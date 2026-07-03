--!strict
-- Handles loading and saving each player's persistent data via DataStores.
--
-- NOTE: DataStores only work in Studio if you enable
--   Game Settings -> Security -> "Enable Studio Access to API Services".
-- Without it, load/save calls fail harmlessly (we pcall + warn) and players
-- simply start from default data each session.

local DataStoreService = game:GetService("DataStoreService")

-- Bump the "_v1" suffix if you ever change the data shape in a breaking way.
local store = DataStoreService:GetDataStore("TycoonSim_PlayerData_v1")

local DataManager = {}

export type PlayerData = {
	coins: number,
	upgradeLevel: number,
}

local DEFAULT_DATA: PlayerData = {
	coins = 0,
	upgradeLevel = 0,
}

-- In-memory copy of each active player's data, keyed by UserId. This is the
-- authoritative value while the player is in-game; the DataStore is just where
-- we persist it between sessions.
local cache: { [number]: PlayerData } = {}

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

-- Load a player's data into the cache and return it.
function DataManager.load(player: Player): PlayerData
	local data = table.clone(DEFAULT_DATA)

	local ok, result = pcall(function()
		return store:GetAsync(keyFor(player))
	end)

	if ok and type(result) == "table" then
		data.coins = result.coins or data.coins
		data.upgradeLevel = result.upgradeLevel or data.upgradeLevel
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
