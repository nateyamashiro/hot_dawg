--!strict
-- Prestige spending (M3 remainder, GDD §4.3). The first sink for the `prestige`
-- currency that rebirths bank but nothing spends today. Server owns a catalog of
-- permanent premium unlocks (income %, extra slots, mutation luck, exclusive
-- cosmetics) bought with prestige — NEVER Robux. Untrusted client only requests;
-- the server validates prestige balance + charges. Mirrors ShopService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local PrestigeShopService = {}

-- Resolved in init(); held as locals so no statement starts with `(`.
local updateLeaderstats: (player: Player) -> ()
local pushProgression: (player: Player) -> ()
local remBuyPrestige: RemoteEvent
local remPrestigeShopUpdate: RemoteEvent

-- Send the catalog + the player's current prestige balance (handshake: also called
-- from Main.pushAllState).
function PrestigeShopService.pushShop(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remPrestigeShopUpdate:FireClient(player, GameConfig.PrestigeShopItems, data.prestige)
end

local function onBuy(player: Player, id: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	-- TODO(M3-prestige): find the item by id, verify data.prestige >= item.cost,
	-- deduct prestige, apply item.effect (incomeMult -> a permanent multiplier field;
	-- bonusDisplay/bonusVault -> data.bonus*Slots + PlotManager.syncDisplay;
	-- mutationLuck -> a stored luck bonus; cosmetic -> grant into data.cosmetics),
	-- then updateLeaderstats + pushProgression + re-push the shop.
	local _ = id
	updateLeaderstats(player)
	pushProgression(player)
	PrestigeShopService.pushShop(player)
end

function PrestigeShopService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	pushProgression: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	pushProgression = deps.pushProgression
	remBuyPrestige = deps.remotes:WaitForChild("BuyPrestige") :: RemoteEvent
	remPrestigeShopUpdate = deps.remotes:WaitForChild("PrestigeShopUpdate") :: RemoteEvent

	remBuyPrestige.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "BuyPrestige", 5) then
			return
		end
		if type(id) == "string" then
			onBuy(player, id)
		end
	end)
end

return PrestigeShopService
