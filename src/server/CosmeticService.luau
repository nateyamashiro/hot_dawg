--!strict
-- Cosmetics (M5, GDD §4.10). Stand skins, trails/auras, and titles — bought with
-- prestige (or Robux via PurchaseService), never affecting power (non-pay-to-win).
-- Server owns the catalog, persists owned/equipped in data.cosmetics, and applies
-- the visuals (stand skin, carry trail, name title). Untrusted client only requests
-- buy/equip. Mirrors ShopService (catalog/buy) + PlotPresentation (visual apply).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local CosmeticService = {}

local remBuyCosmetic: RemoteEvent
local remEquipCosmetic: RemoteEvent
local remCosmeticUpdate: RemoteEvent

function CosmeticService.pushCosmetics(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remCosmeticUpdate:FireClient(player, GameConfig.Cosmetics, data.cosmetics)
end

local function onBuy(player: Player, id: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	-- TODO(M5-cosmetics): find the cosmetic by id; charge prestige (or verify a Robux
	-- purchase), set data.cosmetics.owned[id] = true, then re-push.
	local _ = id
	CosmeticService.pushCosmetics(player)
end

local function onEquip(player: Player, id: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	-- TODO(M5-cosmetics): if owned, set data.cosmetics.equipped = id and apply the
	-- visual (PlotManager stand skin / carry trail / title billboard). "" = unequip.
	local _ = id
	CosmeticService.pushCosmetics(player)
end

function CosmeticService.init(deps: { remotes: Folder })
	remBuyCosmetic = deps.remotes:WaitForChild("BuyCosmetic") :: RemoteEvent
	remEquipCosmetic = deps.remotes:WaitForChild("EquipCosmetic") :: RemoteEvent
	remCosmeticUpdate = deps.remotes:WaitForChild("CosmeticUpdate") :: RemoteEvent

	remBuyCosmetic.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "BuyCosmetic", 5) then
			return
		end
		if type(id) == "string" then
			onBuy(player, id)
		end
	end)

	remEquipCosmetic.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "EquipCosmetic", 10) then
			return
		end
		if type(id) == "string" then
			onEquip(player, id)
		end
	end)
end

return CosmeticService
