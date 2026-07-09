--!strict
-- Handles loading and saving each player's persistent data via DataStores.
--
-- NOTE: DataStores only work in Studio if you enable
--   Game Settings -> Security -> "Enable Studio Access to API Services".
-- Without it, load/save calls fail harmlessly (we pcall + warn) and players
-- simply start from default data each session.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)

-- Bump the "_vN" suffix if you ever change the data shape in a breaking way.
-- v4 adds M3 progression fields (grill/slot levels, rebirth/prestige, offline
-- lastSeen, pity, dex reward, daily streak/missions); load() back-fills them all
-- from defaults so v3 saves upgrade cleanly.
-- v5 (M3-remainder → M6) batches ALL later fields in one migration: vaultPins
-- (manual vault), defenses.trap, achievements, redeemedCodes, eventPoints, VIP +
-- bonus slots + receiptHistory (monetization), tradeCooldownUntil, cosmetics, and
-- shopBuys (per-day cap). hotDogs is UNCHANGED — mutations use composite keys
-- ("Chicago Dog#Gold"), so old plain-name saves are already valid as base dogs.
-- Every field is optional in load() and back-fills from defaults, so v4/v3 upgrade
-- cleanly. Prefer adding future fields to THIS bump's back-fill over a new _vN.
local store = DataStoreService:GetDataStore("StealAGlizzy_PlayerData_v5")

local DataManager = {}

export type Defenses = {
	wall: boolean,
	guard: boolean,
	-- v5: placeable trap (4th defense) — stuns a carrying thief on the plot.
	trap: boolean,
}

-- v5: cosmetics ownership + what's equipped (stand skin / trail / title).
export type Cosmetics = {
	equipped: string?,
	owned: { [string]: boolean },
}

-- v5: rotating-shop per-day purchase counts (enforces GameConfig.ShopDailyBuyCap).
export type ShopBuys = {
	day: number,
	counts: { [string]: number },
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
	-- os.time before which the free single-cook is on cooldown (the glizzy "wall").
	cookReadyAt: number,
	-- One-time dex-completion reward already granted?
	dexRewarded: boolean,
	-- Daily streak: UTC day index of the last streak claim + current streak length.
	lastDailyDay: number,
	streak: number,
	-- UTC day index the active missions were generated for (refresh when it changes).
	missionsDay: number,
	-- Active daily missions (rebuilt each new day by DailyService).
	dailyMissions: { DailyMission },
	-- === v5 fields (M3 remainder → M6). All default-safe; see the store comment. ===
	-- Manual vault selection: inventory keys the player pinned as safe (PlotManager
	-- fills these into the vault first, then tops up by value).
	vaultPins: { [string]: boolean },
	-- Claimed achievement ids (AchievementService).
	achievements: { [string]: boolean },
	-- Codes already redeemed (CodesService), so each pays out once.
	redeemedCodes: { [string]: boolean },
	-- Per-event accumulated points/progress, keyed by event id (EventService).
	eventPoints: { [string]: number },
	-- VIP pass cache (authoritative check still via MarketplaceService on join).
	vip: boolean,
	-- Extra slots granted by the extra-slots game pass / prestige (PlotManager adds
	-- these on top of the coin-upgrade capacity).
	bonusDisplaySlots: number,
	bonusVaultSlots: number,
	-- Processed dev-product receipt ids, so a re-processed receipt can't double-grant.
	receiptHistory: { [string]: boolean },
	-- Prestige-shop unlocks already bought (one-time each), plus the persistent
	-- bonuses they bank: a permanent income-multiplier fraction folded into the
	-- income loop, and a mutation-luck bonus fed to MutationService.maybeMint.
	prestigeUnlocks: { [string]: boolean },
	prestigeIncomeMult: number,
	mutationLuck: number,
	-- os.time until which this player can't start another trade (post-trade cooldown).
	tradeCooldownUntil: number,
	-- Owned + equipped cosmetics (CosmeticService).
	cosmetics: Cosmetics,
	-- Rotating-shop per-day purchase tracking (ShopService cap enforcement).
	shopBuys: ShopBuys,
	-- === Visual-overhaul / tycoon-layer fields (Phase 0 scaffold; all default-safe) ===
	-- Passive auto-cooker level (1-based index into GameConfig.AutoCookerTiers). This
	-- machine emits COINS only — never stealable dogs — so it lives outside hotDogs.
	autoCookerLvl: number,
	-- Which GameConfig.BuildCatalog structure ids the player has constructed.
	built: { [string]: boolean },
	-- Owned + equipped non-damaging weapons (WeaponService).
	weaponsOwned: { [string]: boolean },
	weaponEquipped: string?,
	-- Cooker-upgrader level (index into GameConfig.UpgraderTiers) — multiplies output.
	upgraderLvl: number,
	-- Plot zone/expansion tier (index into GameConfig.ZoneTiers).
	zoneLvl: number,
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
		defenses = { wall = false, guard = false, trap = false },
		grillLvl = 1,
		displaySlotsLvl = 1,
		vaultSlotsLvl = 1,
		rebirths = 0,
		prestige = 0,
		lastSeen = now,
		cooksSinceRare = 0,
		cookReadyAt = 0,
		dexRewarded = false,
		lastDailyDay = 0,
		streak = 0,
		missionsDay = 0,
		dailyMissions = {},
		-- v5 defaults (fresh tables per call so no two players alias them).
		vaultPins = {},
		achievements = {},
		redeemedCodes = {},
		eventPoints = {},
		vip = false,
		bonusDisplaySlots = 0,
		bonusVaultSlots = 0,
		prestigeUnlocks = {},
		prestigeIncomeMult = 0,
		mutationLuck = 0,
		receiptHistory = {},
		tradeCooldownUntil = 0,
		cosmetics = { equipped = nil, owned = {} },
		shopBuys = { day = 0, counts = {} },
		-- Visual-overhaul / tycoon-layer defaults (fresh tables per call).
		-- autoCookerLvl 0 = no stove built yet; the player builds it via a walk-on pad,
		-- then upgrades it. Level N (>=1) indexes GameConfig.AutoCookerTiers.
		autoCookerLvl = 0,
		built = {},
		weaponsOwned = {},
		weaponEquipped = nil,
		upgraderLvl = 1,
		zoneLvl = 1,
	}
