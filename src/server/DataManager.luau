--!strict
-- Handles loading and saving each player's persistent data via DataStores.
--
-- NOTE: DataStores only work in Studio if you enable
--   Game Settings -> Security -> "Enable Studio Access to API Services".
-- Without it, load/save calls fail harmlessly (we pcall + warn) and players
-- simply start from default data each session.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

-- Bump the "_v2" suffix if you ever change the data shape in a breaking way.
local store = DataStoreService:GetDataStore("StealAGlizzy_PlayerData_v2")

local DataManager = {}

export type PlayerData = {
	coins: number,
	-- Owned hot dogs as name -> count, e.g. { ["Plain Dog"] = 3 }.
	hotDogs: { [string]: number },
}

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

-- A fresh default profile. Built new each call so no two players ever share the
-- same inner `hotDogs` table (a shallow copy would alias it — a classic bug).
local function defaultData(): PlayerData
	return {
		coins = GameConfig.StartingCoins,
		hotDogs = {},
	}
end

-- In-memory copy of each active player's data, keyed by UserId. This is the
-- authoritative value while the player is in-game; the DataStore is just where
-- we persist it between sessions.
local cache: { [number]: PlayerData } = {}

-- Load a player's data into the cache and return it.
function DataManager.load(player: Player): PlayerData
	local data = defaultData()

	local ok, result = pcall(function()
		return store:GetAsync(keyFor(player))
	end)

	if ok and type(result) == "table" then
		if type(result.coins) == "number" then
			data.coins = result.coins
		end
		if type(result.hotDogs) == "table" then
			for name, count in result.hotDogs do
				if type(name) == "string" and type(count) == "number" then
					data.hotDogs[name] = count
				end
			end
		end
	elseif not ok then
		warn("[DataManager] Load failed for " .. player.Name .. ": " .. tostring(result))
	end

	cache[player.UserId] = data
	return data
end

-- Get the live cached data for a player (or nil if not loaded yet).
function DataManager.get(player: Player): PlayerData?
	return cache[player.UserId]
end

-- Persist a player's current cached data to the DataStore.
function DataManager.save(player: Player)
	local data = cache[player.UserId]
	if not data then
		return
	end

	local ok, err = pcall(function()
		store:SetAsync(keyFor(player), data)
	end)

	if not ok then
		warn("[DataManager] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

-- Save then drop a player from the cache (call on PlayerRemoving).
function DataManager.release(player: Player)
	DataManager.save(player)
	cache[player.UserId] = nil
end

return DataManager
