--!strict
-- Rotating shop (M3 remainder, GDD §4.3/§6). A daily set of SPECIFIC hot dogs the
-- player can buy directly with coins — a targeted goal that dampens pure-cook RNG.
-- The offer set is a DETERMINISTIC function of the UTC day index, so every player
-- and every server sees the same shop that day (fair + shareable). Buying just adds
-- the dog to the master inventory (no new persisted fields); the server validates the
-- dog is actually in today's shop and charges coins. Untrusted client only requests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)
local PlotManager = require(ServerScriptService.Server.PlotManager)

local ShopService = {}

-- One purchasable shop entry sent to the client.
export type Offer = {
	name: string,
	rarity: HotDogDex.Rarity,
	income: number,
	price: number,
}

local updateLeaderstats: (player: Player) -> ()
local onInventoryChanged: (player: Player) -> ()
-- Resolved in init(); held as locals so no statement starts with `(`.
local remFeedback: RemoteEvent
local remBuyFromShop: RemoteEvent
local remShopUpdate: RemoteEvent

-- Current rotation index (UTC-day based). Deterministic + timezone-stable.
local function currentDay(): number
	return math.floor(os.time() / GameConfig.ShopRefreshSeconds)
end

-- The coin price for a rarity (0 if somehow unconfigured — treated as un-buyable).
local function priceFor(rarity: HotDogDex.Rarity): number
	return GameConfig.ShopRarityPrices[rarity] or 0
end

-- Build the deterministic offer set for a rotation `day`. Draws ShopSlotCount
-- DISTINCT dogs from the full roster, weighted by ShopRarityWeights, using a
-- day-seeded RNG so the result is identical everywhere for that day.
local function offersFor(day: number): { Offer }
	local rng = Random.new(day)
	-- all() builds a fresh array each call, so it's safe to remove picked dogs.
	local pool = HotDogDex.all()
	local offers: { Offer } = {}
	local count = math.min(GameConfig.ShopSlotCount, #pool)

	for _ = 1, count do
		local total = 0
		for _, dog in pool do
			total += GameConfig.ShopRarityWeights[dog.rarity] or 0
		end
		if total <= 0 then
			break
		end
		local pick = rng:NextNumber() * total
		for idx, dog in pool do
			pick -= GameConfig.ShopRarityWeights[dog.rarity] or 0
			if pick <= 0 then
				table.insert(offers, {
					name = dog.name,
					rarity = dog.rarity,
					income = dog.income,
					price = priceFor(dog.rarity),
				})
				table.remove(pool, idx)
				break
			end
		end
	end

	return offers
end

-- Send a player today's offers + seconds until the next rotation (for a countdown).
function ShopService.pushShop(player: Player)
	local secondsLeft = GameConfig.ShopRefreshSeconds - (os.time() % GameConfig.ShopRefreshSeconds)
	remShopUpdate:FireClient(player, offersFor(currentDay()), secondsLeft)
end

local function onBuy(player: Player, name: string)
	local data = DataManager.get(player)
	if not data then
		return
	end

	-- Authoritative check: the dog must actually be in TODAY'S shop.
	local offer: Offer?
	for _, o in offersFor(currentDay()) do
		if o.name == name then
			offer = o
			break
		end
	end
	if not offer then
		remFeedback:FireClient(player, false, "That's not in today's shop anymore.")
		return
	end
	if data.coins < offer.price then
		remFeedback:FireClient(player, false, "Not enough coins — need " .. offer.price .. ".")
		return
	end

	data.coins -= offer.price
	data.hotDogs[name] = (data.hotDogs[name] or 0) + 1
	updateLeaderstats(player)
	PlotManager.syncDisplay(player)
	onInventoryChanged(player) -- dex snapshot + one-time completion reward
	remFeedback:FireClient(
		player,
		true,
		"🛒 Bought " .. name .. " for " .. offer.price .. " coins!"
	)
end

function ShopService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	onInventoryChanged: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	onInventoryChanged = deps.onInventoryChanged
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuyFromShop = deps.remotes:WaitForChild("BuyFromShop") :: RemoteEvent
	remShopUpdate = deps.remotes:WaitForChild("ShopUpdate") :: RemoteEvent

	remBuyFromShop.OnServerEvent:Connect(function(player, name)
		if not RateLimit.check(player, "BuyFromShop", 5) then
			return
		end
		if type(name) == "string" and #name <= 64 then
			onBuy(player, name)
		end
	end)

	-- Re-push the shop to everyone when the rotation rolls over so an in-session
	-- player sees the fresh set without rejoining.
	task.spawn(function()
		local lastDay = currentDay()
		while true do
			task.wait(30)
			local day = currentDay()
			if day ~= lastDay then
				lastDay = day
				for _, player in Players:GetPlayers() do
					ShopService.pushShop(player)
				end
			end
		end
	end)
end

return ShopService
