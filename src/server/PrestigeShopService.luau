--!strict
-- Prestige spending (M3 remainder, GDD §4.3). The first sink for the `prestige`
-- currency that rebirths (and the dex reward) bank but nothing spends today. Server
-- owns a catalog of permanent premium unlocks (income %, extra slots, mutation luck)
-- bought with prestige — NEVER Robux. Unlocks are ONE-TIME each (tracked in
-- data.prestigeUnlocks); the persistent effects they bank feed the income loop
-- (prestigeIncomeMult), the pedestal/vault capacity (bonus*Slots), and the mutation
-- roll (mutationLuck). Untrusted client only requests; the server validates prestige
-- balance + charges. Mirrors ShopService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local PrestigeShopService = {}

-- Resolved in init(); held as locals so no statement starts with `(`.
local updateLeaderstats: (player: Player) -> ()
local pushProgression: (player: Player) -> ()
local remFeedback: RemoteEvent
local remBuyPrestige: RemoteEvent
local remPrestigeShopUpdate: RemoteEvent

-- Send the catalog + the player's current prestige balance + which unlocks they
-- already own (so the client greys out bought rows). Handshake: also called from
-- Main.pushAllState.
function PrestigeShopService.pushShop(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remPrestigeShopUpdate:FireClient(
		player,
		GameConfig.PrestigeShopItems,
		data.prestige,
		data.prestigeUnlocks
	)
end

local function onBuy(player: Player, id: string)
	local data = DataManager.get(player)
	if not data then
		return
	end

	-- Authoritative catalog lookup.
	local item
	for _, it in GameConfig.PrestigeShopItems do
		if it.id == id then
			item = it
			break
		end
	end
	if not item then
		return
	end

	-- One-time unlocks: can't re-buy.
	if data.prestigeUnlocks[id] then
		remFeedback:FireClient(player, false, "You already own that unlock.")
		return
	end
	if data.prestige < item.cost then
		remFeedback:FireClient(
			player,
			false,
			"Not enough prestige — need " .. item.cost .. " ✨."
		)
		return
	end

	-- Charge, mark owned, then apply the persistent effect.
	data.prestige -= item.cost
	data.prestigeUnlocks[id] = true
	if item.effect == "incomeMult" then
		data.prestigeIncomeMult += item.amount
	elseif item.effect == "bonusDisplay" then
		data.bonusDisplaySlots += item.amount
		PlotManager.syncDisplay(player)
	elseif item.effect == "bonusVault" then
		data.bonusVaultSlots += item.amount
		PlotManager.syncDisplay(player)
	elseif item.effect == "mutationLuck" then
		data.mutationLuck += item.amount
	end

	updateLeaderstats(player)
	pushProgression(player)
	PrestigeShopService.pushShop(player)
	remFeedback:FireClient(player, true, "✨ Unlocked " .. item.label .. "!")
end

function PrestigeShopService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	pushProgression: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	pushProgression = deps.pushProgression
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
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
