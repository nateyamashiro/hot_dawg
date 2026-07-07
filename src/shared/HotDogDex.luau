--!strict
-- The "dex" of every hot dog in the game, plus the weighted roll used when a
-- player cooks one. Lives in ReplicatedStorage so BOTH the server (which does
-- the authoritative rolling) and the client (which colours the reveal) can read
-- the same data.

local GameConfig = require(script.Parent.GameConfig)
local Variants = require(script.Parent.Variants)

local HotDogDex = {}

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"

export type HotDog = {
	name: string,
	rarity: Rarity,
	income: number, -- coins per second this hot dog generates while owned
}

-- Rarity tiers, ordered common -> rare. `weight` is the relative chance of
-- rolling this tier; `income` is coins/sec per hot dog of the tier.
local RARITY = {
	{
		rarity = "Common" :: Rarity,
		weight = 100,
		income = 1,
		color = Color3.fromRGB(200, 200, 200),
	},
	{ rarity = "Uncommon" :: Rarity, weight = 40, income = 3, color = Color3.fromRGB(90, 200, 90) },
	{ rarity = "Rare" :: Rarity, weight = 12, income = 8, color = Color3.fromRGB(70, 140, 240) },
	{ rarity = "Epic" :: Rarity, weight = 4, income = 20, color = Color3.fromRGB(170, 90, 230) },
	{
		rarity = "Legendary" :: Rarity,
		weight = 1.5,
		income = 55,
		color = Color3.fromRGB(240, 170, 40),
	},
	{
		rarity = "Mythic" :: Rarity,
		weight = 0.4,
		income = 150,
		color = Color3.fromRGB(240, 70, 70),
	},
	{
		rarity = "Secret" :: Rarity,
		weight = 0.06,
		income = 500,
		color = Color3.fromRGB(15, 15, 15),
	},
}

-- The hot dogs available in each tier. Add more here as you make new content —
-- this is the single place you expand the collection. Names lean food-pun +
-- meme (GDD §4.4). ~30 at launch, growing over time.
local DOGS_BY_RARITY: { [string]: { string } } = {
	Common = {
		"Plain Dog",
		"Ketchup Dog",
		"Mustard Dog",
		"Bun Buddy",
		"Sad Lil' Weenie",
		"Mystery Meat Mike",
	},
	Uncommon = { "Mustard Mutt", "Relish Rex", "Sauerkraut Sam", "Onion Ninja", "Pickle Pete" },
	Rare = {
		"Chicago Dog",
		"Chili Cheese Champ",
		"Jalapeño Popper",
		"Slaw Boss",
		"Coney Islander",
	},
	Epic = { "Corn Dog King", "Bacon-Wrapped Beast", "Pretzel Dog Prince", "Nacho Dog Deluxe" },
	Legendary = { "Footlong Phantom", "Glizzy Gladiator", "Sizzler Supreme", "Danger Dog Diablo" },
	Mythic = { "Golden Glizzy", "Cosmic Corndog", "Rizz Dog" },
	Secret = { "404 Dog Not Found", "The Eternal Weenie", "Glizzus Maximus" },
}

-- Flat lookup by name, built once at load. Lets us find a dog's income/rarity
-- from just the name we stored in the player's data.
local byName: { [string]: HotDog } = {}
for _, def in RARITY do
	for _, name in DOGS_BY_RARITY[def.rarity] do
		byName[name] = { name = name, rarity = def.rarity, income = def.income }
	end
end

-- Look up a hot dog by name.
function HotDogDex.get(name: string): HotDog?
	return byName[name]
end

-- Variant-aware lookup by an inventory KEY (may encode a mutation, e.g.
-- "Chicago Dog#Gold"). Returns the base dog with its income scaled by the
-- variant multiplier, so income/sort math works on composite keys. Plain names
-- decode to the base variant, so this is a safe superset of get(). Used by
-- Main.incomePerSecond, sortedUnits, and StealService's carry visuals.
function HotDogDex.getByKey(key: string): HotDog?
	local name, variant = Variants.decode(key)
	local base = byName[name]
	if not base then
		return nil
	end
	return {
		name = base.name,
		rarity = base.rarity,
		income = base.income * Variants.mult(variant),
	}
end

-- The display colour for a rarity (used by the reveal UI and stealable pedestals).
function HotDogDex.colorFor(rarity: Rarity): Color3
	for _, def in RARITY do
		if def.rarity == rarity then
			return def.color
		end
	end
	return Color3.fromRGB(255, 255, 255)
