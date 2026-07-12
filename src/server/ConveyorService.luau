--!strict
-- Conveyor purchase lane (Phase 4 — SHIPPED). Steal-a-Brainrot's signature street
-- mechanic: glizzies ride a belt down the central aisle; walk up and buy one with a
-- quick ProximityPrompt (a prompt, not raw Touch, so nobody accidentally spends coins
-- crossing the street). Offers are rolled from the SHOP's flatter rarity weights +
-- prices (ShopRarityWeights/ShopRarityPrices — the "pay for certainty" economy lane;
-- belt buys grant the base dog, no mutation mint, exactly like shop buys).
-- Server owns the belt objects, movement, and the buy transaction; there is nothing
-- for the client to request, so this service has no client→server remotes.
--
-- Perf: ≤ ConveyorMaxOnBelt (8) anchored models pivoted per Heartbeat — the one
-- deliberate exception to "no per-frame server work" (bounded + tiny).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GlizzyModel = require(ReplicatedStorage.Shared.GlizzyModel)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local Theme = require(ReplicatedStorage.Shared.Theme)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)

local ConveyorService = {}

-- Belt geometry: a straight run down the street's centre line (world z = 0).
-- Additions #11: the belt now spans (almost) the FULL street (±620) — every plot
-- is steps from an offer. Speed + the GameConfig cap/interval scaled with length
-- so the longer lane doesn't ride empty.
local BELT_START_X = -560
local BELT_END_X = 560
local BELT_Y = 2.4 -- ride height (dog centre) above the road
local BELT_SPEED = 14 -- studs/sec → ~80s on the belt per dog

local updateLeaderstats: (player: Player) -> ()
local onInventoryChanged: (player: Player) -> ()
local remFeedback: RemoteEvent
local remCelebrate: RemoteEvent

type BeltUnit = {
	model: Model,
	primary: BasePart,
	name: string,
	rarity: HotDogDex.Rarity,
	price: number,
	x: number,
	sold: boolean,
}

local active: { BeltUnit } = {}
-- Per-player buy debounce (prompt double-fires are cheap to swallow here).
local nextBuyAllowed: { [number]: number } = {}
Players.PlayerRemoving:Connect(function(player)
	nextBuyAllowed[player.UserId] = nil
end)

-- Roll a belt offer from the shop's flatter weights (surfaces mid-tier dogs;
-- Legendary+ riding past is a "lucky belt" moment).
local RARITY_ORDER: { HotDogDex.Rarity } =
	{ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Forbidden" }
local function pickOffer(): (HotDogDex.HotDog?, number)
	local weights = GameConfig.ShopRarityWeights :: { [string]: number }
	local prices = GameConfig.ShopRarityPrices :: { [string]: number }
	local total = 0
	for _, rarity in RARITY_ORDER do
		total += weights[rarity] or 0
	end
	if total <= 0 then
		return nil, 0
	end
	local pick = math.random() * total
	for _, rarity in RARITY_ORDER do
		pick -= weights[rarity] or 0
		if pick <= 0 then
			return HotDogDex.randomOfRarity(rarity), prices[rarity] or 100
		end
	end
	return nil, 0
end

local function onBuy(buyer: Player, unit: BeltUnit)
	if unit.sold then
		return
	end
	local now = os.clock()
	if now < (nextBuyAllowed[buyer.UserId] or 0) then
		return
	end
	nextBuyAllowed[buyer.UserId] = now + 0.3
	local data = DataManager.get(buyer)
	if not data then
		return
	end
	if data.coins < unit.price then
		remFeedback:FireClient(
			buyer,
			false,
			"Need " .. Format.comma(unit.price) .. " coins for that glizzy!"
		)
		return
	end

	unit.sold = true
	data.coins -= unit.price
	-- Base dog, plain key — belt buys mirror shop buys (no mutation mint; cook is
	-- the only mutation source, GDD §4.4).
	data.hotDogs[unit.name] = (data.hotDogs[unit.name] or 0) + 1
	updateLeaderstats(buyer)
	PlotManager.syncDisplay(buyer)
	onInventoryChanged(buyer)
	remFeedback:FireClient(buyer, true, "🌭 Bought a " .. unit.name .. " off the belt!")
	-- Rarity-colored burst where the dog stood (Vector3 target → client anchors it).
	remCelebrate:FireAllClients("cook", unit.primary.Position, unit.rarity)

	local index = table.find(active, unit)
	if index then
		table.remove(active, index)
	end
	unit.model:Destroy()
end

local function spawnUnit()
	local dog, price = pickOffer()
	if not dog then
		return
	end
	local model = GlizzyModel.build(dog.name, {
		rarity = dog.rarity,
		anchored = true,
		fx = false, -- belt merch stays clean; the pedestal aura budget isn't for ads
	})
	-- NOT "DogUnit": steal prompts, GlizzyFx tracking, and clearUnits must all
	-- ignore belt merchandise.
	model.Name = "BeltDog"
	local primary = model.PrimaryPart :: BasePart

	-- Genre-standard belt tag (Steal a Brainrot's conveyor shows rarity, cost, AND
	-- earning rate): three compact stacked lines, occludable, near-fading.
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(104, 46)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.3, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 70
	billboard.Parent = primary
	local function tagLine(text: string, color: Color3, y: number, h: number, font: Enum.Font)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, h)
		l.Position = UDim2.fromScale(0, y)
		l.BackgroundTransparency = 1
		l.TextColor3 = color
		l.TextStrokeTransparency = 0
		l.TextScaled = true
		l.Font = font
		l.Text = text
		l.Parent = billboard
	end
	tagLine(dog.name, Color3.fromRGB(255, 255, 255), 0, 0.42, Theme.UI.TitleFont)
	tagLine(dog.rarity, HotDogDex.colorFor(dog.rarity), 0.42, 0.3, Theme.UI.TitleFont)
	tagLine(
		"💰" .. Format.comma(price) .. " · +" .. Format.comma(dog.income) .. "/s",
		Color3.fromRGB(170, 255, 170),
		0.72,
		0.28,
		Theme.UI.NumberFont
	)

	local unit: BeltUnit = {
		model = model,
		primary = primary,
		name = dog.name,
		rarity = dog.rarity,
		price = price,
		x = BELT_START_X,
		sold = false,
	}

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy 💰" .. Format.comma(price)
	prompt.ObjectText = dog.name
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = primary
	prompt.Triggered:Connect(function(buyer: Player)
		onBuy(buyer, unit)
	end)

	model:PivotTo(CFrame.new(BELT_START_X, BELT_Y, 0))
	model.Parent = Workspace:FindFirstChild("ConveyorLane") or Workspace
	table.insert(active, unit)
