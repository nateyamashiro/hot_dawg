--!strict
-- Monetization (M5, GDD §4.10). All non-pay-to-win — NEVER paid gacha (cook stays
-- coin-only per Roblox's paid-random-item rules; see docs/roblox-reference/
-- monetization). Live passes: EXTRA SLOTS, VIP, and 2× COINS (multiplicative in
-- Main.incomeMultiplier); auto-collect is detected but its effect awaits Nate's
-- design call (income is already automatic). Ids live in GameConfig.GamePassIds/
-- DevProductIds — 0 = unconfigured, so everything here is id-agnostic: prompts
-- toast "not available yet" and Studio can flip GameConfig.StudioTestPasses to
-- exercise the pass EFFECTS without real ids.
--
-- Ownership model (refund-safe): data.passes[kind] is the last-known
-- UserOwnsGamePassAsync answer (refreshed on join + on purchase, kept on API
-- failure). Effects DERIVE from it at read time — PlotManager capacity, Main's
-- incomeMultiplier — never banked into bonus*Slots, so refunds can't leave
-- phantom slots and re-checks can't double-grant.
--
-- Dev products (coin packs, extra steal charges, offline refill) go through
-- ProcessReceipt, made idempotent via data.receiptHistory. UNMAPPED products
-- return NotProcessedYet so Roblox retries or refunds — never consume a receipt
-- you didn't grant. offlineRefill (M5, 2026-07-12) pays out the cap-truncated
-- offline seconds banked in data.offlineMissedSeconds at the buyer's live rate.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)
local StealService = require(ServerScriptService.Server.StealService)
local Telemetry = require(ServerScriptService.Server.Telemetry)

local PurchaseService = {}

-- Dynamic-key views of the id tables (their literal types have named fields).
local PASS_IDS = GameConfig.GamePassIds :: { [string]: number }
local PRODUCT_IDS = GameConfig.DevProductIds :: { [string]: number }
local PRODUCT_GRANTS = GameConfig.ProductGrants :: { [string]: number }
local STUDIO_PASSES = GameConfig.StudioTestPasses :: { [string]: boolean }

local updateLeaderstats: (player: Player) -> ()
-- Main's live coins/sec closure ((dogs + stove) × full multiplier) — the
-- offlineRefill grant pays banked seconds out at this rate.
local computeIncome: (player: Player) -> number
local remPromptPurchase: RemoteEvent
local remPurchaseUpdate: RemoteEvent
local remFeedback: RemoteEvent
local remCelebrate: RemoteEvent

local function feedback(player: Player, ok: boolean, message: string)
	remFeedback:FireClient(player, ok, message)
end

