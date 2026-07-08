--!strict
-- Zone / world expansion (Phase 5, visual-overhaul/tycoon plan; prestige-gated). A
-- late-game runway sink: spend PRESTIGE (never Robux) to expand your plot tier — a
-- bigger pad + extra capacity. GameConfig.ZoneTiers holds the prestige cost + pad-size
-- multiplier + extra slots per level (data.zoneLvl). Server validates prestige balance
-- + charges + re-sizes the plot; untrusted client only requests. Mirrors
-- PrestigeShopService (spends the same prestige currency).
--
-- SCAFFOLD: the buy path + PlotManager re-sizing are TODO(Phase5). Today this ships the
-- pushState handshake only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local ZoneService = {}

local updateLeaderstats: (player: Player) -> ()
local remFeedback: RemoteEvent
local remBuyZone: RemoteEvent
local remZoneUpdate: RemoteEvent

-- Send the tier table + level + prestige balance for the expansion panel. In pushAllState.
function ZoneService.pushState(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remZoneUpdate:FireClient(player, GameConfig.ZoneTiers, data.zoneLvl, data.prestige)
end

local function onBuy(player: Player)
	-- TODO(Phase5): validate a next tier exists + prestige >= cost; charge prestige,
	-- bump data.zoneLvl, resize the plot + apply extraSlots via PlotManager, push.
	local _ = remFeedback
	updateLeaderstats(player)
	ZoneService.pushState(player)
end

function ZoneService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuyZone = deps.remotes:WaitForChild("BuyZone") :: RemoteEvent
	remZoneUpdate = deps.remotes:WaitForChild("ZoneUpdate") :: RemoteEvent

	remBuyZone.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "BuyZone", 5) then
			return
		end
		onBuy(player)
	end)
end

return ZoneService
