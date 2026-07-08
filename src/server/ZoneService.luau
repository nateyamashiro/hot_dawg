--!strict
-- Zone / world expansion (Phase 5 — SHIPPED; prestige-gated). The late-game runway
-- sink: spend PRESTIGE (never Robux) to expand your plot tier. Each ZoneTiers level
-- buys a physically bigger pad (padSizeMult — the footprint visibly swells, a flex
-- neighbors can see) plus extra display slots (extraSlots — folded into
-- PlotManager.displayCapacity at READ time like every other capacity grant, so
-- rejoin can never double-apply). Bought via the 🌍 walk-on pad or the BuyZone
-- remote — both share tryUpgrade. Mirrors PrestigeShopService (same currency).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local ZoneService = {}

local updateLeaderstats: (player: Player) -> ()
local pushProgression: (player: Player) -> ()
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

-- Re-apply the player's zone size on join (right after structures rebuild). The
-- capacity half of the grant needs no re-apply — displayCapacity derives it.
function ZoneService.applyLoaded(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local tier = GameConfig.ZoneTiers[data.zoneLvl]
	if tier and tier.padSizeMult > 1 then
		PlotManager.applyZone(player, tier.padSizeMult)
	end
end

-- Expand to the next zone tier: validate it exists + prestige covers it, charge,
-- bump, resize the pad, refresh capacity. Returns true on success.
function ZoneService.tryUpgrade(player: Player): boolean
	local data = DataManager.get(player)
	if not data then
		return false
	end
	local nextLvl = data.zoneLvl + 1
	local nextTier = GameConfig.ZoneTiers[nextLvl]
	if not nextTier then
		remFeedback:FireClient(player, false, "🌍 Your zone is fully expanded!")
		return false
	end
	if data.prestige < nextTier.prestigeCost then
		remFeedback:FireClient(
			player,
			false,
			"Need ✨" .. nextTier.prestigeCost .. " prestige to expand (rebirth to earn it)."
		)
		return false
	end
	data.prestige -= nextTier.prestigeCost
	data.zoneLvl = nextLvl
	PlotManager.applyZone(player, nextTier.padSizeMult)
	PlotManager.syncDisplay(player) -- extra slots may reveal stored dogs on floor anchors
	updateLeaderstats(player)
	pushProgression(player) -- prestige balance shows in the Rebirth panel
	ZoneService.pushState(player)
	remFeedback:FireClient(
		player,
		true,
		"🌍 Zone expanded to tier "
			.. nextLvl
			.. " — bigger pad, +"
			.. nextTier.extraSlots
			.. " slots!"
	)
	return true
end

function ZoneService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	pushProgression: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	pushProgression = deps.pushProgression
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuyZone = deps.remotes:WaitForChild("BuyZone") :: RemoteEvent
	remZoneUpdate = deps.remotes:WaitForChild("ZoneUpdate") :: RemoteEvent

	remBuyZone.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "BuyZone", 5) then
			return
		end
		ZoneService.tryUpgrade(player)
	end)
end

return ZoneService
