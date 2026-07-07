--!strict
-- Central tunables for the game. Both the server and client read from here,
-- so there is exactly one source of truth for numbers you'll want to balance.
-- Everything below is placeholder-tuned; rebalance during playtests.

local GameConfig = {
	-- === Core economy (Milestone 1) ===
	-- Seconds between passive income ticks.
	TickInterval = 1,
	-- Coins a brand-new player starts with. ~10 cooks of runway so a fresh player
	-- reliably reaches their first Rare in the opening minute or two (see §6 tuning).
	StartingCoins = 100,
	-- Coins it costs to cook (roll) one random hot dog.
	CookCost = 10,

	-- === Plots / bases (Milestone 2) ===
	-- How many plot pads the world spawns (cap this near the max server size).
	PlotCount = 20,
	-- Plots are laid out as two long parallel rows facing a central aisle.
	-- Distance between neighbouring stands along a row (studs).
	PlotRowSpacing = 42,
	-- Distance between the two rows — the width of the central street (studs).
	PlotRowSeparation = 128,
	-- NOTE: display (stealable) + vault slot counts are now upgrade-driven — see
	-- DisplaySlotLevels / VaultSlotLevels / MaxDisplaySlots / MaxVaultSlots below.

	-- === Stealing (Milestone 2) ===
	-- Base seconds to hold the "Steal" prompt before the dog detaches.
	StealHoldSeconds = 3,
	-- WalkSpeed while carrying a stolen dog (normal Roblox default is 16). Slow
	-- enough to chase down, fast enough that a clean getaway feels achievable.
	CarryWalkSpeed = 10,
	NormalWalkSpeed = 16,
	-- Steal energy: max charges and how often (seconds) one recharges.
	MaxStealCharges = 5,
	ChargeRechargeSeconds = 45,
	-- Can't re-raid the SAME victim again until this many seconds pass.
	PerTargetCooldownSeconds = 120,
	-- Each successful raid on a victim adds this much hold-time to your NEXT raid
	-- on them (diminishing returns / discourages fixating on one target).
	DiminishingPenaltyPerRaid = 1.5,
	-- New players are un-raidable for this long (seconds of wall-clock since first join).
	ShieldDurationSeconds = 600,

	-- === Defense (Milestone 2) ===
	-- Net tool: how long a tagged thief is stunned, and the range to tag from.
	NetStunSeconds = 3,
	NetRange = 12,
	-- Buyable wall: coin cost and how much it lengthens the steal hold on your plot.
	WallCost = 250,
	WallHoldBonusSeconds = 2,
	-- Buyable NPC guard: coin cost and how often it scans for carrying thieves.
	GuardCost = 600,
	GuardScanSeconds = 1.5,

	-- === Progression (Milestone 3) ===
	-- Grill tiers: index = level. `rareWeightMult` scales the roll weight of every
	-- Rare-or-better tier (better grill = better odds). Level 1 is the free default.
	GrillLevels = {
		{ cost = 0, rareWeightMult = 1.0 },
		{ cost = 500, rareWeightMult = 1.4 },
		{ cost = 2500, rareWeightMult = 1.9 },
		{ cost = 10000, rareWeightMult = 2.6 },
		{ cost = 40000, rareWeightMult = 3.6 },
		{ cost = 150000, rareWeightMult = 5.0 },
	},
	-- Display (stealable) slot tiers: index = level, `slots` = how many pedestals fill.
	-- L1 must match the starting DisplaySlots; the max determines pre-built anchors.
	DisplaySlotLevels = {
		{ cost = 0, slots = 8 },
		{ cost = 750, slots = 10 },
		{ cost = 3000, slots = 12 },
		{ cost = 12000, slots = 14 },
		{ cost = 50000, slots = 16 },
	},
	-- Safe vault slot tiers: index = level, `slots` = how many vault shelves fill.
	VaultSlotLevels = {
		{ cost = 0, slots = 3 },
		{ cost = 1500, slots = 4 },
		{ cost = 8000, slots = 5 },
		{ cost = 35000, slots = 6 },
	},
	-- Max anchors PlotManager pre-builds (must be >= the top DisplaySlot/VaultSlot level).
	MaxDisplaySlots = 16,
	MaxVaultSlots = 6,

	-- Rebirth: cost grows geometrically; each rebirth adds a permanent income % and
	-- grants prestige currency (banked for future premium unlocks).
	RebirthBaseCost = 5000,
	RebirthCostGrowth = 2.5,
	RebirthIncomeBonus = 0.25, -- +25% income per rebirth
	RebirthPrestigeReward = 1,

	-- Offline earnings are granted on rejoin, capped to this many seconds away.
	OfflineCapSeconds = 8 * 60 * 60, -- 8 hours

	-- Cook: how many rolls a "cook 10" buys, and the pity counter that guarantees a
	-- Rare-or-better once you've cooked this many times without one.
	CookTenCount = 10,
	PityCooks = 20,

	-- Dex: one-time reward for collecting every hot dog.
	DexCompletionReward = 25000,
	DexCompletionPrestige = 3,

	-- Daily login streak: reward for claim #N (streak clamps to the last entry).
	DailyStreakRewards = { 100, 200, 350, 600, 1000, 1600, 2500 },
	-- How many daily missions are active at once, drawn from the pool below.
	DailyMissionCount = 3,
	-- Mission pool: `kind` is what to track, `target` the goal, `reward` the coins.
	DailyMissionDefs = {
		{ id = "cook15", kind = "cook", target = 15, reward = 300, label = "Cook 15 hot dogs" },
		{ id = "cook40", kind = "cook", target = 40, reward = 800, label = "Cook 40 hot dogs" },
		{ id = "steal3", kind = "steal", target = 3, reward = 500, label = "Steal 3 dogs" },
		{ id = "steal8", kind = "steal", target = 8, reward = 1200, label = "Steal 8 dogs" },
		{ id = "earn2k", kind = "earn", target = 2000, reward = 400, label = "Earn 2,000 coins" },
		{ id = "earn8k", kind = "earn", target = 8000, reward = 1000, label = "Earn 8,000 coins" },
	},
}

return GameConfig
