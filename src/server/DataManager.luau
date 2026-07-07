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

-- Bump the "_vN" suffix if you ever change the data shape in a breaking way.
-- v4 adds M3 progression fields (grill/slot levels, rebirth/prestige, offline
-- lastSeen, pity, dex reward, daily streak/missions); load() back-fills them all
-- from defaults so v3 saves upgrade cleanly.
local store = DataStoreService:GetDataStore("StealAGlizzy_PlayerData_v4")

local DataManager = {}

export type Defenses = {
	wall: boolean,
	guard: boolean,
}

-- One active daily mission (item 10). `kind` is what to track ("cook"/"steal"/"earn").
export type DailyMission = {
	id: string,
	kind: string,
	target: number,
	progress: number,
	claimed: boolean,
}

export type PlayerData = {
	coins: number,
	-- Owned hot dogs as name -> count, e.g. { ["Plain Dog"] = 3 }. This is the
	-- master inventory; vault vs. display is DERIVED (see PlotManager), not stored.
	hotDogs: { [string]: number },
	-- Steal energy: current charges + os.time of the last recharge tick.
	stealCharges: number,
	lastChargeAt: number,
	-- os.time until which this player's plot is un-raidable (newbie shield).
	shieldUntil: number,
	-- Lifetime successful steals (leaderstats / future leaderboard).
	totalSteals: number,
	-- Which defenses this player has bought.
	defenses: Defenses,
	-- === M3 progression ===
	-- Upgrade levels (1-based indices into GameConfig.*Levels).
	grillLvl: number,
	displaySlotsLvl: number,
	vaultSlotsLvl: number,
	-- Rebirth count (drives the income multiplier) + banked prestige currency.
	rebirths: number,
	prestige: number,
	-- os.time of the last save; used to grant capped offline earnings on rejoin.
	lastSeen: number,
	-- Cooks since the last Rare-or-better (pity guarantee).
	cooksSinceRare: number,
	-- One-time dex-completion reward already granted?
	dexRewarded: boolean,
	-- Daily streak: UTC day index of the last streak claim + current streak length.
	lastDailyDay: number,
	streak: number,
	-- UTC day index the active missions were generated for (refresh when it changes).
	missionsDay: number,
	-- Active daily missions (rebuilt each new day by DailyService).
	dailyMissions: { DailyMission },
}

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

-- A fresh default profile. Built new each call so no two players ever share the
-- same inner tables (a shallow copy would alias them — a classic bug).
local function defaultData(): PlayerData
	local now = os.time()
	return {
		coins = GameConfig.StartingCoins,
		hotDogs = {},
		stealCharges = GameConfig.MaxStealCharges,
		lastChargeAt = now,
		shieldUntil = now + GameConfig.ShieldDurationSeconds,
		totalSteals = 0,
		defenses = { wall = false, guard = false },
		grillLvl = 1,
		displaySlotsLvl = 1,
		vaultSlotsLvl = 1,
		rebirths = 0,
		prestige = 0,
		lastSeen = now,
		cooksSinceRare = 0,
		dexRewarded = false,
		lastDailyDay = 0,
		streak = 0,
		missionsDay = 0,
		dailyMissions = {},
	}
end

-- In-memory copy of each active player's data, keyed by UserId. This is the
-- authoritative value while the player is in-game; the DataStore is just where
-- we persist it between sessions.
local cache: { [number]: PlayerData } = {}

-- Load a player's data into the cache and return it. Unknown/missing fields are
-- back-filled from defaults so older (v2) saves keep working.
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
		if type(result.stealCharges) == "number" then
			data.stealCharges = math.clamp(result.stealCharges, 0, GameConfig.MaxStealCharges)
		end
		if type(result.lastChargeAt) == "number" then
			data.lastChargeAt = result.lastChargeAt
		end
		if type(result.shieldUntil) == "number" then
			-- Returning players keep whatever shield they had left (usually none);
			-- only brand-new profiles get the fresh full shield window.
			data.shieldUntil = result.shieldUntil
		end
		if type(result.totalSteals) == "number" then
			data.totalSteals = result.totalSteals
		end
		if type(result.defenses) == "table" then
			data.defenses.wall = result.defenses.wall == true
			data.defenses.guard = result.defenses.guard == true
		end
		-- === M3 fields (all optional; older saves fall back to the defaults above) ===
		if type(result.grillLvl) == "number" then
			data.grillLvl = math.max(1, math.floor(result.grillLvl))
		end
		if type(result.displaySlotsLvl) == "number" then
			data.displaySlotsLvl = math.max(1, math.floor(result.displaySlotsLvl))
		end
		if type(result.vaultSlotsLvl) == "number" then
			data.vaultSlotsLvl = math.max(1, math.floor(result.vaultSlotsLvl))
		end
		if type(result.rebirths) == "number" then
			data.rebirths = math.max(0, math.floor(result.rebirths))
		end
		if type(result.prestige) == "number" then
			data.prestige = math.max(0, math.floor(result.prestige))
		end
		if type(result.lastSeen) == "number" then
			data.lastSeen = result.lastSeen
		end
		if type(result.cooksSinceRare) == "number" then
			data.cooksSinceRare = math.max(0, math.floor(result.cooksSinceRare))
		end
		data.dexRewarded = result.dexRewarded == true
		if type(result.lastDailyDay) == "number" then
			data.lastDailyDay = math.floor(result.lastDailyDay)
		end
		if type(result.streak) == "number" then
			data.streak = math.max(0, math.floor(result.streak))
		end
		if type(result.missionsDay) == "number" then
			data.missionsDay = math.floor(result.missionsDay)
		end
		if type(result.dailyMissions) == "table" then
			for _, m in result.dailyMissions do
				if
					type(m) == "table"
					and type(m.id) == "string"
					and type(m.kind) == "string"
					and type(m.target) == "number"
				then
					table.insert(data.dailyMissions, {
						id = m.id,
						kind = m.kind,
						target = m.target,
						progress = type(m.progress) == "number" and m.progress or 0,
						claimed = m.claimed == true,
					})
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

	-- Stamp the save time so a rejoin can grant capped offline earnings (item 7).
	data.lastSeen = os.time()

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
