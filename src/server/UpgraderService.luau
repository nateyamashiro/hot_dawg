--!strict
-- Cooker upgraders (Phase 4, visual-overhaul/tycoon plan). The classic dropper→upgrader
-- value chain: an upgrader multiplies the auto-cooker's coin output as it travels the
-- belt. GameConfig.UpgraderTiers holds the multiplier per level (data.upgraderLvl).
-- Server validates + charges the upgrade; the multiplier is read by AutoCookerService /
-- Main's income loop. Untrusted client only requests. Mirrors UpgradeService.
--
-- SCAFFOLD: the buy path is TODO(Phase4). Today this ships the pushState handshake +
-- the outputMultiplier getter (so Phase 4 income wiring is a one-liner).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local UpgraderService = {}

local updateLeaderstats: (player: Player) -> ()
local remBuyUpgrader: RemoteEvent
local remUpgraderUpdate: RemoteEvent

-- Multiplier the player's current upgrader tier applies to auto-cooker output (1 if
-- misconfigured). Phase 4 multiplies AutoCookerService.coinsPerSecond by this.
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

local function onBuy(player: Player)
	-- TODO(Phase4): validate a next tier exists + coins >= cost; charge, bump
	-- data.upgraderLvl, push.
	updateLeaderstats(player)
	UpgraderService.pushState(player)
end

function UpgraderService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remBuyUpgrader = deps.remotes:WaitForChild("BuyUpgrader") :: RemoteEvent
	remUpgraderUpdate = deps.remotes:WaitForChild("UpgraderUpdate") :: RemoteEvent

	remBuyUpgrader.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "BuyUpgrader", 5) then
			return
		end
		onBuy(player)
	end)
end

return UpgraderService
