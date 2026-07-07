--!strict
-- Duplicates → fusion (M3 remainder, GDD §4.4). Combine N duplicates of the same
-- inventory key into a better outcome (a higher-tier dog, or a forced mutation).
-- Server validates the player actually owns N of the key, consumes them, and grants
-- the result — operating on composite keys so Gold/Rainbow/etc. fuse too. Untrusted
-- client only requests. Mirrors UpgradeService's validate→charge→grant→push flow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
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
	-- TODO(M3-fusion): consume GameConfig.FusionInputs of `key`, then grant the
	-- result per a FusionRules mapping (upgrade one rarity tier, or force a mutation
	-- via Variants when GameConfig.FusionForcesMutation). Then sync + push below.
	updateLeaderstats(player)
	PlotManager.syncDisplay(player)
	onInventoryChanged(player)
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
