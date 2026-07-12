--!strict
-- Base building (Phase 3 / P-B) — the classic-tycoon "walk onto a button → your base
-- physically grows" loop, now real. GameConfig.BuildCatalog lists the structures;
-- BuildGrants owns the pure math (category, next-offer, grant sums); PlotManager owns
-- the physical BUILDERS. This service is the validate → charge → grant → spawn → push
-- pipeline (mirrors FusionService's flow), plus:
--   * the two walk-on pads' offers ("build" = next structural, "decor" = next decor —
--     the server RE-derives the offer on step; it never trusts the pad),
--   * rebuild-on-join (applyLoaded — grants derive from data.built at read time, so
--     rebuilding can never double-apply),
--   * the slow-down gate rule (registered via PlotManager.setGateHandler): gates slow
--     non-owners, they NEVER block (locked balance rule).
-- The perimeter wall's steal-hold bonus (WallHoldBonusSeconds) is granted here now —
-- the old $250 DefenseService wall is retired (owners grandfathered in DataManager).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BuildGrants = require(ReplicatedStorage.Shared.BuildGrants)
local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)
local StealService = require(ServerScriptService.Server.StealService)
local Telemetry = require(ServerScriptService.Server.Telemetry)

local BuildService = {}

local updateLeaderstats: (player: Player) -> ()
local remFeedback: RemoteEvent
local remBuild: RemoteEvent
local remBuildUpdate: RemoteEvent
local remCelebrate: RemoteEvent

-- Send the catalog + the player's constructed set + coin balance so the client can
-- render the build menu (owned / affordable / prereq-locked). Also in Main.pushAllState.
function BuildService.pushState(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remBuildUpdate:FireClient(player, GameConfig.BuildCatalog, data.built, data.coins)
end

-- What a walk-on pad should offer right now (nil = category exhausted, pad hides).
function BuildService.nextEntry(data: DataManager.PlayerData, category: string): BuildGrants.Entry?
	return BuildGrants.nextEntry(data.built, category)
end

-- Validate id ∈ catalog, not built, prereq built, coins ≥ cost → charge, mark built,
-- spawn the structure, apply side grants, push. Shared by the walk-on pads and the
-- Build remote (menu panel).
function BuildService.tryBuild(player: Player, id: string): boolean
	local data = DataManager.get(player)
	if not data then
		return false
	end
	local entry = BuildGrants.entry(id)
	if not entry then
		return false
	end
	if data.built[id] then
		remFeedback:FireClient(player, false, entry.label .. " is already built.")
		return false
	end
	if entry.prereq ~= nil and not data.built[entry.prereq] then
		local prereqEntry = BuildGrants.entry(entry.prereq)
		local need = if prereqEntry then prereqEntry.label else entry.prereq
		remFeedback:FireClient(player, false, "Requires " .. need .. " first.")
		return false
	end
	if data.coins < entry.cost then
		remFeedback:FireClient(
			player,
			false,
			"Need " .. Format.comma(entry.cost) .. " coins for " .. entry.label .. "."
		)
		return false
	end

	data.coins -= entry.cost
	data.built[id] = true
	Telemetry.funnelStep(player, "FirstBuild")
	PlotManager.spawnStructure(player, entry)
	if id == "wall" then
		-- The wall's defensive value: thieves hold the Steal prompt longer.
		PlotManager.setStealHoldBonus(player, GameConfig.WallHoldBonusSeconds)
	end
	if entry.grants.kind == "floor" then
		-- The new floor's anchors may fill immediately from stored overflow dogs.
		PlotManager.syncDisplay(player)
	end
	updateLeaderstats(player)
	BuildService.pushState(player)
	remFeedback:FireClient(player, true, "🏗️ " .. entry.label .. " built!")
	-- Build-complete dust puff (P-C) over the plot, for everyone watching.
	local center = PlotManager.plotCenterOf(player)
	if center then
		remCelebrate:FireAllClients("build", center + Vector3.new(0, 5, 0))
	end
	return true
end

-- Walk-on pad entry point: the server re-derives what the pad currently offers
-- (never trusts the pad's label) and buys that. Returns true on a purchase.
function BuildService.tryBuildNext(player: Player, category: string): boolean
	local data = DataManager.get(player)
	if not data then
		return false
	end
	local entry = BuildGrants.nextEntry(data.built, category)
	if not entry then
		return false
	end
	return BuildService.tryBuild(player, entry.id)
end

-- Re-spawn everything a player already built (join path; mirrors
-- DefenseService.applyLoadedDefenses — call right after it in Main.onPlayerAdded).
function BuildService.applyLoaded(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	PlotManager.rebuildStructures(player)
	if data.built.wall then
		PlotManager.setStealHoldBonus(player, GameConfig.WallHoldBonusSeconds)
	end
	-- Rebuilt floor anchors may host overflow dogs that had no pedestal before.
	PlotManager.syncDisplay(player)
end

-- === Slow-down gate rule ===
-- A non-owner brushed the gate curtain (PlotManager debounces 1.5s/player): slow them
-- for 2s. Gates slow, they never block — rule 1. Restore only if still gate-slowed so
-- we don't stomp a net/trap stun or a carry-speed change that landed meanwhile.
local GATE_SLOW_SPEED = 9
local GATE_SLOW_SECONDS = 2
local function onGateTouched(toucher: Player)
	local char = toucher.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if humanoid.WalkSpeed <= GATE_SLOW_SPEED then
		return -- already slowed/stunned; don't extend or fight it
	end
	humanoid.WalkSpeed = GATE_SLOW_SPEED
	task.delay(GATE_SLOW_SECONDS, function()
		if humanoid.Parent and humanoid.WalkSpeed == GATE_SLOW_SPEED then
			humanoid.WalkSpeed = if StealService.isCarrying(toucher)
				then GameConfig.CarryWalkSpeed
				else GameConfig.NormalWalkSpeed
		end
	end)
end

function BuildService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuild = deps.remotes:WaitForChild("Build") :: RemoteEvent
	remBuildUpdate = deps.remotes:WaitForChild("BuildUpdate") :: RemoteEvent
	remCelebrate = deps.remotes:WaitForChild("Celebrate") :: RemoteEvent

	PlotManager.setGateHandler(onGateTouched)

	remBuild.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "Build", 5) then
			return
		end
		if type(id) == "string" then
			BuildService.tryBuild(player, id)
			-- Pad labels catch up via Main's 1s syncPads tick; no extra push needed.
		end
	end)
end

return BuildService
