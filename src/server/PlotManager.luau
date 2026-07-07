--!strict
-- Owns every player's physical base (a "hot dog stand") and keeps the STEALABLE
-- display in sync with their inventory. Plots are code-generated blocky pads in a
-- ring on the baseplate (swap for AI-gen art later). This module owns the Roblox
-- instances (parts, pedestals, prompts); the RULES of stealing live in
-- StealService, which registers handlers here.
--
-- Vault vs. display split (GDD §4.1): a player's units are sorted high->low value;
-- the top `VaultSlots` sit on a safe back shelf (no prompt), and the overflow fills
-- the front pedestals as STEALABLE units (each gets a "Steal" ProximityPrompt).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local DataManager = require(ServerScriptService.Server.DataManager)

export type Plot = {
	index: number,
	model: Model,
	center: Vector3,
	facing: CFrame,
	signText: TextLabel,
	pedestalAnchors: { BasePart },
	vaultAnchors: { BasePart },
	depositPrompt: ProximityPrompt,
	owner: Player?,
	holdBonus: number,
	guardModel: Model?,
	wallModel: Model?,
}

local PlotManager = {}

local plots: { Plot } = {}
local ownerToPlot: { [number]: Plot } = {}

-- Handlers registered by StealService (dependency inversion: PlotManager owns the
-- prompts, StealService owns the rules).
type StealHandler = (thief: Player, victimUserId: number, dogName: string, unitPart: BasePart) -> ()
type DepositHandler = (thief: Player) -> ()
local stealHandler: StealHandler? = nil
local depositHandler: DepositHandler? = nil

function PlotManager.setStealHandler(fn: StealHandler)
	stealHandler = fn
end

function PlotManager.setDepositHandler(fn: DepositHandler)
	depositHandler = fn
end

-- === Small part-building helpers ===
local function makePart(props: { [string]: any }): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(part :: any)[k] = v
	end
	return part
end

local function makeBillboard(
	parent: BasePart,
	text: string,
	color: Color3,
	sizeY: number,
	name: string?
): TextLabel
	local bb = Instance.new("BillboardGui")
	if name then
		-- Stable name so the client can find + hide structural labels on rival stands.
		bb.Name = name
	end
	bb.Size = UDim2.fromOffset(180, sizeY)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = bb
	return label
end

