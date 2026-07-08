--!strict
-- Mutations / variants (M3 remainder). The single source of truth for the
-- "composite-key stacks" inventory model: a hot dog is stored in `data.hotDogs`
-- under a KEY that encodes its variant. Base dogs keep their plain name
-- ("Chicago Dog"); a mutation appends "#<Variant>" ("Chicago Dog#Gold"). That
-- keeps `hotDogs` a plain { [string]: number } — old saves are already valid
-- (plain name = base) and the tested steal/shop/dex code keeps working on
-- strings; only the INTERPRETATION lives here.
--
-- Lives in ReplicatedStorage so both sides read the same variant math (server
-- mints + prices income; client colours the tag).

local Variants = {}

export type Variant = "base" | "Gold" | "Rainbow" | "Giant"

export type VariantDef = {
	variant: Variant,
	label: string, -- prefix shown before the dog name ("" for base)
	incomeMult: number, -- income multiplier applied on top of the base dog
	-- Relative chance of being chosen WHEN a mutation happens (base is excluded
	-- from minting; the base-vs-mutation coin flip is GameConfig.MutationChance).
	mintWeight: number,
	color: Color3, -- accent/tint used by the reveal + pedestal tag
}

-- Ordered rarest-last is fine; minting weights make Giant the jackpot.
local DEFS: { VariantDef } = {
	{
		variant = "base" :: Variant,
		label = "",
		incomeMult = 1,
		mintWeight = 0, -- never minted; it's the default
		color = Color3.fromRGB(255, 255, 255),
	},
	{
		variant = "Gold" :: Variant,
		label = "Gold",
		incomeMult = 2,
		mintWeight = 100,
		color = Color3.fromRGB(240, 200, 60),
	},
	{
		variant = "Rainbow" :: Variant,
		label = "Rainbow",
		incomeMult = 3.5,
		mintWeight = 30,
		color = Color3.fromRGB(255, 120, 200),
	},
	{
		variant = "Giant" :: Variant,
		label = "Giant",
		incomeMult = 5,
		mintWeight = 8,
		color = Color3.fromRGB(120, 220, 120),
	},
}

local byVariant: { [string]: VariantDef } = {}
for _, def in DEFS do
	byVariant[def.variant] = def
end

local SEP = "#" -- dog names never contain "#", so this round-trips cleanly.

-- Encode a (name, variant) pair into an inventory key. Base variant => plain name.
function Variants.encode(name: string, variant: Variant): string
	if variant == "base" then
		return name
	end
	return name .. SEP .. variant
end

-- Decode an inventory key back into (base name, variant).
function Variants.decode(key: string): (string, Variant)
	local sepAt = string.find(key, SEP, 1, true)
	if not sepAt then
		return key, "base" :: Variant
	end
	local name = string.sub(key, 1, sepAt - 1)
	local variant = string.sub(key, sepAt + 1)
	if byVariant[variant] then
		return name, variant :: Variant
	end
	return key, "base" :: Variant
end

-- Just the base dog name for a key (roster/dex lookups go through this).
function Variants.baseName(key: string): string
	local name, _ = Variants.decode(key)
	return name
end

-- The income multiplier for a variant (1 for base / unknown).
function Variants.mult(variant: Variant): number
	local def = byVariant[variant]
	return def and def.incomeMult or 1
end

function Variants.def(variant: Variant): VariantDef?
	return byVariant[variant]
end

-- The next variant "up" the mutation ladder (DEFS order = base < Gold < Rainbow <
-- Giant), or nil if already at the top. Fusion uses this: N dupes of a key fuse into
-- one of the same base dog at the next variant up (5 plain → 1 Gold → 1 Rainbow → …).
-- Both sides read it (server grants the result, client previews it), so the ladder
-- stays a single source of truth.
function Variants.nextVariant(variant: Variant): Variant?
	for i, def in DEFS do
		if def.variant == variant then
			local nextDef = DEFS[i + 1]
			return nextDef and nextDef.variant or nil
		end
	end
	return nil
end

-- Human label like "Gold Chicago Dog" (or just the name for base).
function Variants.displayName(key: string): string
	local name, variant = Variants.decode(key)
	local def = byVariant[variant]
	if def and def.label ~= "" then
		return def.label .. " " .. name
	end
	return name
end

-- Pick a mutation variant weighted by mintWeight (base excluded). Called on the
-- SERVER when GameConfig.MutationChance fires. `rng` optional for determinism.
function Variants.pickMint(rng: Random?): Variant
	local total = 0
	for _, def in DEFS do
		total += def.mintWeight
	end
	if total <= 0 then
		return "base" :: Variant
	end
	local pick = (rng and rng:NextNumber() or math.random()) * total
	for _, def in DEFS do
		pick -= def.mintWeight
		if pick <= 0 then
			return def.variant
		end
	end
	return "Gold" :: Variant
end

return Variants