-- Push the cached ownership snapshot (non-yielding — safe inside pushAllState).
function PurchaseService.pushStatus(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remPurchaseUpdate:FireClient(player, {
		vip = data.vip,
		passes = data.passes,
		bonusDisplaySlots = data.bonusDisplaySlots,
		bonusVaultSlots = data.bonusVaultSlots,
	})
end

-- Re-check pass ownership against Marketplace (YIELDS — call from a spawned
-- thread, never inline in a push path). id == 0 in Studio falls back to the
-- StudioTestPasses override; a pcall failure keeps the last persisted answer.
local function refreshOwnership(player: Player): boolean
	local data = DataManager.get(player)
	if not data then
		return false
	end
	local changed = false
	for kind, id in PASS_IDS do
		local owns: boolean? = nil
		if id ~= 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			if ok then
				owns = result == true
			end
		elseif RunService:IsStudio() then
			owns = STUDIO_PASSES[kind] == true
		end
		if owns ~= nil and data.passes[kind] ~= owns then
			data.passes[kind] = owns
			changed = true
		end
	end
	data.vip = data.passes.vip == true
	return changed
end

-- Join hook (Main task.spawns this): refresh ownership, then re-push status and
-- re-render the stand if pass slots appeared/disappeared since last session.
function PurchaseService.onJoin(player: Player)
	if refreshOwnership(player) and player.Parent then
		PlotManager.syncDisplay(player)
		PurchaseService.pushStatus(player)
	end
end

-- A pass purchase completed in-game: bank ownership + apply effects immediately.
local function onPassPurchased(player: Player, kind: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	data.passes[kind] = true
	data.vip = data.passes.vip == true
	PlotManager.syncDisplay(player) -- extra-slots: new pedestals fill right away
	updateLeaderstats(player)
	PurchaseService.pushStatus(player)
	Telemetry.event(player, "PassBought_" .. kind)
	feedback(player, true, "💎 Pass unlocked — thank you!")
	local signPost = PlotManager.signPostOf(player)
	if signPost then
		remCelebrate:FireAllClients("purchase", signPost)
	end
end

-- Idempotent dev-product handler. Returns a ProductPurchaseDecision.
local function processReceipt(info: { PlayerId: number, PurchaseId: string, ProductId: number })
	local player = Players:GetPlayerByUserId(info.PlayerId)
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

	local productKind: string? = nil
	for kind, id in PRODUCT_IDS do
		if id ~= 0 and id == info.ProductId then
			productKind = kind
			break
		end
	end

	-- Grant FIRST, mark the receipt, THEN PurchaseGranted. Anything unmapped
	-- (unknown ids, offlineRefill until its bespoke logic lands) grants nothing —
	-- so do NOT consume the receipt: NotProcessedYet makes Roblox retry (and
	-- auto-refund if it never processes). Returning PurchaseGranted without a
	-- grant would eat a player's real Robux.
	if productKind == "coinsSmall" or productKind == "coinsLarge" then
		data.coins += PRODUCT_GRANTS[productKind]
		updateLeaderstats(player)
		feedback(player, true, "💰 +" .. PRODUCT_GRANTS[productKind] .. " coins — thank you!")
	elseif productKind == "stealCharges" then
		-- May exceed MaxStealCharges on purpose: the recharge loop only tops up
		-- below the cap, so bought charges are never wasted, just spent down.
		data.stealCharges += GameConfig.ProductGrants.stealCharges
		StealService.pushStats(player)
		feedback(
			player,
			true,
			"⚡ +" .. GameConfig.ProductGrants.stealCharges .. " steal charges!"
		)
	elseif productKind == "offlineRefill" then
		-- Bespoke grant (M5): pay out the offline time the cap truncated — banked at
		-- join in data.offlineMissedSeconds — at the buyer's LIVE income rate. With
		-- nothing banked (bought in a race), don't consume the receipt: Roblox
		-- retries next session and auto-refunds if it never grants.
		local seconds = data.offlineMissedSeconds
		local earned = math.floor(computeIncome(player) * seconds)
		if seconds <= 0 or earned <= 0 then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		data.coins += earned
		data.offlineMissedSeconds = 0
		updateLeaderstats(player)
		feedback(
			player,
			true,
			"⏰ Offline refill: +" .. Format.comma(earned) .. " coins — thank you!"
		)
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.receiptHistory[info.PurchaseId] = true
	Telemetry.event(player, "ProductBought_" .. productKind)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function PurchaseService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	computeIncome: (player: Player) -> number,
})
	updateLeaderstats = deps.updateLeaderstats
	computeIncome = deps.computeIncome
	remPromptPurchase = deps.remotes:WaitForChild("PromptPurchase") :: RemoteEvent
	remPurchaseUpdate = deps.remotes:WaitForChild("PurchaseUpdate") :: RemoteEvent
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remCelebrate = deps.remotes:WaitForChild("Celebrate") :: RemoteEvent

	MarketplaceService.ProcessReceipt = processReceipt

	-- Server-side confirmation of a pass bought through our prompt (grant-on-the-
	-- spot; the on-join UserOwnsGamePassAsync re-check covers external purchases).
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, passId: number, purchased: boolean)
			if not purchased then
				return
			end
			for kind, id in PASS_IDS do
				if id ~= 0 and id == passId then
					onPassPurchased(player, kind)
					return
				end
			end
		end
	)

	-- Client asks the server to prompt a purchase (kind = pass/product key).
	remPromptPurchase.OnServerEvent:Connect(function(player, kind)
		if not RateLimit.check(player, "PromptPurchase", 5) then
			return
		end
		if type(kind) ~= "string" or #kind > 32 then
			return
		end
		local passId = PASS_IDS[kind]
		local productId = PRODUCT_IDS[kind]
		if passId and passId ~= 0 then
			local data = DataManager.get(player)
			if data and data.passes[kind] then
				feedback(player, false, "You already own that pass!")
				return
			end
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, passId)
			end)
		elseif productId and productId ~= 0 then
			-- offlineRefill only makes sense with banked cap-truncated time; block
			-- the prompt up front so nobody buys an empty refill.
			if kind == "offlineRefill" then
				local data = DataManager.get(player)
				if not data or data.offlineMissedSeconds <= 0 then
					feedback(player, false, "Nothing to refill — you're all caught up!")
					return
				end
			end
			pcall(function()
				MarketplaceService:PromptProductPurchase(player, productId)
			end)
		else
			feedback(player, false, "Not available yet — check back soon!")
		end
	end)
end

return PurchaseService
