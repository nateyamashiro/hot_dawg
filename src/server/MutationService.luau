--!strict
-- Mutations minting (M3 remainder, GDD §4.4). Random-on-acquire model: when a dog
-- is cooked (and optionally stolen), there's a GameConfig.MutationChance it's minted
-- as a variant (Gold/Rainbow/Giant) instead of base. This module is the single
-- server-side decision point; it returns the INVENTORY KEY to bank (a composite key
-- like "Chicago Dog#Gold", or just the plain name for base). No remotes — it rides
-- the existing cook/steal flow. See Variants.luau for the key encoding + income math.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Variants = require(ReplicatedStorage.Shared.Variants)

local MutationService = {}

-- Given a freshly-acquired base dog name, roll for a mutation and return the key to
-- store in data.hotDogs. `luckBonus` (0-1) lets prestige/passes raise the odds
-- (data.mutationLuck, banked by the prestige shop). Wired into Main.doCook (cook +
-- cook-10) with the variant riding CookResult for a bigger reveal, and into
-- StealService.onDeposit (gated by GameConfig.MutateOnSteal — base dogs only).
function MutationService.maybeMint(baseName: string, luckBonus: number?): string
	local chance = GameConfig.MutationChance * (1 + (luckBonus or 0))
	if math.random() >= chance then
		return baseName -- base variant: plain name
	end
	local variant = Variants.pickMint()
	return Variants.encode(baseName, variant)
end

return MutationService
