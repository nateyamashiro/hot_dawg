--!strict
-- Monetization (M5, GDD §4.10). All non-pay-to-win — NEVER paid gacha (cook stays
-- coin-only per Roblox's paid-random-item rules; see docs/roblox-reference/
-- monetization). First passes: EXTRA SLOTS + VIP; later 2× coins + auto-collect.
-- Dev products (coin packs, offline refill, extra steal charges) go through
-- ProcessReceipt, made idempotent via data.receiptHistory so a re-processed receipt
-- can't double-grant. Mirrors UpgradeService's grant flow + DataManager persistence.

local MarketplaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")

-- GameConfig (GamePassIds / DevProductIds / ProductGrants) gets required when the
-- purchase logic lands — see the TODOs below.
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local PurchaseService = {}

local updateLeaderstats: (player: Player) -> ()
local remPromptPurchase: RemoteEvent
local remPurchaseUpdate: RemoteEvent

-- Refresh (and cache) which passes the player owns, then push status to the client.
-- TODO(M5-mon): call MarketplaceService:UserOwnsGamePassAsync for each GamePassIds
-- entry (pcall), set data.vip / data.bonus*Slots for extra-slots, and drive the 2×
-- coins / auto-collect effects from the cached flags. Also from Main.pushAllState.
function PurchaseService.pushStatus(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remPurchaseUpdate:FireClient(player, {
		vip = data.vip,
		bonusDisplaySlots = data.bonusDisplaySlots,
		bonusVaultSlots = data.bonusVaultSlots,
	})
end

-- Idempotent dev-product handler. Returns a ProductPurchaseDecision.
local function processReceipt(info: { PlayerId: number, PurchaseId: string, ProductId: number })
	local player = game:GetService("Players"):GetPlayerByUserId(info.PlayerId)
	if not player then
		-- Player left; let Roblox retry later so we can grant on their next session.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataManager.get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if data.receiptHistory[info.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted
	end
	-- TODO(M5-mon): map info.ProductId (GameConfig.DevProductIds) → grant coins /
	-- steal charges / offline refill via GameConfig.ProductGrants, then persist.
	data.receiptHistory[info.PurchaseId] = true
	updateLeaderstats(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function PurchaseService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remPromptPurchase = deps.remotes:WaitForChild("PromptPurchase") :: RemoteEvent
	remPurchaseUpdate = deps.remotes:WaitForChild("PurchaseUpdate") :: RemoteEvent

	MarketplaceService.ProcessReceipt = processReceipt

	-- Client asks the server to prompt a purchase (kind = pass/product key).
	remPromptPurchase.OnServerEvent:Connect(function(player, kind)
		if not RateLimit.check(player, "PromptPurchase", 5) then
			return
		end
		if type(kind) ~= "string" then
			return
		end
		-- TODO(M5-mon): look up the asset id in GameConfig.GamePassIds / DevProductIds
		-- and call MarketplaceService:PromptGamePassPurchase / PromptProductPurchase.
	end)
end

return PurchaseService
