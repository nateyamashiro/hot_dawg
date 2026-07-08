--!strict
-- Auto-cooker (Phase 1, visual-overhaul/tycoon plan). The passive "dropper" income
-- FLOOR: a machine on every stand that emits COINS over time. Deliberately SEPARATE
-- from the gacha Cook — it produces NO stealable glizzies, only un-stealable coins,
-- so it lives entirely outside data.hotDogs. Upgradeable via GameConfig.AutoCookerTiers
-- (data.autoCookerLvl). Server owns the tier/charge; untrusted client only requests an
-- upgrade. Mirrors PrestigeShopService's validate→charge→apply→push flow.
--
-- The stove starts UNBUILT (data.autoCookerLvl 0); the player builds it via a walk-on
-- pad (PlotManager) — tryUpgrade both builds (0→1) and upgrades (N→N+1). Its coins are
-- folded into Main's income loop via coinsPerSecond, and it's rendered as a physical
-- model by PlotManager.setStove. A menu button can also drive it via the BuyAutoCooker
-- remote (same tryUpgrade path).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BuildGrants = require(ReplicatedStorage.Shared.BuildGrants)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)
local UpgraderService = require(ServerScriptService.Server.UpgraderService)

local AutoCookerService = {}

local updateLeaderstats: (player: Player) -> ()
local remFeedback: RemoteEvent
local remBuyAutoCooker: RemoteEvent
local remAutoCookerUpdate: RemoteEvent

-- Coins/sec the player's current stove tier emits (0 when unbuilt/misconfigured).
-- Folded into Main's income loop. Un-stealable by construction — it's coins, not dogs.
-- Two read-time multipliers stack on the base tier rate:
--   * built floors: each cooker slot = +15% (BuildGrants; derived from data.built)
--   * the cooker upgrader: ×UpgraderTiers[upgraderLvl].outputMult (Phase 4)
function AutoCookerService.coinsPerSecond(data: DataManager.PlayerData): number
	local tier = GameConfig.AutoCookerTiers[data.autoCookerLvl]
	if not tier then
		return 0
	end
	return tier.coinsPerSec
		* (1 + 0.15 * BuildGrants.cookerSlotBonus(data.built))
		* UpgraderService.outputMultiplier(data)
end

-- Send the tier table + the player's level + coin balance so a client panel can render
-- the upgrade state. Handshake: also called from Main.pushAllState.
function AutoCookerService.pushState(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remAutoCookerUpdate:FireClient(
		player,
		GameConfig.AutoCookerTiers,
		data.autoCookerLvl,
		data.coins
	)
end

-- Build (0→1) or upgrade (N→N+1) the stove: validate the next tier exists + affordable,
-- charge, bump the level, push. Returns true on success. Called by the walk-on pad
-- (via Main's pad handler) and the BuyAutoCooker remote. Caller re-syncs the plot.
function AutoCookerService.tryUpgrade(player: Player): boolean
	local data = DataManager.get(player)
	if not data then
		return false
	end
	local nextLvl = data.autoCookerLvl + 1
	local nextTier = GameConfig.AutoCookerTiers[nextLvl]
	if not nextTier then
		remFeedback:FireClient(player, false, "🔥 Stove is fully upgraded!")
		return false
	end
	if data.coins < nextTier.cost then
		remFeedback:FireClient(player, false, "Need " .. nextTier.cost .. " coins for the stove.")
		return false
	end
	data.coins -= nextTier.cost
	data.autoCookerLvl = nextLvl
	updateLeaderstats(player)
	AutoCookerService.pushState(player)
	local msg = if nextLvl == 1
		then "🔥 Stove built — passive coins flowing!"
		else "🔥 Stove upgraded to Lv " .. nextLvl .. "!"
	remFeedback:FireClient(player, true, msg)
	return true
end

function AutoCookerService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuyAutoCooker = deps.remotes:WaitForChild("BuyAutoCooker") :: RemoteEvent
	remAutoCookerUpdate = deps.remotes:WaitForChild("AutoCookerUpdate") :: RemoteEvent

	remBuyAutoCooker.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "BuyAutoCooker", 5) then
			return
		end
		AutoCookerService.tryUpgrade(player)
	end)
end

return AutoCookerService
