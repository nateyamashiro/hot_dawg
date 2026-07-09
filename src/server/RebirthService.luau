--!strict
-- Rebirth / prestige loop (item 6, GDD §4.3). Rebirthing resets coins to the
-- starting amount, KEEPS the whole hot-dog collection and upgrade levels, bumps a
-- permanent income multiplier (applied in Main's income loop), and banks prestige
-- currency for future premium unlocks. Cost grows geometrically per rebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local RebirthService = {}

local updateLeaderstats: (player: Player) -> ()
local pushProgression: (player: Player) -> ()
local remFeedback: RemoteEvent
local remRebirth: RemoteEvent

-- Coin cost of a player's NEXT rebirth (exposed so the client can display it too,
-- though the client also computes it from config for the button label).
function RebirthService.costFor(rebirths: number): number
	return math.floor(GameConfig.RebirthBaseCost * GameConfig.RebirthCostGrowth ^ rebirths)
end

local function onRebirth(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end

	local cost = RebirthService.costFor(data.rebirths)
	if data.coins < cost then
		remFeedback:FireClient(player, false, "Need " .. cost .. " coins to rebirth.")
		return
	end

	-- Reset coins; keep dogs + upgrades; advance rebirth + prestige.
	data.coins = GameConfig.StartingCoins
	data.rebirths += 1
	data.prestige += GameConfig.RebirthPrestigeReward

	updateLeaderstats(player)
	pushProgression(player)

	local pct = math.floor(data.rebirths * GameConfig.RebirthIncomeBonus * 100)
	remFeedback:FireClient(
		player,
		true,
		"✨ Rebirth " .. data.rebirths .. "! Income now +" .. pct .. "%."
	)
end

function RebirthService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	pushProgression: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	pushProgression = deps.pushProgression
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remRebirth = deps.remotes:WaitForChild("Rebirth") :: RemoteEvent

	remRebirth.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "Rebirth", 2) then
			return
		end
		onRebirth(player)
	end)
end

return RebirthService
