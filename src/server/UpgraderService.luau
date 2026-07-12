--!strict
-- Cooker upgraders (Phase 4 — SHIPPED). The classic dropper→upgrader value chain: an
-- upgrader multiplies the auto-cooker stove's coin output. GameConfig.UpgraderTiers
-- holds the multiplier per level (data.upgraderLvl; level 1 = the free ×1.0 default).
-- Server validates + charges; AutoCookerService.coinsPerSecond reads outputMultiplier,
-- so the tick loop, offline earnings, and the stove label all inherit it for free.
-- Bought via the ⚙️ walk-on pad (Main's pad handler) or the BuyUpgrader remote — both
-- share tryUpgrade. Mirrors AutoCookerService's validate→charge→apply→push flow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local UpgraderService = {}

local updateLeaderstats: (player: Player) -> ()
local remFeedback: RemoteEvent
local remBuyUpgrader: RemoteEvent
local remUpgraderUpdate: RemoteEvent

-- Multiplier the player's current upgrader tier applies to auto-cooker output (1 if
-- misconfigured). AutoCookerService.coinsPerSecond multiplies by this.
function UpgraderService.outputMultiplier(data: DataManager.PlayerData): number
	local tier = GameConfig.UpgraderTiers[data.upgraderLvl]
	return tier and tier.outputMult or 1
end

-- Send the tier table + level + coin balance for the upgrade panel. Also in pushAllState.
function UpgraderService.pushState(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remUpgraderUpdate:FireClient(player, GameConfig.UpgraderTiers, data.upgraderLvl, data.coins)
end

-- Upgrade to the next tier: validate it exists + affordable, charge, bump, push.
-- Returns true on success (the pad handler pops a celebration on it).
function UpgraderService.tryUpgrade(player: Player): boolean
	local data = DataManager.get(player)
	if not data then
		return false
	end
	local nextLvl = data.upgraderLvl + 1
	local nextTier = GameConfig.UpgraderTiers[nextLvl]
	if not nextTier then
		remFeedback:FireClient(player, false, "⚙️ Upgrader is fully upgraded!")
		return false
	end
	if data.coins < nextTier.cost then
		remFeedback:FireClient(
			player,
			false,
			"Need " .. Format.comma(nextTier.cost) .. " coins for the upgrader."
		)
		return false
	end
	data.coins -= nextTier.cost
	data.upgraderLvl = nextLvl
	updateLeaderstats(player)
	UpgraderService.pushState(player)
	remFeedback:FireClient(
		player,
		true,
		"⚙️ Upgrader Lv " .. nextLvl .. " — stove output ×" .. nextTier.outputMult .. "!"
	)
	return true
end

function UpgraderService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuyUpgrader = deps.remotes:WaitForChild("BuyUpgrader") :: RemoteEvent
	remUpgraderUpdate = deps.remotes:WaitForChild("UpgraderUpdate") :: RemoteEvent

	remBuyUpgrader.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "BuyUpgrader", 5) then
			return
		end
		UpgraderService.tryUpgrade(player)
	end)
end

return UpgraderService
