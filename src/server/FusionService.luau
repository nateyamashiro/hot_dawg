--!strict
-- Duplicates → fusion (M3 remainder, GDD §4.4). Combine N duplicates of the same
-- inventory key into a better outcome (a higher-tier dog, or a forced mutation).
-- Server validates the player actually owns N of the key, consumes them, and grants
-- the result — operating on composite keys so Gold/Rainbow/etc. fuse too. Untrusted
-- client only requests. Mirrors UpgradeService's validate→charge→grant→push flow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Variants = require(ReplicatedStorage.Shared.Variants)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local FusionService = {}

local updateLeaderstats: (player: Player) -> ()
local onInventoryChanged: (player: Player) -> ()
local remFuse: RemoteEvent
local remFeedback: RemoteEvent

local function onFuse(player: Player, key: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local have = data.hotDogs[key] or 0
	if have < GameConfig.FusionInputs then
		remFeedback:FireClient(player, false, "Need " .. GameConfig.FusionInputs .. " to fuse.")
		return
	end

	-- Force-mutation ladder (GDD §7 fork): fusing N dupes of a key yields ONE of the
	-- same base dog, one variant up (base → Gold → Rainbow → Giant). Reuses the live
	-- Variants layer so Gold/Rainbow dupes fuse too; Giant is the top and can't fuse
	-- higher. (GameConfig.FusionForcesMutation flags this mode; a rarity-tier-upgrade
	-- alternative is the future fork, needing a HotDogDex "next dog up" helper.)
	local baseName, variant = Variants.decode(key)
	local nextVariant = Variants.nextVariant(variant)
	if not nextVariant then
		remFeedback:FireClient(
			player,
			false,
			"That's already the top mutation — can't fuse higher."
		)
		return
	end
	local resultKey = Variants.encode(baseName, nextVariant)

	-- Consume the inputs (clear the stack when it empties so a 0-count key doesn't
	-- linger), then grant the fused result.
	local remaining = have - GameConfig.FusionInputs
	data.hotDogs[key] = remaining > 0 and remaining or nil
	data.hotDogs[resultKey] = (data.hotDogs[resultKey] or 0) + 1

	updateLeaderstats(player)
	PlotManager.syncDisplay(player)
	onInventoryChanged(player)
	remFeedback:FireClient(
		player,
		true,
		"⚗️ Fused into " .. Variants.displayName(resultKey) .. "!"
	)
end

function FusionService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	onInventoryChanged: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	onInventoryChanged = deps.onInventoryChanged
	remFuse = deps.remotes:WaitForChild("Fuse") :: RemoteEvent
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent

	remFuse.OnServerEvent:Connect(function(player, key)
		if not RateLimit.check(player, "Fuse", 5) then
			return
		end
		if type(key) == "string" then
			onFuse(player, key)
		end
	end)
end

return FusionService