-- === Build the world (called once at startup) ===
local function buildPlot(index: number): Plot
	-- Two parallel rows of stands facing a central street (like a food court).
	-- Rows alternate as index increases so both sides fill in as players join.
	local perRow = math.ceil(GameConfig.PlotCount / 2)
	local row = (index - 1) % 2 -- 0 = far side, 1 = near side
	local col = math.floor((index - 1) / 2)
	local x = (col - (perRow - 1) / 2) * GameConfig.PlotRowSpacing
	local halfStreet = GameConfig.PlotRowSeparation / 2
	local z = if row == 0 then halfStreet else -halfStreet
	local center = Vector3.new(x, 0.5, z)
	-- Each row faces the central aisle (a stand's front is its local +Z).
	local yaw = if row == 0 then math.pi else 0
	local facing = CFrame.new(center) * CFrame.Angles(0, yaw, 0)

	local model = Instance.new("Model")
	model.Name = "Plot" .. index

	-- Flat pad.
	local pad = makePart({
		Name = "Pad",
		Size = Vector3.new(26, 1, 20),
		Color = Color3.fromRGB(120, 90, 60),
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
		CFrame = facing * CFrame.new(0, 0, 0),
	})
	pad.Parent = model

	-- Sign with the owner name (billboard above a post).
	local signPost = makePart({
		Name = "SignPost",
		Size = Vector3.new(1, 8, 1),
		Color = Color3.fromRGB(90, 60, 40),
		CFrame = facing * CFrame.new(0, 4, -8),
	})
	signPost.Parent = model
	local signText = makeBillboard(signPost, "Empty Plot", Color3.fromRGB(255, 240, 200), 60)

	-- Front row: stealable pedestals. Build the MAXIMUM up front; syncDisplay only
	-- fills up to the owner's current DisplaySlots level (upgrades reveal more).
	local pedestalAnchors: { BasePart } = {}
	local slots = GameConfig.MaxDisplaySlots
	for i = 1, slots do
		local offsetX = (i - (slots + 1) / 2) * 2.6
		local anchor = makePart({
			Name = "Pedestal" .. i,
			Size = Vector3.new(2, 2, 2),
			Color = Color3.fromRGB(70, 70, 80),
			Material = Enum.Material.Metal,
			CanCollide = true,
			CFrame = facing * CFrame.new(offsetX, 1.5, 3),
		})
		anchor.Parent = model
		table.insert(pedestalAnchors, anchor)
	end

	-- Back shelf: safe vault slots (also built to the maximum; filled per level).
	local vaultAnchors: { BasePart } = {}
	local vaultSlots = GameConfig.MaxVaultSlots
	for i = 1, vaultSlots do
		local offsetX = (i - (vaultSlots + 1) / 2) * 2.8
		local anchor = makePart({
			Name = "Vault" .. i,
			Size = Vector3.new(2.2, 2.2, 2.2),
			Color = Color3.fromRGB(210, 180, 40),
			Material = Enum.Material.Metal,
			CanCollide = true,
			CFrame = facing * CFrame.new(offsetX, 1.6, -6),
		})
		anchor.Parent = model
		makeBillboard(anchor, "🔒 Vault", Color3.fromRGB(255, 230, 120), 40, "VaultLabel")
		table.insert(vaultAnchors, anchor)
	end

	-- Deposit pad (drop stolen dogs here to claim them).
	local depositPad = makePart({
		Name = "DepositPad",
		Size = Vector3.new(6, 0.6, 6),
		Color = Color3.fromRGB(60, 160, 90),
		Material = Enum.Material.Neon,
		CanCollide = true,
		CFrame = facing * CFrame.new(0, 0.6, 7),
	})
	depositPad.Parent = model
	makeBillboard(depositPad, "Deposit", Color3.fromRGB(180, 255, 200), 40, "DepositLabel")

	local depositPrompt = Instance.new("ProximityPrompt")
	depositPrompt.ActionText = "Deposit stolen dog"
	depositPrompt.ObjectText = "Your Stand"
	depositPrompt.HoldDuration = 0.5
	depositPrompt.MaxActivationDistance = 10
	depositPrompt.RequiresLineOfSight = false
	depositPrompt.Enabled = false
	depositPrompt.Parent = depositPad
	depositPrompt.Triggered:Connect(function(triggerer: Player)
		-- Only the plot's owner may deposit here (you carry loot back to YOUR stand).
		local ownPlot = ownerToPlot[triggerer.UserId]
		if depositHandler and ownPlot and ownPlot.depositPrompt == depositPrompt then
			depositHandler(triggerer)
		end
	end)

	model.Parent = workspace

	return {
		index = index,
		model = model,
		center = center,
		facing = facing,
		signText = signText,
		pedestalAnchors = pedestalAnchors,
		vaultAnchors = vaultAnchors,
		depositPrompt = depositPrompt,
		owner = nil,
		holdBonus = 0,
		guardModel = nil,
		wallModel = nil,
	}
end

function PlotManager.build()
	for i = 1, GameConfig.PlotCount do
		table.insert(plots, buildPlot(i))
	end
end

-- === Ownership ===
function PlotManager.getPlotByOwner(player: Player): Plot?
	return ownerToPlot[player.UserId]
end

function PlotManager.assign(player: Player): Plot?
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			ownerToPlot[player.UserId] = plot
			plot.signText.Text = player.DisplayName .. "'s Stand"
			-- Replicated so the client (PlotPresentation) can mark THIS stand as the
			-- local player's: highlight, "YOUR STAND" banner, hide own steal prompts.
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			PlotManager.syncDisplay(player)
			return plot
		end
	end
	warn("[PlotManager] No free plot for " .. player.Name)
	return nil
end

-- Clear the dog units currently sitting on a set of anchors.
local function clearUnits(anchors: { BasePart })
	for _, anchor in anchors do
		for _, child in anchor:GetChildren() do
			if child.Name == "DogUnit" then
				child:Destroy()
			end
		end
	end
end

-- Build a visible dog "unit" on top of an anchor. `stealable` controls whether it
-- gets a Steal prompt (front pedestals) or is safe (vault shelf).
local function spawnUnit(plot: Plot, anchor: BasePart, dog: HotDogDex.HotDog, stealable: boolean)
	local color = HotDogDex.colorFor(dog.rarity)
	local unit = makePart({
		Name = "DogUnit",
		Size = Vector3.new(1.6, 0.7, 3),
		Color = color,
		Material = Enum.Material.SmoothPlastic,
		CFrame = anchor.CFrame * CFrame.new(0, 1.5, 0),
	})
	unit:SetAttribute("DogName", dog.name)
	makeBillboard(unit, dog.name, color, 44)
	unit.Parent = anchor

	if stealable then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Steal"
		prompt.ObjectText = dog.name
		prompt.HoldDuration = GameConfig.StealHoldSeconds + plot.holdBonus
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = unit
		prompt.Triggered:Connect(function(thief: Player)
			local victim = plot.owner
			if victim and stealHandler then
				stealHandler(thief, victim.UserId, dog.name, unit)
			end
		end)
	end
end

-- Current safe-vault / stealable-display capacity, derived from the player's
-- upgrade levels (item 5) rather than the flat starting config.
local function vaultCapacity(data: DataManager.PlayerData): number
	local levels = GameConfig.VaultSlotLevels
	local def = levels[data.vaultSlotsLvl] or levels[#levels]
	return def.slots
end

local function displayCapacity(data: DataManager.PlayerData): number
	local levels = GameConfig.DisplaySlotLevels
	local def = levels[data.displaySlotsLvl] or levels[#levels]
	return def.slots
end

-- Rebuild a player's pedestals + vault from their current inventory. Cheap enough
-- to call whenever inventory changes (cook, steal, deposit) or capacity upgrades.
function PlotManager.syncDisplay(player: Player)
	local plot = ownerToPlot[player.UserId]
	if not plot then
		return
	end
	local data = DataManager.get(player)
	if not data then
		return
	end

	clearUnits(plot.pedestalAnchors)
	clearUnits(plot.vaultAnchors)

	local vaultCap = vaultCapacity(data)
	local displayCap = displayCapacity(data)
	local units = HotDogDex.sortedUnits(data.hotDogs)
	-- Top `vaultCap` units -> safe vault; the next `displayCap` -> stealable pedestals.
	for i, dog in units do
		if i <= vaultCap then
			local anchor = plot.vaultAnchors[i]
			if anchor then
				spawnUnit(plot, anchor, dog, false)
			end
		else
			local pedIndex = i - vaultCap
			if pedIndex > displayCap then
				break -- Out of display room; remaining units are "in storage" (not shown).
			end
			local anchor = plot.pedestalAnchors[pedIndex]
			if anchor then
				spawnUnit(plot, anchor, dog, true)
			else
				break
			end
		end
	end
end

-- Update the steal hold-time on this plot (called when a wall is bought). Applies
-- to current prompts and is baked into future ones via `plot.holdBonus`.
function PlotManager.setStealHoldBonus(player: Player, bonus: number)
	local plot = ownerToPlot[player.UserId]
	if not plot then
		return
	end
	plot.holdBonus = bonus
	for _, anchor in plot.pedestalAnchors do
		for _, child in anchor:GetChildren() do
			local prompt = child:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.HoldDuration = GameConfig.StealHoldSeconds + bonus
			end
		end
	end
end

-- Toggle the deposit prompt on a player's own stand (shown only while carrying).
function PlotManager.setDepositEnabled(player: Player, enabled: boolean)
	local plot = ownerToPlot[player.UserId]
	if plot then
		plot.depositPrompt.Enabled = enabled
	end
end

function PlotManager.release(player: Player)
	local plot = ownerToPlot[player.UserId]
	if not plot then
		return
	end
	clearUnits(plot.pedestalAnchors)
	clearUnits(plot.vaultAnchors)
	if plot.guardModel then
		plot.guardModel:Destroy()
		plot.guardModel = nil
	end
	if plot.wallModel then
		plot.wallModel:Destroy()
		plot.wallModel = nil
	end
	plot.holdBonus = 0
	plot.depositPrompt.Enabled = false
	plot.signText.Text = "Empty Plot"
	plot.model:SetAttribute("OwnerUserId", nil)
	plot.owner = nil
	ownerToPlot[player.UserId] = nil
end

-- Where a player should spawn: standing in the aisle just in front of their own
-- stand, turned to face it. Returns nil if they have no plot yet.
function PlotManager.getSpawnCFrame(player: Player): CFrame?
	local plot = ownerToPlot[player.UserId]
	if not plot then
		return nil
	end
	-- The stand's front is its local +Z; step out into the aisle and turn 180° so
	-- the player looks back at their own stand on spawn (clear "this is yours").
	return plot.facing * CFrame.new(0, 5, 12) * CFrame.Angles(0, math.pi, 0)
end

-- Convenience for services that need to reason about "who is standing on my plot".
function PlotManager.plotCenterOf(player: Player): Vector3?
	local plot = ownerToPlot[player.UserId]
	return plot and plot.center or nil
end

Players.PlayerRemoving:Connect(function(player)
	PlotManager.release(player)
end)

return PlotManager
