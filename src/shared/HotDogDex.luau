--!strict
-- The "dex" of every hot dog in the game, plus the weighted roll used when a
-- player cooks one. Lives in ReplicatedStorage so BOTH the server (which does
-- the authoritative rolling) and the client (which colours the reveal) can read
-- the same data.

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
	{ rarity = "Common" :: Rarity, weight = 100, income = 1, color = Color3.fromRGB(200, 200, 200) },
	{ rarity = "Uncommon" :: Rarity, weight = 45, income = 3, color = Color3.fromRGB(90, 200, 90) },
	{ rarity = "Rare" :: Rarity, weight = 20, income = 8, color = Color3.fromRGB(70, 140, 240) },
	{ rarity = "Epic" :: Rarity, weight = 8, income = 20, color = Color3.fromRGB(170, 90, 230) },
	{ rarity = "Legendary" :: Rarity, weight = 3, income = 55, color = Color3.fromRGB(240, 170, 40) },
	{ rarity = "Mythic" :: Rarity, weight = 0.9, income = 150, color = Color3.fromRGB(240, 70, 70) },
	{ rarity = "Secret" :: Rarity, weight = 0.1, income = 500, color = Color3.fromRGB(15, 15, 15) },
}

-- The hot dogs available in each tier. Add more here as you make new content —
-- this is the single place you expand the collection.
local DOGS_BY_RARITY: { [string]: { string } } = {
	Common = { "Plain Dog", "Ketchup Dog" },
	Uncommon = { "Mustard Mutt", "Relish Rex" },
	Rare = { "Chicago Dog", "Chili Cheese Champ" },
	Epic = { "Corn Dog King", "Bacon-Wrapped Beast" },
	Legendary = { "Footlong Phantom", "Glizzy Gladiator" },
	Mythic = { "Golden Glizzy", "Cosmic Corndog" },
	Secret = { "404 Dog Not Found", "The Eternal Weenie" },
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

-- The display colour for a rarity (used by the reveal UI).
function HotDogDex.colorFor(rarity: Rarity): Color3
	for _, def in RARITY do
		if def.rarity == rarity then
			return def.color
		end
	end
	return Color3.fromRGB(255, 255, 255)
end

-- Roll a random hot dog, weighted by rarity. Called on the SERVER only.
function HotDogDex.roll(): HotDog
	local total = 0
	for _, def in RARITY do
		total += def.weight
	end

	local pick = math.random() * total
	for _, def in RARITY do
		pick -= def.weight
		if pick <= 0 then
			local names = DOGS_BY_RARITY[def.rarity]
			return byName[names[math.random(1, #names)]]
		end
	end

	-- Unreachable in practice; satisfies the type checker with a real return.
	return byName["Plain Dog"]
end

return HotDogDex
