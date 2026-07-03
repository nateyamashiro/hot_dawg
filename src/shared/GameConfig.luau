--!strict
-- Central tunables for the game. Both the server and client read from here,
-- so there is exactly one source of truth for numbers you'll want to balance.

local GameConfig = {
	-- Base passive income: coins earned per tick before any upgrades.
	CoinsPerTick = 1,
	-- Seconds between automatic coin ticks.
	TickInterval = 1,

	Upgrade = {
		-- Cost of your first upgrade (level 0 -> 1).
		BaseCost = 25,
		-- Each subsequent upgrade costs this much more (geometric growth).
		CostGrowth = 1.5,
		-- Each upgrade level adds this much to CoinsPerTick.
		CoinsPerTickBonus = 1,
	},
}

return GameConfig