end

-- In-memory copy of each active player's data, keyed by UserId. This is the
-- authoritative value while the player is in-game; the DataStore is just where
-- we persist it between sessions.
local cache: { [number]: PlayerData } = {}

-- os.clock() of each player's last save attempt — drives the autosave cadence and
-- the double-save guard (PlayerRemoving + BindToClose both fire on shutdown; the
-- second write inside 5s would only trip the 6s/key DataStore throttle).
local lastSaveAt: { [number]: number } = {}

-- Load a player's data into the cache and return it. Unknown/missing fields are
-- back-filled from defaults so older (v2) saves keep working.
--
-- Returns NIL when the DataStore read fails after retries. Critically, a failed
-- load must NOT cache a fresh default profile: playing on defaults and then
-- saving would OVERWRITE the player's real progress. No cache entry means
-- save/release are structural no-ops; Main kicks the player with a retry message.
function DataManager.load(player: Player): PlayerData?
	local data = defaultData()

	local ok, result
	for attempt = 1, 3 do
		ok, result = pcall(function()
			return store:GetAsync(keyFor(player))
		end)
		if ok then
			break
		end
		warn(
			("[DataManager] Load attempt %d failed for %s: %s"):format(
				attempt,
				player.Name,
				tostring(result)
			)
		)
		task.wait(attempt) -- 1s, 2s backoff before the next try
	end
	if not ok then
		return nil
	end

	if type(result) == "table" then
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
			data.defenses.trap = result.defenses.trap == true
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
		if type(result.cookReadyAt) == "number" then
			data.cookReadyAt = result.cookReadyAt
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
		-- === v5 fields (all optional; older saves keep the defaults above) ===
		-- NOTE: deliberately at the TOP level of the `type(result) == "table"` block —
		-- this was once nested inside the dailyMissions back-fill, which made the
		-- entire tycoon layer's persistence silently depend on that one field.
		local function copyBoolMap(src: any, dst: { [string]: boolean })
			if type(src) == "table" then
				for k, v in src do
					if type(k) == "string" and v == true then
						dst[k] = true
					end
				end
			end
		end
		copyBoolMap(result.vaultPins, data.vaultPins)
		copyBoolMap(result.achievements, data.achievements)
		copyBoolMap(result.redeemedCodes, data.redeemedCodes)
		copyBoolMap(result.receiptHistory, data.receiptHistory)
		copyBoolMap(result.prestigeUnlocks, data.prestigeUnlocks)
		if type(result.eventPoints) == "table" then
			for k, v in result.eventPoints do
				if type(k) == "string" and type(v) == "number" then
					data.eventPoints[k] = v
				end
			end
		end
		data.vip = result.vip == true
		if type(result.bonusDisplaySlots) == "number" then
			data.bonusDisplaySlots = math.max(0, math.floor(result.bonusDisplaySlots))
		end
		if type(result.bonusVaultSlots) == "number" then
			data.bonusVaultSlots = math.max(0, math.floor(result.bonusVaultSlots))
		end
		if type(result.prestigeIncomeMult) == "number" then
			data.prestigeIncomeMult = math.max(0, result.prestigeIncomeMult)
		end
		if type(result.mutationLuck) == "number" then
			data.mutationLuck = math.max(0, result.mutationLuck)
		end
		if type(result.tradeCooldownUntil) == "number" then
			data.tradeCooldownUntil = result.tradeCooldownUntil
		end
		if type(result.cosmetics) == "table" then
			if type(result.cosmetics.equipped) == "string" then
				data.cosmetics.equipped = result.cosmetics.equipped
			end
			copyBoolMap(result.cosmetics.owned, data.cosmetics.owned)
		end
		-- Visual-overhaul / tycoon-layer fields (Phase 0; all optional).
		copyBoolMap(result.built, data.built)
		copyBoolMap(result.weaponsOwned, data.weaponsOwned)
		if type(result.weaponEquipped) == "string" then
			data.weaponEquipped = result.weaponEquipped
		end
		if type(result.autoCookerLvl) == "number" then
			data.autoCookerLvl = math.max(0, math.floor(result.autoCookerLvl))
		end
		if type(result.upgraderLvl) == "number" then
			data.upgraderLvl = math.max(1, math.floor(result.upgraderLvl))
		end
		if type(result.zoneLvl) == "number" then
			data.zoneLvl = math.max(1, math.floor(result.zoneLvl))
		end
		if type(result.shopBuys) == "table" then
			if type(result.shopBuys.day) == "number" then
				data.shopBuys.day = math.floor(result.shopBuys.day)
			end
			if type(result.shopBuys.counts) == "table" then
				for k, v in result.shopBuys.counts do
					if type(k) == "string" and type(v) == "number" then
						data.shopBuys.counts[k] = v
					end
				end
			end
		end
	end

	-- Wall grandfather (P-B, locked decision #5): the old $250 DefenseService wall is
	-- retired; the BuildCatalog perimeter wall is the only physical wall now. Anyone
	-- who owned the old wall gets the build free. Idempotent — runs every load;
	-- `defenses.wall` stays in the save shape for compat but is never set again.
	-- (Deliberately OUTSIDE the nested back-fill blocks so it always runs.)
	if data.defenses.wall then
		data.built.wall = true
	end

	-- Starting glizzy (Phase 0): a brand-new profile (successful load, but no saved
	-- record yet) spawns owning one random Common. Gated on result == nil so a
	-- returning player who lost all their dogs is NOT re-granted one every join.
	if result == nil then
		local starter = HotDogDex.randomOfRarity(GameConfig.StartingGlizzyRarity)
		if starter then
			data.hotDogs[starter.name] = (data.hotDogs[starter.name] or 0) + 1
		end
	end

	-- Prune vault pins for keys no longer owned (stolen/fused away) so the pin map
	-- can't grow forever; SetVaultPin re-validates ownership for live pins anyway.
	for key in data.vaultPins do
		if (data.hotDogs[key] or 0) <= 0 then
			data.vaultPins[key] = nil
		end
	end

	cache[player.UserId] = data
	lastSaveAt[player.UserId] = os.clock() -- joining counts as a fresh checkpoint
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
	local now = os.clock()
	if now - (lastSaveAt[player.UserId] or -math.huge) < 5 then
		return -- just saved (autosave/leave/shutdown overlap); nothing meaningful lost
	end
	lastSaveAt[player.UserId] = now

	-- Stamp the save time so a rejoin can grant capped offline earnings (item 7).
	data.lastSeen = os.time()

	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function(old)
			-- Stale-write guard: if another server already saved NEWER data (quick
			-- server hop landing our delayed write last), keep theirs — returning
			-- nil aborts the write. Full session locking stays a later hardening.
			if type(old) == "table" and type(old.lastSeen) == "number" then
				if old.lastSeen > data.lastSeen then
					return nil
				end
			end
			return data
		end)
	end)

	if not ok then
		warn("[DataManager] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

-- Save then drop a player from the cache (call on PlayerRemoving).
function DataManager.release(player: Player)
	DataManager.save(player)
	cache[player.UserId] = nil
	lastSaveAt[player.UserId] = nil
end

-- Autosave: a crash between leave-saves must not cost a whole session. Every 60s,
-- save anyone whose last write is >3 min old (staggered naturally by join times;
-- respects the per-key throttle via the 5s guard above). Started once from Main.
function DataManager.startAutosave()
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				if os.clock() - (lastSaveAt[player.UserId] or 0) > 180 then
					DataManager.save(player)
				end
			end
		end
	end)
end

return DataManager
