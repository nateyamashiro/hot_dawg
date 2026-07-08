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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GlizzyModel = require(ReplicatedStorage.Shared.GlizzyModel)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local Theme = require(ReplicatedStorage.Shared.Theme)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)

local ConveyorService = {}

-- Belt geometry: a straight run down the street's centre line (world z = 0).
local BELT_START_X = -200
local BELT_END_X = 200
local BELT_Y = 2.4 -- ride height (dog centre) above the road
local BELT_SPEED = 10 -- studs/sec → ~40s on the belt per dog

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

-- Roll a belt offer from the shop's flatter weights (surfaces mid-tier dogs;
-- Legendary+ riding past is a "lucky belt" moment).
local RARITY_ORDER: { HotDogDex.Rarity } =
	{ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
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
		remFeedback:FireClient(buyer, false, "Need " .. unit.price .. " coins for that glizzy!")
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

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(170, 52)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 90
	billboard.Parent = primary
	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.fromScale(1, 1)
	tag.BackgroundTransparency = 1
	tag.TextColor3 = HotDogDex.colorFor(dog.rarity)
	tag.TextStrokeTransparency = 0.4
	tag.TextScaled = true
	tag.Font = Enum.Font.GothamBold
	tag.Text = dog.name .. "\n💰" .. price
	tag.Parent = billboard

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
	prompt.ActionText = "Buy 💰" .. price
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
