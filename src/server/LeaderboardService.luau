--!strict
-- Leaderboards (M4, GDD §4.7). Global top-N for richest (coins), most steals, and
-- rarest collection — backed by OrderedDataStore (see docs/roblox-reference for
-- GetSortedAsync). Each player's stats are submitted on an interval; the top-N is
-- fetched, cached, and pushed to clients. Untrusted client only asks which board to
-- show. Mirrors DataManager's DataStore usage for the store wiring.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local LeaderboardService = {}

local remLeaderboardUpdate: RemoteEvent
local remRequestLeaderboard: RemoteEvent

-- One OrderedDataStore per board.
local boards = {
	coins = DataStoreService:GetOrderedDataStore("StealAGlizzy_LB_Coins_v1"),
	steals = DataStoreService:GetOrderedDataStore("StealAGlizzy_LB_Steals_v1"),
	rarest = DataStoreService:GetOrderedDataStore("StealAGlizzy_LB_Rarest_v1"),
}

-- Cached top-N per board (list of { name, value }), refreshed on an interval.
local cachedTops: { [string]: { { name: string, value: number } } } = {
	coins = {},
	steals = {},
	rarest = {},
}

-- A single numeric "rarest" score derived from a player's inventory: the income/sec
-- of their single best unit (variant-scaled, so a Gold dog outranks its plain twin),
-- ×100 because OrderedDataStore only takes integers. sortedUnits sorts descending.
local function rarestScore(data: DataManager.PlayerData): number
	local units = HotDogDex.sortedUnits(data.hotDogs)
	local best = units[1]
	return if best then math.floor(best.income * 100) else 0
end

-- UserId -> display name, cached for the server's lifetime (the web lookup is slow
-- and rate-limited; a stale name for a session is fine for a leaderboard).
local nameCache: { [number]: string } = {}
local function nameForUserId(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local resolved = if ok and type(name) == "string" then name else "Player " .. userId
	nameCache[userId] = resolved
	return resolved
end

-- Write everyone's current stats into the ordered stores (pcall-guarded like saves).
local function submitScores()
	for _, player in Players:GetPlayers() do
		local data = DataManager.get(player)
		if data then
			local key = "player_" .. player.UserId
			pcall(function()
				boards.coins:SetAsync(key, data.coins)
				boards.steals:SetAsync(key, data.totalSteals)
				boards.rarest:SetAsync(key, rarestScore(data))
			end)
		end
	end
end

-- Refresh cachedTops for each board from its ordered store.
local function refreshTops()
	for boardName, store in boards do
		local ok, page = pcall(function()
			return store:GetSortedAsync(false, GameConfig.LeaderboardTopN)
		end)
		if ok and page then
			local out: { { name: string, value: number } } = {}
			for _, entry in page:GetCurrentPage() do
				-- Keys are "player_<UserId>" (see submitScores).
				local userId = tonumber(string.match(tostring(entry.key), "^player_(%d+)$"))
				local name = if userId then nameForUserId(userId) else tostring(entry.key)
				table.insert(out, { name = name, value = entry.value })
			end
			cachedTops[boardName] = out
		end
	end
end

function LeaderboardService.pushLeaderboard(player: Player)
	remLeaderboardUpdate:FireClient(player, cachedTops)
end

function LeaderboardService.init(deps: { remotes: Folder })
	remLeaderboardUpdate = deps.remotes:WaitForChild("LeaderboardUpdate") :: RemoteEvent
	remRequestLeaderboard = deps.remotes:WaitForChild("RequestLeaderboard") :: RemoteEvent

	remRequestLeaderboard.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "RequestLeaderboard", 5) then
			return
		end
		LeaderboardService.pushLeaderboard(player)
	end)

	task.spawn(function()
		while true do
			submitScores()
			refreshTops()
			for _, player in Players:GetPlayers() do
				LeaderboardService.pushLeaderboard(player)
			end
			task.wait(GameConfig.LeaderboardRefreshSeconds)
		end
	end)
end

return LeaderboardService
