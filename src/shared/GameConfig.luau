--!strict
-- Central tunables for the game. Both the server and client read from here,
-- so there is exactly one source of truth for numbers you'll want to balance.

local GameConfig = {
	-- Seconds between passive income ticks.
	TickInterval = 1,
	-- Coins a brand-new player starts with (enough to cook a few hot dogs).
	StartingCoins = 50,
	-- Coins it costs to cook (roll) one random hot dog.
	CookCost = 10,
}

return GameConfig
