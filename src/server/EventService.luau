--!strict
-- Weekly limited-time events (M4, GDD §4.7). The active event is a DETERMINISTIC
-- function of the week index (same trick ShopService uses for the daily shop), so
-- every server agrees without coordination. An event carries a modifier — consumed
-- where the real math lives: income2x in Main.incomeMultiplier, cookHalfPrice in
-- Main's cook-10 cost, freeCookBursts by the dog-rain loop below (Main hands us a
-- grantFreeCook closure) — and a per-player reward track fed by `eventPoints`
-- (cooks + steals report in via addPoints). Untrusted client only requests claims.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local EventService = {}

local updateLeaderstats: (player: Player) -> ()
local grantFreeCook: (player: Player) -> ()
local onInventoryChanged: (player: Player) -> ()
local remEventUpdate: RemoteEvent
local remClaimEventReward: RemoteEvent
local remFeedback: RemoteEvent

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

-- Points + claimed-tier count persist in the eventPoints map under derived keys,
-- so no new PlayerData field / _vN bump is needed (the _v5 back-fill already keeps
-- any string->number pair in this map). Keys are scoped to the OCCURRENCE
-- ("doubleIncome@2951"), not just the event id: when the same event returns three
-- weeks later, the track — and its exclusive reward dog — is fresh again. Old
-- occurrences' keys linger as tiny residue (a few dozen bytes a year; harmless).
local function pointsKey(eventId: string): string
	return eventId .. "@" .. currentWeek()
end

local function claimedKey(eventId: string): string
	return eventId .. "@" .. currentWeek() .. ":claimed"
end

-- The active-event modifier, for other systems (income/cook) to read.
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
	local points = ev and (data.eventPoints[pointsKey(ev.id)] or 0) or 0
	local claimed = ev and (data.eventPoints[claimedKey(ev.id)] or 0) or 0
	remEventUpdate:FireClient(player, ev, points, secondsLeft, claimed)
end

-- Bank reward-track points for the live event (cooks + steals call this via Main).
-- No-op when no event is running. Pushes so the panel's points count stays live.
function EventService.addPoints(player: Player, amount: number)
	local data = DataManager.get(player)
	local ev = currentEvent()
	if not (data and ev) or amount <= 0 then
		return
	end
	local key = pointsKey(ev.id)
	data.eventPoints[key] = (data.eventPoints[key] or 0) + amount
	EventService.pushEvent(player)
end

-- Claim every reward tier the player's points have unlocked but not yet collected.
local function onClaim(player: Player)
	local data = DataManager.get(player)
	local ev = currentEvent()
	if not (data and ev) then
		return
	end
	local points = data.eventPoints[pointsKey(ev.id)] or 0
	local claimed = data.eventPoints[claimedKey(ev.id)] or 0
	local payout = 0
	local tiersWon = 0
	while true do
		local nextTier = claimed + tiersWon + 1
		local need = GameConfig.EventRewardTiers[nextTier]
		if not need or points < need then
			break
		end
		payout += GameConfig.EventRewardCoins[nextTier] or 0
		tiersWon += 1
	end
	if tiersWon == 0 then
		local need = GameConfig.EventRewardTiers[claimed + 1]
		if need then
			remFeedback:FireClient(
				player,
				false,
				"Need " .. need .. " event points for the next reward (" .. points .. " now)."
			)
		else
			remFeedback:FireClient(player, false, "🎉 Every event reward already claimed!")
		end
		return
	end
	data.eventPoints[claimedKey(ev.id)] = claimed + tiersWon
	data.coins += payout
	local plural = if tiersWon > 1 then "s" else ""
	remFeedback:FireClient(
		player,
		true,
		"🎉 Claimed " .. tiersWon .. " event reward" .. plural .. " — +" .. payout .. " coins!"
	)
	-- The FINAL tier also grants the event-exclusive dog (the FOMO hook): never in
	-- cook rolls / shop / conveyor, only here, and only while this event runs.
	local rewardDog = ev.rewardDog
	if rewardDog and claimed + tiersWon >= #GameConfig.EventRewardTiers then
		data.hotDogs[rewardDog] = (data.hotDogs[rewardDog] or 0) + 1
		PlotManager.syncDisplay(player)
		onInventoryChanged(player)
		remFeedback:FireClient(
			player,
			true,
			"🌭✨ EXCLUSIVE unlocked: " .. rewardDog .. " — only from this event!"
		)
	end
	updateLeaderstats(player)
	EventService.pushEvent(player)
end

function EventService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	grantFreeCook: (player: Player) -> (),
	onInventoryChanged: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	grantFreeCook = deps.grantFreeCook
	onInventoryChanged = deps.onInventoryChanged
	remEventUpdate = deps.remotes:WaitForChild("EventUpdate") :: RemoteEvent
	remClaimEventReward = deps.remotes:WaitForChild("ClaimEventReward") :: RemoteEvent
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent

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

	-- Dog Rain: while the freeCookBursts event is live, everyone online gets a free
	-- glizzy roll on an interval (Main's closure does the roll + reveal + celebrate).
	task.spawn(function()
		while true do
			task.wait(GameConfig.EventDogRainIntervalSeconds)
			if EventService.activeModifier() == "freeCookBursts" then
				for _, player in Players:GetPlayers() do
					task.spawn(grantFreeCook, player)
				end
			end
		end
	end)
end

return EventService
