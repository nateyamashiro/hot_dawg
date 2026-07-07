--!strict
-- Weekly limited-time events (M4, GDD §4.7). The active event is a DETERMINISTIC
-- function of the week index (same trick ShopService uses for the daily shop), so
-- every server agrees without coordination. An event carries a modifier (2× income /
-- dog rain / discount cook) and a per-player reward track fed by `eventPoints`.
-- Event-only dogs are FOMO. Untrusted client only requests reward claims.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local EventService = {}

local updateLeaderstats: (player: Player) -> ()
local remEventUpdate: RemoteEvent
local remClaimEventReward: RemoteEvent

-- Which event is live right now (index into GameConfig.Events by week).
local function currentWeek(): number
	return math.floor(os.time() / GameConfig.EventRefreshSeconds)
end

local function currentEvent()
	local list = GameConfig.Events
	if #list == 0 then
		return nil
	end
	return list[(currentWeek() % #list) + 1]
end

-- The active-event modifier, for other systems (income/cook) to read.
-- TODO(M4-event): consume this in Main's income loop + cook cost (income2x /
-- cookHalfPrice) and a dog-rain spawner (freeCookBursts).
function EventService.activeModifier(): string?
	local ev = currentEvent()
	return ev and ev.modifier or nil
end

function EventService.pushEvent(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local ev = currentEvent()
	local secondsLeft = GameConfig.EventRefreshSeconds
		- (os.time() % GameConfig.EventRefreshSeconds)
	local points = ev and (data.eventPoints[ev.id] or 0) or 0
	remEventUpdate:FireClient(player, ev, points, secondsLeft)
end

local function onClaim(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	-- TODO(M4-event): find the highest reward tier the player's eventPoints unlock
	-- that isn't claimed yet, grant it, mark claimed, updateLeaderstats, re-push.
	updateLeaderstats(player)
	EventService.pushEvent(player)
end

function EventService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remEventUpdate = deps.remotes:WaitForChild("EventUpdate") :: RemoteEvent
	remClaimEventReward = deps.remotes:WaitForChild("ClaimEventReward") :: RemoteEvent

	remClaimEventReward.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "ClaimEventReward", 5) then
			return
		end
		onClaim(player)
	end)

	-- Re-push to everyone when the event rotates so in-session players update.
	task.spawn(function()
		local lastWeek = currentWeek()
		while true do
			task.wait(60)
			local week = currentWeek()
			if week ~= lastWeek then
				lastWeek = week
				for _, player in Players:GetPlayers() do
					EventService.pushEvent(player)
				end
			end
		end
	end)
end

return EventService
