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

	-- === Rotating shop (M3 remainder) ===
	-- A daily-rotating set of SPECIFIC hot dogs you can buy directly with coins — a
	-- targeted goal that dampens pure-cook RNG. Offers are picked deterministically
	-- from the UTC day index (ShopService), so every player/server sees the same shop
	-- that day. Buying is unlimited in v1 (a per-rotation purchase cap is a fast-follow);
	-- prices are premium so cooking stays the coin-efficient path and the shop is the
	-- "pay for certainty" option.
	-- How many distinct dogs the shop offers each rotation.
	ShopSlotCount = 6,
	-- Seconds per rotation (86,400 = one UTC day). Also the day-index divisor.
	ShopRefreshSeconds = 24 * 60 * 60,
	-- Relative chance each rarity is drawn into a shop slot. Flatter than the cook
	-- roll weights so the shop actually surfaces mid-tier dogs; Legendary+ is a rare
	-- "lucky day". Keyed by rarity name.
	ShopRarityWeights = {
		Common = 30,
		Uncommon = 30,
		Rare = 20,
		Epic = 12,
		Legendary = 5,
		Mythic = 2,
		Secret = 0.5,
	},
	-- Coin price to buy a dog of each rarity. Payback (price ÷ income/sec) rises with
	-- rarity — 150s for Common up to 600s for Secret — so rarer dogs are a premium /
	-- prestige purchase, never a shortcut to optimal income.
	ShopRarityPrices = {
		Common = 150,
		Uncommon = 500,
		Rare = 1800,
		Epic = 6000,
		Legendary = 22000,
		Mythic = 75000,
		Secret = 300000,
	},
	-- Rotating-shop per-day purchase cap (closes the v1 unlimited-buys fast-follow).
	-- 0 = unlimited. Tracked per player in PlayerData.shopBuys (see DataManager _v5).
	ShopDailyBuyCap = 0,

	-- === Mutations / variants (M3 remainder) ===
	-- Chance (0-1) that a freshly acquired dog (cook, and optionally steal) is minted
	-- as a mutation instead of plain "base". When it mutates, WHICH variant is chosen
	-- by the per-variant `mintWeight` in Variants.luau. Reasoned placeholder — tune.
	MutationChance = 0.04,
	-- Whether stolen dogs can also roll a mutation on deposit (cook always can).
	MutateOnSteal = false,

	-- === Prestige spending (M3 remainder) ===
	-- Premium unlocks bought with banked `prestige` currency (never Robux). `effect`
	-- is interpreted by PrestigeShopService. Reasoned placeholders.
	PrestigeShopItems = {
		{
			id = "income10",
			cost = 5,
			label = "+10% permanent income",
			effect = "incomeMult",
			amount = 0.10,
		},
		{
			id = "display1",
			cost = 8,
			label = "+1 display slot",
			effect = "bonusDisplay",
			amount = 1,
		},
		{ id = "vault1", cost = 12, label = "+1 vault slot", effect = "bonusVault", amount = 1 },
		{
			id = "mutluck",
			cost = 15,
			label = "+50% mutation luck",
			effect = "mutationLuck",
			amount = 0.5,
		},
	},

	-- === Fusion (M3 remainder) ===
	-- Combine N duplicates of a dog into a better outcome. `inputs` = how many of the
	-- same key are consumed; result is interpreted by FusionService (upgrade tier or
	-- force a mutation). Reasoned placeholders.
	FusionInputs = 5,
	FusionForcesMutation = true,

	-- === Traps (M2 fast-follow / 4th defense) ===
	TrapCost = 450,
	TrapStunSeconds = 4,
	TrapRange = 10,

	-- === Weekly events (M4) ===
	-- Active event is chosen deterministically by week index (like the shop's UTC-day
	-- trick) so all servers agree. `modifier` interpreted by EventService.
	EventRefreshSeconds = 7 * 24 * 60 * 60, -- one week
	Events = {
		{ id = "doubleIncome", label = "Double Income Weekend", modifier = "income2x" },
		{ id = "dogRain", label = "Dog Rain", modifier = "freeCookBursts" },
		{ id = "discountCook", label = "Discount Cook", modifier = "cookHalfPrice" },
	},
	-- Coins/points needed per event reward-track tier (reasoned placeholder).
	EventRewardTiers = { 100, 300, 700, 1500 },

	-- === Leaderboards (M4, OrderedDataStore) ===
	LeaderboardTopN = 25,
	LeaderboardRefreshSeconds = 60,

	-- === Achievements (M4) ===
	-- `metric` is a tracked stat; grant `reward` coins once `target` is reached.
	Achievements = {
		{ id = "collect10", metric = "dogs", target = 10, reward = 500, label = "Collect 10 dogs" },
		{
			id = "collect30",
			metric = "dogs",
			target = 30,
			reward = 2500,
			label = "Collect 30 dogs",
		},
		{ id = "steal25", metric = "steals", target = 25, reward = 2000, label = "Steal 25 dogs" },
		{
			id = "steal100",
			metric = "steals",
			target = 100,
			reward = 10000,
			label = "Steal 100 dogs",
		},
		{
			id = "rebirth3",
			metric = "rebirths",
			target = 3,
			reward = 5000,
			label = "Rebirth 3 times",
		},
	},

	-- === Codes (M4) — creator-marketing lever. code -> reward coins. ===
	Codes = {
		LAUNCH = 1000,
		GLIZZY = 500,
	},

	-- === Monetization (M5) — all non-pay-to-win; NEVER paid gacha ===
	-- Real asset ids get filled in on the Creator Dashboard; 0 = unconfigured stub.
	GamePassIds = {
		extraSlots = 0, -- first pass: +N display/vault slots
		vip = 0, -- first pass: VIP perks (badge, chat tag, small boosts)
		doubleCoins = 0, -- later: 2x coins
		autoCollect = 0, -- later: auto-collect income
	},
	DevProductIds = {
		coinsSmall = 0,
		coinsLarge = 0,
		offlineRefill = 0,
		stealCharges = 0,
	},
	-- Grant amounts for dev products + pass effects (reasoned placeholders).
	ExtraSlotsPassDisplay = 2,
	ExtraSlotsPassVault = 1,
	VipIncomeBonus = 0.10,
	DoubleCoinsMult = 2.0,
	ProductGrants = {
		coinsSmall = 1000,
		coinsLarge = 12000,
		stealCharges = 5,
	},

	-- === Cosmetics (M5) — skins/trails/titles; cost in Robux (pass/product) or prestige ===
	Cosmetics = {
		{ id = "skinGold", kind = "standSkin", label = "Gold Stand", prestigeCost = 20 },
		{ id = "trailFire", kind = "trail", label = "Fire Trail", prestigeCost = 10 },
		{ id = "titleGlizzKing", kind = "title", label = "Glizzy King", prestigeCost = 25 },
	},

	-- === Trading (M6) — baseline safeguards ===
	TradeCooldownSeconds = 30,
	TradeMaxItems = 6,

	-- === Emotes (M6) — preset taunts, no free text ===
	Emotes = { "Laugh", "Cry", "Point", "Dance", "Wave" },
}

return GameConfig