end

-- The first RARITY index considered "Rare or better" (Rare, Epic, ... Secret).
local RARE_INDEX = 3

-- 1-based rarity rank (Common = 1 … Secret = 7). Lets callers ask "is this Rare+?".
function HotDogDex.rarityRank(rarity: Rarity): number
	for i, def in RARITY do
		if def.rarity == rarity then
			return i
		end
	end
	return 1
end

-- Per-tier roll weights after applying the grill's Rare+ multiplier. A better grill
-- scales up the weight of every Rare-or-better tier (item 5). Shared by roll + odds.
local function effectiveWeights(grillLvl: number?): { number }
	local levels = GameConfig.GrillLevels
	local def = levels[grillLvl or 1] or levels[#levels]
	local mult = def.rareWeightMult
	local weights: { number } = {}
	for i, tier in RARITY do
		weights[i] = if i >= RARE_INDEX then tier.weight * mult else tier.weight
	end
	return weights
end

-- Roll a random hot dog, weighted by rarity. Called on the SERVER only.
-- `grillLvl` improves the odds; `guaranteeRare` (pity) restricts the roll to Rare+.
function HotDogDex.roll(grillLvl: number?, guaranteeRare: boolean?): HotDog
	local weights = effectiveWeights(grillLvl)
	local startIdx = if guaranteeRare then RARE_INDEX else 1

	local total = 0
	for i = startIdx, #RARITY do
		total += weights[i]
	end

	local pick = math.random() * total
	for i = startIdx, #RARITY do
		pick -= weights[i]
		if pick <= 0 then
			local names = DOGS_BY_RARITY[RARITY[i].rarity]
			return byName[names[math.random(1, #names)]]
		end
	end

	-- Unreachable in practice; satisfies the type checker with a real return.
	local names = DOGS_BY_RARITY[RARITY[startIdx].rarity]
	return byName[names[1]]
end

-- Disclosed per-tier drop chances for the cook UI (item 9), given the grill level.
function HotDogDex.odds(grillLvl: number?): { { rarity: Rarity, chance: number } }
	local weights = effectiveWeights(grillLvl)
	local total = 0
	for _, w in weights do
		total += w
	end
	local out: { { rarity: Rarity, chance: number } } = {}
	for i, tier in RARITY do
		table.insert(out, { rarity = tier.rarity, chance = weights[i] / total })
	end
	return out
end

-- Every hot dog in dex order (Common → Secret, roster order). Used by the dex grid.
function HotDogDex.all(): { HotDog }
	local out: { HotDog } = {}
	for _, def in RARITY do
		for _, name in DOGS_BY_RARITY[def.rarity] do
			table.insert(out, byName[name])
		end
	end
	return out
end

-- One displayed dog unit on a stand. Carries the inventory KEY (so a stolen or
-- re-synced unit maps back to the right stack, variant included), the variant-scaled
-- income used for sorting, and the label/colour the pedestal shows.
export type Unit = {
	key: string, -- inventory key, may encode a mutation ("Chicago Dog#Gold")
	name: string, -- base dog name (roster identity)
	displayName: string, -- variant-aware label ("Gold Chicago Dog")
	rarity: Rarity,
	income: number, -- base income × the variant multiplier
	variant: Variants.Variant,
}

-- Expand a `{key -> count}` inventory into a flat list of individual dog units,
-- sorted by income DESCENDING (tie-broken by name for stable ordering). Composite
-- keys decode to their base dog with variant-scaled income, so a Gold dog correctly
-- outranks its plain twin. Used by PlotManager to decide which units go in the safe
-- vault (the top ones) vs. the stealable display pedestals (the overflow).
function HotDogDex.sortedUnits(hotDogs: { [string]: number }): { Unit }
	local units: { Unit } = {}
	for key, count in hotDogs do
		local name, variant = Variants.decode(key)
		local base = byName[name]
		if base then
			local unit: Unit = {
				key = key,
				name = base.name,
				displayName = Variants.displayName(key),
				rarity = base.rarity,
				income = base.income * Variants.mult(variant),
				variant = variant,
			}
			for _ = 1, count do
				table.insert(units, unit)
			end
		end
	end
	table.sort(units, function(a, b)
		if a.income ~= b.income then
			return a.income > b.income
		end
		return a.displayName < b.displayName
	end)
	return units
end

return HotDogDex
