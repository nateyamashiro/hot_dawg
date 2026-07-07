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

-- A single numeric "rarest" score derived from a player's inventory (higher = rarer
-- collection). TODO(M4-lb): compute from best-dog income / variant via HotDogDex.
local function rarestScore(data: DataManager.PlayerData): number
	local _ = data
	return 0
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
			-- TODO(M4-lb): map UserIds → display names (GetNameFromUserIdAsync, cached).
			for _, entry in page:GetCurrentPage() do
				table.insert(out, { name = tostring(entry.key), value = entry.value })
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
