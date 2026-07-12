--!strict
-- Daily login streak + daily missions (item 10, GDD §4.7). On each new UTC day a
-- player gets a fresh set of missions (cook X / steal Y / earn Z) and can claim an
-- escalating streak reward once per day. Progress is driven server-side from the
-- cook, steal, and income paths via DailyService.progress(). Server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local DailyService = {}

local updateLeaderstats: (player: Player) -> ()
local remFeedback: RemoteEvent
local remDailyUpdate: RemoteEvent
local remClaimDaily: RemoteEvent
local remClaimMission: RemoteEvent

-- Fast lookup of a mission definition (label/reward) by id.
local defById: { [string]: any } = {}
for _, def in GameConfig.DailyMissionDefs do
	defById[def.id] = def
end

-- Current UTC day index. Simple + timezone-stable; no extra storage needed.
local function today(): number
	return math.floor(os.time() / 86400)
end

-- The coin reward for claiming at a given (already-incremented) streak length.
local function streakReward(streak: number): number
	local rewards = GameConfig.DailyStreakRewards
	local idx = math.clamp(streak, 1, #rewards)
	return rewards[idx]
end

-- Pick a fresh set of daily missions (distinct, drawn from the pool).
local function rollMissions(): { DataManager.DailyMission }
	local pool = table.clone(GameConfig.DailyMissionDefs)
	local chosen: { DataManager.DailyMission } = {}
	local count = math.min(GameConfig.DailyMissionCount, #pool)
	for _ = 1, count do
		local def = table.remove(pool, math.random(1, #pool))
		table.insert(chosen, {
			id = def.id,
			kind = def.kind,
			target = def.target,
			progress = 0,
			claimed = false,
		})
	end
	return chosen
end

-- Send the player their current daily state (streak + claimability + missions).
local function pushDaily(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local missions = {}
	for _, m in data.dailyMissions do
		local def = defById[m.id]
		table.insert(missions, {
			id = m.id,
			label = def and def.label or m.id,
			target = m.target,
			progress = m.progress,
			claimed = m.claimed,
			reward = def and def.reward or 0,
		})
	end
	local canClaimStreak = data.lastDailyDay < today()
	remDailyUpdate:FireClient(player, {
		streak = data.streak,
		canClaimStreak = canClaimStreak,
		-- Reward the NEXT claim would grant (streak+1, or reset to 1 if a day was missed).
		nextReward = streakReward(
			if canClaimStreak and today() == data.lastDailyDay + 1 then data.streak + 1 else 1
		),
		missions = missions,
	})
end

-- Refresh missions if it's a new day, then push. Call on join.
function DailyService.onJoin(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local t = today()
	if data.missionsDay ~= t or #data.dailyMissions == 0 then
		data.dailyMissions = rollMissions()
		data.missionsDay = t
	end
	pushDaily(player)
end

-- Advance any active mission of `kind` by `amount`; push if something changed.
function DailyService.progress(player: Player, kind: string, amount: number)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local changed = false
	for _, m in data.dailyMissions do
		if m.kind == kind and not m.claimed and m.progress < m.target then
			m.progress = math.min(m.target, m.progress + amount)
			changed = true
		end
	end
	if changed then
		pushDaily(player)
	end
end

local function onClaimDaily(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local t = today()
	if data.lastDailyDay >= t then
		remFeedback:FireClient(player, false, "Come back tomorrow for your streak reward!")
		return
	end
	-- Consecutive day keeps the streak; a missed day resets it to 1.
	if t == data.lastDailyDay + 1 then
		data.streak += 1
	else
		data.streak = 1
	end
	data.lastDailyDay = t
	local reward = streakReward(data.streak)
	data.coins += reward
	updateLeaderstats(player)
	remFeedback:FireClient(
		player,
		true,
		"📅 Day " .. data.streak .. " streak! +" .. Format.comma(reward) .. " coins."
	)
	pushDaily(player)
end

local function onClaimMission(player: Player, id: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	for _, m in data.dailyMissions do
		if m.id == id then
			if m.claimed then
				return
			end
			if m.progress < m.target then
				remFeedback:FireClient(player, false, "That mission isn't done yet.")
				return
			end
			m.claimed = true
			local def = defById[id]
			local reward = def and def.reward or 0
			data.coins += reward
			updateLeaderstats(player)
			remFeedback:FireClient(
				player,
				true,
				"✅ Mission complete! +" .. Format.comma(reward) .. " coins."
			)
			pushDaily(player)
			return
		end
	end
end

function DailyService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remDailyUpdate = deps.remotes:WaitForChild("DailyUpdate") :: RemoteEvent
	remClaimDaily = deps.remotes:WaitForChild("ClaimDaily") :: RemoteEvent
	remClaimMission = deps.remotes:WaitForChild("ClaimMission") :: RemoteEvent

	remClaimDaily.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "ClaimDaily", 3) then
			return
		end
		onClaimDaily(player)
	end)
	remClaimMission.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "ClaimMission", 5) then
			return
		end
		if type(id) == "string" and #id <= 64 then
			onClaimMission(player, id)
		end
	end)
end

return DailyService
