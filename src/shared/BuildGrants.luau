--!strict
-- Pure helpers over GameConfig.BuildCatalog + a player's `built` set (design plan
-- §2.3). THE grant rule: every building effect is derived at READ time from
-- data.built — never banked into another field — so rebuild-on-join can't
-- double-apply capacity or income. Lives in ReplicatedStorage so the server folds
-- grants into capacity/income and the client Build panel renders owned/next/locked
-- from the same math.

local GameConfig = require(script.Parent.GameConfig)

local BuildGrants = {}

export type Grants = {
	kind: string, -- "floor" | "access" | "defense" | "income"
	displaySlots: number?, -- floor: pedestal anchors added on the new floor
	cookerSlots: number?, -- floor: each = +15% stove output (AutoCookerService)
	access: string?, -- access: "stairs" | "elevator"
	floor: number?, -- access: which floor it reaches
	defense: string?, -- defense: "wall" | "gate"
	incomeMult: number?, -- income: permanent +income fraction (additive)
}

export type Entry = {
	id: string,
	label: string,
	cost: number,
	prereq: string?,
	grants: Grants,
}

local catalog: { Entry } = GameConfig.BuildCatalog :: any

type BuiltSet = { [string]: boolean }

-- The whole catalog in pad-offer order.
function BuildGrants.all(): { Entry }
	return catalog
end

function BuildGrants.entry(id: string): Entry?
	for _, e in catalog do
		if e.id == id then
			return e
		end
	end
	return nil
end

-- Which walk-on pad offers this entry: structural (floor/access/defense) rides the
-- 🏗️ "build" pad; income decor rides the 🎪 "decor" pad.
function BuildGrants.category(e: Entry): string
	return if e.grants.kind == "income" then "decor" else "build"
end

-- The next entry a pad should offer: first catalog entry (array order) in the
-- category that is NOT built and whose prereq (if any) IS built. nil = exhausted
-- (the pad hides itself).
function BuildGrants.nextEntry(built: BuiltSet, category: string): Entry?
	for _, e in catalog do
		if BuildGrants.category(e) == category and not built[e.id] then
			if e.prereq == nil or built[e.prereq] then
				return e
			end
		end
	end
	return nil
end

local function sumGrant(built: BuiltSet, field: string): number
	local total = 0
	for _, e in catalog do
		if built[e.id] then
			local value = (e.grants :: any)[field]
			if type(value) == "number" then
				total += value
			end
		end
	end
	return total
end

-- Extra stealable-display pedestal slots from built floors (PlotManager capacity).
function BuildGrants.displaySlotBonus(built: BuiltSet): number
	return sumGrant(built, "displaySlots")
end

-- Cooker slots from built floors (+15% stove output each; AutoCookerService).
function BuildGrants.cookerSlotBonus(built: BuiltSet): number
	return sumGrant(built, "cookerSlots")
end

-- Permanent decor income bonus, additive with rebirth/prestige (Main.incomeMultiplier).
function BuildGrants.incomeBonus(built: BuiltSet): number
	return sumGrant(built, "incomeMult")
end

return BuildGrants
