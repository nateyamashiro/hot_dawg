--!strict
-- Buyable progression upgrades (item 5): grill tiers (better roll odds), display
-- slots (more stealable pedestals), and vault slots (more safe storage). Purchases
-- mutate coins + level fields server-side; PlotManager reflects slot capacity and
-- HotDogDex reads the grill level when rolling. Mirrors DefenseService's shape.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)
local PlotManager = require(ServerScriptService.Server.PlotManager)

local UpgradeService = {}

local updateLeaderstats: (player: Player) -> ()
local pushCookStats: (player: Player) -> ()
local pushProgression: (player: Player) -> ()
-- Resolved in init(); held as locals so no statement starts with `(`.
local remFeedback: RemoteEvent
local remBuyUpgrade: RemoteEvent

local function feedback(player: Player, ok: boolean, message: string)
	remFeedback:FireClient(player, ok, message)
end

-- Read/write the level field for a given upgrade kind (explicit branches keep the
-- strict type-checker happy vs. dynamic string indexing of PlayerData).
local function levelsFor(which: string): { { cost: number } }?
	if which == "grill" then
		return GameConfig.GrillLevels
	elseif which == "display" then
		return GameConfig.DisplaySlotLevels
	elseif which == "vault" then
		return GameConfig.VaultSlotLevels
	end
	return nil
end

local function getLevel(data: DataManager.PlayerData, which: string): number
	if which == "grill" then
		return data.grillLvl
	elseif which == "display" then
		return data.displaySlotsLvl
	else
		return data.vaultSlotsLvl
	end
end

local function setLevel(data: DataManager.PlayerData, which: string, value: number)
	if which == "grill" then
		data.grillLvl = value
	elseif which == "display" then
		data.displaySlotsLvl = value
	elseif which == "vault" then
		data.vaultSlotsLvl = value
	end
end

-- Validate + charge + apply one upgrade step for `which` ("grill"/"display"/"vault").
-- Public so both the BuyUpgrade remote (menu) and the walk-on upgrade pads (via Main's
-- pad handler) drive the exact same server-authoritative path. Returns true on a
-- successful purchase (the pad handler pops a celebration on it).
function UpgradeService.tryBuy(player: Player, which: string): boolean
	local data = DataManager.get(player)
	local levels = levelsFor(which)
	if not (data and levels) then
		return false
	end

	local nextLvl = getLevel(data, which) + 1
	local nextDef = levels[nextLvl]
	if not nextDef then
		feedback(player, false, "That's already maxed out!")
		return false
	end
	if data.coins < nextDef.cost then
		feedback(player, false, "Not enough coins — need " .. nextDef.cost .. ".")
		return false
	end

	data.coins -= nextDef.cost
	setLevel(data, which, nextLvl)
	updateLeaderstats(player)
	pushProgression(player)

	if which == "grill" then
		pushCookStats(player) -- refresh disclosed odds + pity display
		feedback(player, true, "🔥 Grill upgraded to level " .. nextLvl .. "!")
	elseif which == "display" then
		PlotManager.syncDisplay(player)
		feedback(player, true, "🅿️ Display slots upgraded to level " .. nextLvl .. "!")
	else
		PlotManager.syncDisplay(player)
		feedback(player, true, "🔒 Vault slots upgraded to level " .. nextLvl .. "!")
	end
	return true
end

function UpgradeService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	pushCookStats: (player: Player) -> (),
	pushProgression: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	pushCookStats = deps.pushCookStats
	pushProgression = deps.pushProgression
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuyUpgrade = deps.remotes:WaitForChild("BuyUpgrade") :: RemoteEvent

	remBuyUpgrade.OnServerEvent:Connect(function(player, which)
		if not RateLimit.check(player, "BuyUpgrade", 5) then
			return
		end
		if type(which) == "string" and #which <= 32 then
			UpgradeService.tryBuy(player, which)
		end
	end)
end

return UpgradeService