end

-- The physical belt strip down the street centre (visual only — CanCollide false so
-- chases across the road never snag).
local function buildBelt(): Model
	local lane = Instance.new("Model")
	lane.Name = "ConveyorLane"
	local strip = Instance.new("Part")
	strip.Name = "BeltStrip"
	strip.Anchored = true
	strip.CanCollide = false
	strip.Material = Enum.Material.SmoothPlastic
	strip.Color = Theme.Palette.Steel
	strip.Size = Vector3.new(BELT_END_X - BELT_START_X + 10, 0.4, 7)
	strip.CFrame = CFrame.new(0, 0.6, 0)
	strip.Parent = lane
	for _, side in { -1, 1 } do
		local rail = Instance.new("Part")
		rail.Name = "BeltRail"
		rail.Anchored = true
		rail.CanCollide = false
		rail.CastShadow = false
		rail.Material = Enum.Material.SmoothPlastic
		rail.Color = Theme.Palette.MustardDark
		rail.Size = Vector3.new(BELT_END_X - BELT_START_X + 10, 0.3, 0.5)
		rail.CFrame = CFrame.new(0, 0.75, side * 3.5)
		rail.Parent = lane
	end
	lane.Parent = Workspace
	return lane
end

function ConveyorService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	onInventoryChanged: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	onInventoryChanged = deps.onInventoryChanged
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remCelebrate = deps.remotes:WaitForChild("Celebrate") :: RemoteEvent

	buildBelt()

	-- Movement: ride + a slow merch spin; despawn unsold dogs at the end of the run.
	RunService.Heartbeat:Connect(function(dt: number)
		local spin = os.clock() * 1.2 % (2 * math.pi)
		for i = #active, 1, -1 do
			local unit = active[i]
			unit.x += BELT_SPEED * dt
			if unit.x > BELT_END_X then
				table.remove(active, i)
				unit.model:Destroy()
			else
				unit.model:PivotTo(CFrame.new(unit.x, BELT_Y, 0) * CFrame.Angles(0, spin, 0))
			end
		end
	end)

	-- Spawner: keep the belt stocked up to the cap.
	task.spawn(function()
		while true do
			task.wait(GameConfig.ConveyorSpawnInterval)
			if #active < GameConfig.ConveyorMaxOnBelt then
				spawnUnit()
			end
		end
	end)
end

return ConveyorService
