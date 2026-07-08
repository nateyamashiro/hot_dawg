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

local BuildGrants = require(ReplicatedStorage.Shared.BuildGrants)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GlizzyModel = require(ReplicatedStorage.Shared.GlizzyModel)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local Theme = require(ReplicatedStorage.Shared.Theme)
local Variants = require(ReplicatedStorage.Shared.Variants)
local DataManager = require(ServerScriptService.Server.DataManager)

-- One walk-on tycoon pad (build/upgrade button). `part` is the step pad; `label` is
-- its floating cost text; `id` routes the purchase through Main's pad handler.
export type Pad = {
	id: string,
	part: BasePart,
	label: TextLabel,
}

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
	trapModel: Model?,
	-- Walk-on tycoon pads (cook is a separate ProximityPrompt station, not a pad).
	pads: { [string]: Pad },
	cookPrompt: ProximityPrompt,
	stoveModel: Model?,
	-- Spawned BuildCatalog structures, keyed by catalog id (BuildService drives these;
	-- the old DefenseService wallModel is retired — the wall is a structure now).
	structures: { [string]: Model },
}

local PlotManager = {}

local plots: { Plot } = {}
local ownerToPlot: { [number]: Plot } = {}

-- Handlers registered by StealService (dependency inversion: PlotManager owns the
-- prompts, StealService owns the rules).
type StealHandler = (thief: Player, victimUserId: number, dogName: string, unitPart: BasePart) -> ()
type DepositHandler = (thief: Player) -> ()
-- Owner steps on a build/upgrade pad → route the purchase (Main decides the effect).
type PadHandler = (owner: Player, padId: string) -> ()
-- Owner uses their cook station → roll a hot dog (Main owns the cook logic).
type CookHandler = (owner: Player) -> ()
-- A NON-owner brushed a slow-down gate curtain → apply the slow (BuildService owns
-- the rule; the per-player 1.5s debounce lives in the gate builder).
type GateHandler = (toucher: Player) -> ()
local stealHandler: StealHandler? = nil
local depositHandler: DepositHandler? = nil
local padHandler: PadHandler? = nil
local cookHandler: CookHandler? = nil
local gateHandler: GateHandler? = nil

function PlotManager.setStealHandler(fn: StealHandler)
	stealHandler = fn
end

function PlotManager.setDepositHandler(fn: DepositHandler)
	depositHandler = fn
end

function PlotManager.setPadHandler(fn: PadHandler)
	padHandler = fn
end

function PlotManager.setCookHandler(fn: CookHandler)
	cookHandler = fn
end

function PlotManager.setGateHandler(fn: GateHandler)
	gateHandler = fn
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

-- Walk-on tycoon pads laid across the front apron of the pad (local offsets; +Z is the
-- stand's front, toward the street). Order left→right. Their dynamic cost/visibility is
-- driven by Main via PlotManager.updatePads; stepping on one routes through padHandler.
local PAD_LAYOUT: { { id: string, offset: Vector3 } } = {
	{ id = "stove", offset = Vector3.new(-15, 0.7, 19) },
	{ id = "grill", offset = Vector3.new(-5, 0.7, 19) },
	{ id = "display", offset = Vector3.new(5, 0.7, 19) },
	{ id = "vault", offset = Vector3.new(15, 0.7, 19) },
	-- Building pads (P-B): each offers ONE item at a time — the next structural (🏗️)
	-- or decor (🎪) BuildCatalog entry — never 15 pads. Main.syncPads fills the label.
	{ id = "build", offset = Vector3.new(25, 0.7, 19) },
	{ id = "decor", offset = Vector3.new(-25, 0.7, 19) },
}

-- Build one walk-on pad for `plot` at a facing-local offset. Owner-only + debounced:
-- only the player who owns the plot this pad sits on triggers it, at most ~2/sec.
local function makeBuyPad(model: Model, facing: CFrame, id: string, offset: Vector3): Pad
	local part = makePart({
		Name = "Pad_" .. id,
		Size = Vector3.new(6, 0.4, 6),
		Color = Color3.fromRGB(90, 150, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
		CFrame = facing * CFrame.new(offset),
	})
	part.Parent = model
	local label = makeBillboard(part, "", Color3.fromRGB(220, 255, 210), 60, "PadLabel")
	-- Start hidden (no owner yet). updatePads reveals affordable/available pads.
	part.Transparency = 1
	part.CanTouch = false
	(label.Parent :: BillboardGui).Enabled = false

	local nextAllowed = 0
	part.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		local toucher = character and Players:GetPlayerFromCharacter(character)
		if not toucher then
			return
		end
		-- Only the owner of THIS plot (pad is a descendant of their model) may buy.
		local ownPlot = ownerToPlot[toucher.UserId]
		if not (ownPlot and part:IsDescendantOf(ownPlot.model)) then
			return
		end
		if os.clock() < nextAllowed then
			return
		end
		nextAllowed = os.clock() + 0.6
		if padHandler then
			padHandler(toucher, id)
		end
	end)

	return { id = id, part = part, label = label }
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

	-- Flat pad. Footprint is config-driven (GameConfig.PlotPad*) so the stands read as
	-- real buildings with room for the auto-cooker + buildable floors (Phase 1/3).
	local pad = makePart({
		Name = "Pad",
		Size = Vector3.new(GameConfig.PlotPadWidth, 1, GameConfig.PlotPadDepth),
		Color = Theme.Palette.WoodWarm,
		CanCollide = true,
		CFrame = facing * CFrame.new(0, 0, 0),
	})
	pad.Parent = model

	-- Sign with the owner name (billboard above a post).
	local signPost = makePart({
		Name = "SignPost",
		Size = Vector3.new(1.5, 8, 1.5),
		Color = Theme.Palette.CharBrown,
		CFrame = facing * CFrame.new(0, 4, -8),
	})
	signPost.Parent = model
	local signText = makeBillboard(signPost, "Empty Plot", Color3.fromRGB(255, 240, 200), 60)

	-- === Floor-1 shell (STATIC on every plot): a humble open-air stall ===
	-- Envelope x ∈ [-24,24], z ∈ [-13.5,8.5]; stations (z=12) + pads (z=19) stay
	-- outside in front. Buildable floors 2/3 stack on top (BUILDERS below).
	local function shellPart(props: { [string]: any })
		local part = makePart(props)
		part.CanCollide = true
		part.CFrame = facing * (props.CFrame :: CFrame)
		part.Parent = model
	end
	for _, sx in { -23, 23 } do
		for _, sz in { 7.5, -13.5 } do
			shellPart({
				Name = "ShellPost",
				Size = Vector3.new(1.5, 9, 1.5),
				Color = Theme.Palette.CharBrown,
				CFrame = CFrame.new(sx, 5, sz),
			})
		end
	end
	shellPart({
		Name = "BackWall",
		Size = Vector3.new(48, 9, 1),
		Color = Theme.Palette.Cream,
		CFrame = CFrame.new(0, 5, -13.5),
	})
	-- Waist-high side walls — open above so the stall never reads as a box.
	for _, sx in { -23.5, 23.5 } do
		shellPart({
			Name = "SideWall",
			Size = Vector3.new(1, 3.5, 20),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 2.25, -3),
		})
	end
	-- Front counters + mustard tops, leaving a permanent 12-stud entrance x ∈ [-6,6]
	-- (the deposit pad sits in that doorway — an always-open ground route, rule 1).
	for _, sx in { -14, 14 } do
		shellPart({
			Name = "Counter",
			Size = Vector3.new(16, 2.5, 1.5),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 1.75, 7.5),
		})
		shellPart({
			Name = "CounterTop",
			Size = Vector3.new(16, 0.5, 2),
			Color = Theme.Palette.Mustard,
			CFrame = CFrame.new(sx, 3.25, 7.5),
		})
	end

	-- Front row: stealable pedestals. Build the MAXIMUM up front; syncDisplay only
	-- fills up to the owner's current DisplaySlots level (upgrades reveal more).
	local pedestalAnchors: { BasePart } = {}
	local slots = GameConfig.MaxDisplaySlots
	for i = 1, slots do
		local offsetX = (i - (slots + 1) / 2) * 2.6
		local anchor = makePart({
			Name = "Pedestal" .. i,
			Size = Vector3.new(2, 2, 2),
			Color = Theme.Palette.Cream,
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
			Color = Theme.Palette.VaultGold,
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
		Color = Theme.Semantic.Deposit,
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

	-- Cook station (front-right): a permanent grill the owner uses to cook glizzies. A
	-- ProximityPrompt routes to Main's cook handler (same server-authoritative roll as
	-- the on-screen Cook button). Visible + interactable only for the plot owner.
	local cookStation = makePart({
		Name = "CookStation",
		Size = Vector3.new(5, 3, 4),
		Color = Theme.Palette.Steel,
		Material = Enum.Material.Metal,
		CanCollide = true,
		CFrame = facing * CFrame.new(15, 1.5, 12),
	})
	cookStation.Parent = model
	makeBillboard(cookStation, "🌭 Cook Station", Color3.fromRGB(255, 220, 150), 40, "CookLabel")
	local cookPrompt = Instance.new("ProximityPrompt")
	cookPrompt.ActionText = "Cook a glizzy"
	cookPrompt.ObjectText = "Grill"
	cookPrompt.HoldDuration = 0.2
	cookPrompt.MaxActivationDistance = 10
	cookPrompt.RequiresLineOfSight = false
	cookPrompt.Enabled = false
	cookPrompt.Parent = cookStation
	cookPrompt.Triggered:Connect(function(triggerer: Player)
		local ownPlot = ownerToPlot[triggerer.UserId]
		if cookHandler and ownPlot and ownPlot.cookPrompt == cookPrompt then
			cookHandler(triggerer)
		end
	end)

	-- Walk-on build/upgrade pads along the front apron.
	local pads: { [string]: Pad } = {}
	for _, spec in PAD_LAYOUT do
		pads[spec.id] = makeBuyPad(model, facing, spec.id, spec.offset)
	end

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
		trapModel = nil,
		pads = pads,
		cookPrompt = cookPrompt,
		stoveModel = nil,
		structures = {},
	}
end

function PlotManager.build()
	for i = 1, GameConfig.PlotCount do
		table.insert(plots, buildPlot(i))
	end
end

-- ==================================================================================
-- Buildable structures (P-B). One builder per BuildCatalog id; each returns a Model
-- of parts positioned plot-locally (specs mirror the design plan §2.4).
--
-- THEFT-AND-DEFEND BALANCE RULES (LOCKED — design plan §2.7; encode in every builder):
--   1. Every plot keeps ≥1 always-open ground route: the wall's 16-stud front gap is
--      permanent, and the gate never collides — it only slows non-owners.
--   2. Every elevated display floor keeps ≥1 no-purchase access for outsiders:
--      floor-2 railings are jumpable, floor 3 ships its own climbable truss, and
--      elevator prompts work for EVERYONE (thieves included).
--   3. Thieves descend by jumping off. Upper floors cost thieves TIME — that time is
--      the defense value being sold. Never remove access.
-- ==================================================================================

-- A structure part: plot-local CFrame, CanCollide defaults TRUE (structural), parts
-- named "FloorPedestal" become display anchors (collected by spawnStructure).
local function structurePart(model: Model, plot: Plot, props: { [string]: any }): BasePart
	local part = makePart(props)
	part.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
	part.CFrame = plot.facing * (props.CFrame :: CFrame)
	part.Parent = model
	return part
end

local BUILDERS: { [string]: (plot: Plot) -> Model } = {}

BUILDERS.floor2 = function(plot: Plot): Model
	local model = Instance.new("Model")
	structurePart(model, plot, {
		Name = "Slab2",
		Size = Vector3.new(48, 1, 22),
		Color = Theme.Palette.BunTan,
		CFrame = CFrame.new(0, 10, -2.5),
	})
	-- Railings are JUMPABLE by design (rule 2) — they slow a thief, never stop one.
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(48, 2.5, 0.5),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(0, 11.75, 8),
	})
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(48, 2.5, 0.5),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(0, 11.75, -13),
	})
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(0.5, 2.5, 21),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(23.75, 11.75, -2.5),
	})
	-- West rail split: 6-stud stair opening centered z=-9 (the stairs2 landing).
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(0.5, 2.5, 1),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(-23.75, 11.75, -12.5),
	})
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(0.5, 2.5, 14),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(-23.75, 11.75, 1),
	})
	for _, sx in { -4, 4 } do
		structurePart(model, plot, {
			Name = "FloorPedestal",
			Size = Vector3.new(2, 2, 2),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 11.5, 0),
		})
	end
	return model
end

BUILDERS.stairs2 = function(plot: Plot): Model
	local model = Instance.new("Model")
	-- Outdoor west-side stairs up to the floor-2 rail opening. CanCollide=true —
	-- thieves climb them too (rule 2).
	for i = 1, 10 do
		structurePart(model, plot, {
			Name = "Step",
			Size = Vector3.new(4, 1, 2),
			Color = Theme.Palette.CharBrown,
			CFrame = CFrame.new(-26.5, i, 7 - (i - 1) * 2),
		})
	end
	structurePart(model, plot, {
		Name = "Landing",
		Size = Vector3.new(5, 1, 4),
		Color = Theme.Palette.CharBrown,
		CFrame = CFrame.new(-26.5, 10, -13),
	})
	return model
end

BUILDERS.wall = function(plot: Plot): Model
	-- Perimeter fence. The 16-stud front opening (x ∈ [-8,8]) is PERMANENT (rule 1):
	-- walls buy hold-time (WallHoldBonusSeconds), they never seal the plot.
	local model = Instance.new("Model")
	structurePart(model, plot, {
		Name = "WallBack",
		Size = Vector3.new(60, 6, 1),
		Color = Theme.Palette.Cream,
		CFrame = CFrame.new(0, 3, -22.5),
	})
	for _, sx in { -29.5, 29.5 } do
		structurePart(model, plot, {
			Name = "WallSide",
			Size = Vector3.new(1, 6, 44),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 3, 0),
		})
	end
	for _, sx in { -19, 19 } do
		structurePart(model, plot, {
			Name = "WallFront",
			Size = Vector3.new(22, 6, 1),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 3, 22.5),
		})
	end
	return model
end

BUILDERS.floor3 = function(plot: Plot): Model
	local model = Instance.new("Model")
	for _, sx in { -23, 23 } do
		for _, sz in { 7.5, -13.5 } do
			structurePart(model, plot, {
				Name = "Post3",
				Size = Vector3.new(1.5, 8, 1.5),
				Color = Theme.Palette.CharBrown,
				CFrame = CFrame.new(sx, 14.5, sz),
			})
		end
	end
	structurePart(model, plot, {
		Name = "Slab3",
		Size = Vector3.new(48, 1, 22),
		Color = Theme.Palette.BunTan,
		CFrame = CFrame.new(0, 19, -2.5),
	})
	-- Parapets, with a 4-stud gap in the east rail at z=-12.5 where the truss lands.
	structurePart(model, plot, {
		Name = "Parapet",
		Size = Vector3.new(48, 2.5, 0.5),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(0, 20.75, 8),
	})
	structurePart(model, plot, {
		Name = "Parapet",
		Size = Vector3.new(48, 2.5, 0.5),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(0, 20.75, -13),
	})
	structurePart(model, plot, {
		Name = "Parapet",
		Size = Vector3.new(0.5, 2.5, 21),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(-23.75, 20.75, -2.5),
	})
	structurePart(model, plot, {
		Name = "Parapet",
		Size = Vector3.new(0.5, 2.5, 18.5),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(23.75, 20.75, -1.25),
	})
	-- Climbable truss, ground → east rail gap: floor 3's THEFT-ACCESS GUARANTEE
	-- (rule 2). Ships in the same model so the floor can never exist without it.
	local truss = Instance.new("TrussPart")
	truss.Anchored = true
	truss.Size = Vector3.new(2, 19, 2)
	truss.Color = Theme.Palette.CharBrown
	truss.CFrame = plot.facing * CFrame.new(25.5, 10, -12.5)
	truss.Parent = model
	for _, sx in { 0, -6, 6 } do
		structurePart(model, plot, {
			Name = "FloorPedestal",
			Size = Vector3.new(2, 2, 2),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 20.5, 0),
		})
	end
	return model
end

BUILDERS.gate = function(plot: Plot): Model
	local model = Instance.new("Model")
	for _, sx in { -8, 8 } do
		structurePart(model, plot, {
			Name = "GatePost",
			Size = Vector3.new(1.5, 7, 1.5),
			Color = Theme.Palette.Ketchup,
			CFrame = CFrame.new(sx, 3.5, 22.5),
		})
	end
	-- Hanging strip curtain across the wall opening. CanCollide=false: gates SLOW,
	-- never block (rule 1). Touch slows non-owners via the gate handler; the 1.5s
	-- per-player debounce lives here.
	local nextAllowed: { [number]: number } = {}
	for i = 1, 7 do
		local strip = structurePart(model, plot, {
			Name = "GateStrip",
			Size = Vector3.new(1.6, 5, 0.3),
			Color = if i % 2 == 1 then Theme.Palette.Mustard else Theme.Palette.Ketchup,
			CanCollide = false,
			CFrame = CFrame.new(-6.9 + (i - 1) * 2.3, 4.5, 22.5),
		})
		strip.Touched:Connect(function(hit: BasePart)
			local character = hit.Parent
			local toucher = character and Players:GetPlayerFromCharacter(character)
			if not toucher or toucher == plot.owner then
				return
			end
			local now = os.clock()
			if now < (nextAllowed[toucher.UserId] or 0) then
				return
			end
			nextAllowed[toucher.UserId] = now + 1.5
			if gateHandler then
				gateHandler(toucher)
			end
		end)
	end
	return model
end

BUILDERS.elevator = function(plot: Plot): Model
	-- Teleport-pad pair (locked decision #7), NOT a moving platform. Prompts are
	-- enabled for EVERYONE — thieves ride too (rule 2).
	local model = Instance.new("Model")
	for _, sz in { 3.5, 6.5 } do
		structurePart(model, plot, {
			Name = "ElevatorPole",
			Size = Vector3.new(1, 20, 1),
			Color = Theme.Palette.CharBrown,
			CFrame = CFrame.new(23, 10, sz),
		})
	end
	local pads: { BasePart } = {}
	for _, sy in { 1.05, 20.25 } do
		local padPart = structurePart(model, plot, {
			Name = "ElevatorPad",
			Size = Vector3.new(4, 0.5, 4),
			Color = Theme.Palette.Mustard,
			Material = Enum.Material.Neon,
			CFrame = CFrame.new(21, sy, 5),
		})
		table.insert(pads, padPart)
	end
	for i, padPart in pads do
		local other = pads[if i == 1 then 2 else 1]
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Elevator"
		prompt.ObjectText = "Glizzy Lift"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 6
		prompt.RequiresLineOfSight = false
		prompt.Parent = padPart
		prompt.Triggered:Connect(function(rider: Player)
			local char = rider.Character
			if not char then
				return
			end
			local pivot = char:GetPivot()
			char:PivotTo(CFrame.new(other.Position + Vector3.new(0, 3.5, 0)) * pivot.Rotation)
			-- 0.3s arrival flash on the destination pad.
			other.Transparency = 0.6
			task.delay(0.3, function()
				other.Transparency = 0
			end)
		end)
	end
	return model
end

BUILDERS.awning = function(plot: Plot): Model
	-- Pitched striped canopy over the counters.
	local model = Instance.new("Model")
	local stripeIndex = 0
	for sx = -20, 20, 10 do
		stripeIndex += 1
		structurePart(model, plot, {
			Name = "AwningStripe",
			Size = Vector3.new(10, 0.6, 7),
			Color = if stripeIndex % 2 == 1 then Theme.Palette.Ketchup else Theme.Palette.Cream,
			CanCollide = false,
			CFrame = CFrame.new(sx, 9, 10.2) * CFrame.Angles(math.rad(-18), 0, 0),
		})
	end
	return model
end

BUILDERS.planters = function(plot: Plot): Model
	local model = Instance.new("Model")
	for _, sx in { -9, 9 } do
		structurePart(model, plot, {
			Name = "PlanterBox",
			Size = Vector3.new(6, 1.5, 2),
			Color = Theme.Palette.CharBrown,
			CFrame = CFrame.new(sx, 1.25, 9.5),
		})
		for _, dx in { -1.8, 0, 1.8 } do
			structurePart(model, plot, {
				Name = "Bush",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.6, 1.6, 1.6),
				Color = Theme.Palette.Relish,
				CanCollide = false,
				CastShadow = false,
				CFrame = CFrame.new(sx + dx, 2.6, 9.5),
			})
		end
		structurePart(model, plot, {
			Name = "Tomato",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.9, 0.9, 0.9),
			Color = Theme.Palette.Ketchup,
			CanCollide = false,
			CastShadow = false,
			CFrame = CFrame.new(sx + 2.2, 2.3, 9.9),
		})
	end
	return model
end

BUILDERS.sign = function(plot: Plot): Model
	-- Board + a physical neon glizzy (bun cylinder + Neon ketchup sausage along X).
	local model = Instance.new("Model")
	structurePart(model, plot, {
		Name = "SignBoard",
		Size = Vector3.new(12, 4, 0.8),
		Color = Theme.Palette.CharBrown,
		CFrame = CFrame.new(0, 12.5, 9.3),
	})
	structurePart(model, plot, {
		Name = "SignBun",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 1.8, 1.8),
		Color = Theme.Palette.BunTan,
		CanCollide = false,
		CFrame = CFrame.new(0, 12.2, 10),
	})
	structurePart(model, plot, {
		Name = "SignSausage",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6.4, 1.1, 1.1),
		Color = Theme.Palette.Ketchup,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CFrame = CFrame.new(0, 12.75, 10),
	})
	structurePart(model, plot, {
		Name = "SignDrizzle",
		Size = Vector3.new(4, 0.25, 0.25),
		Color = Theme.Palette.Mustard,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
		CFrame = CFrame.new(0, 13.35, 10),
	})
	return model
end

BUILDERS.window2 = function(plot: Plot): Model
	local model = Instance.new("Model")
	for _, sx in { -14, 14 } do
		structurePart(model, plot, {
			Name = "WindowPanel",
			Size = Vector3.new(18, 6, 1),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 14.5, 8),
		})
		for _, dx in { -4, 4 } do
			structurePart(model, plot, {
				Name = "WindowGlass",
				Size = Vector3.new(5, 3.5, 1.2),
				Color = Theme.Palette.SkyBlue,
				Material = Enum.Material.Glass,
				Transparency = Theme.WindowTransparency,
				CanCollide = false,
				CFrame = CFrame.new(sx + dx, 14.5, 8),
			})
			structurePart(model, plot, {
				Name = "WindowSill",
				Size = Vector3.new(5.5, 0.5, 1.4),
				Color = Theme.Palette.Mustard,
				CanCollide = false,
				CastShadow = false,
				CFrame = CFrame.new(sx + dx, 12.4, 8),
			})
		end
	end
	return model
end

BUILDERS.flags = function(plot: Plot): Model
	-- Two sagging bunting strings from the shell posts up to the sign line.
	local model = Instance.new("Model")
	local colors = {
		Theme.Palette.Ketchup,
		Theme.Palette.Mustard,
		Theme.Palette.Relish,
		Theme.Palette.SkyBlue,
	}
	for _, sideX in { -23, 23 } do
		local from = Vector3.new(sideX, 9.5, 7.5)
		local to = Vector3.new(0, 12, 9)
		for i = 1, 6 do
			local t = (i - 0.5) / 6
			local pos = from:Lerp(to, t) - Vector3.new(0, math.sin(math.pi * t), 0) -- 1-stud mid dip
			local pennant = Instance.new("WedgePart")
			pennant.Anchored = true
			pennant.CanCollide = false
			pennant.CastShadow = false
			pennant.Material = Enum.Material.SmoothPlastic
			pennant.Size = Vector3.new(0.2, 1.4, 1.4)
			pennant.Color = colors[(i - 1) % 4 + 1]
			pennant.CFrame = plot.facing * CFrame.new(pos) * CFrame.Angles(math.pi, 0, 0)
			pennant.Parent = model
		end
	end
	return model
end

BUILDERS.tiles = function(plot: Plot): Model
	-- 8×4 checkerboard laid over the interior floor. Pure decor: CanCollide=false.
	local model = Instance.new("Model")
	for col = 1, 8 do
		for row = 1, 4 do
			structurePart(model, plot, {
				Name = "Tile",
				Size = Vector3.new(5.5, 0.2, 5.5),
				Color = if (col + row) % 2 == 0 then Theme.Palette.Ketchup else Theme.Palette.Cream,
				CanCollide = false,
				CFrame = CFrame.new((col - 4.5) * 5.6, 0.6, (row - 2.5) * 5.6 - 2.5),
			})
		end
	end
	return model
end

BUILDERS.window3 = function(plot: Plot): Model
	-- Mirrors window2 one floor up.
	local model = Instance.new("Model")
	for _, sx in { -14, 14 } do
		structurePart(model, plot, {
			Name = "WindowPanel",
			Size = Vector3.new(18, 6, 1),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 23.5, 8),
		})
		for _, dx in { -4, 4 } do
			structurePart(model, plot, {
				Name = "WindowGlass",
				Size = Vector3.new(5, 3.5, 1.2),
				Color = Theme.Palette.SkyBlue,
				Material = Enum.Material.Glass,
				Transparency = Theme.WindowTransparency,
				CanCollide = false,
				CFrame = CFrame.new(sx + dx, 23.5, 8),
			})
			structurePart(model, plot, {
				Name = "WindowSill",
				Size = Vector3.new(5.5, 0.5, 1.4),
				Color = Theme.Palette.Mustard,
				CanCollide = false,
				CastShadow = false,
				CFrame = CFrame.new(sx + dx, 21.4, 8),
			})
		end
	end
	return model
end

BUILDERS.umbrella = function(plot: Plot): Model
	-- Patio set on the front-right apron: pole + two-tier canopy + table + stools.
	local model = Instance.new("Model")
	structurePart(model, plot, {
		Name = "UmbrellaPole",
		Size = Vector3.new(0.6, 7, 0.6),
		Color = Theme.Palette.CharBrown,
		CanCollide = false,
		CFrame = CFrame.new(24, 3.5, 15),
	})
	local upright = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis X → Y
	structurePart(model, plot, {
		Name = "CanopyBig",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 8, 8),
		Color = Theme.Palette.Ketchup,
		CanCollide = false,
		CFrame = CFrame.new(24, 6.4, 15) * upright,
	})
	structurePart(model, plot, {
		Name = "CanopySmall",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 5, 5),
		Color = Theme.Palette.Mustard,
		CanCollide = false,
		CFrame = CFrame.new(24, 7, 15) * upright,
	})
	structurePart(model, plot, {
		Name = "Table",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 4, 4),
		Color = Theme.Palette.Cream,
		CFrame = CFrame.new(24, 2.6, 15) * upright,
	})
	for _, sx in { 21.5, 26.5 } do
		structurePart(model, plot, {
			Name = "Stool",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, 1.6, 1.6),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 1.1, 15) * upright,
		})
	end
	return model
end

BUILDERS.rooftop = function(plot: Plot): Model
	-- The floor-3 capstone gag: a giant glizzy statue on the roof.
	local model = Instance.new("Model")
	structurePart(model, plot, {
		Name = "WienerMount",
		Size = Vector3.new(3, 1.5, 3),
		Color = Theme.Palette.CharBrown,
		CFrame = CFrame.new(0, 20.35, -2.5),
	})
	local wiener = GlizzyModel.build("Plain Dog", {
		rarity = "Common",
		scale = 4,
		anchored = true,
		fx = false,
	})
	-- Not "DogUnit": nothing should ever try to steal or fx-track the statue.
	wiener.Name = "RooftopWiener"
	wiener:PivotTo(plot.facing * CFrame.new(0, 22.9, -2.5) * CFrame.Angles(0, 0, math.rad(8)))
	wiener.Parent = model
	return model
end

-- Spawn one built structure onto the owner's plot. Floor builders contribute new
-- display anchors (parts named "FloorPedestal"), appended past the base MaxDisplaySlots
-- anchors — so positions 17+ are floor slots, filled only once capacity grows.
function PlotManager.spawnStructure(player: Player, entry: BuildGrants.Entry)
	local plot = ownerToPlot[player.UserId]
	if not plot then
		return
	end
	if plot.structures[entry.id] then
		return -- already standing (idempotent)
	end
	local builder = BUILDERS[entry.id]
	if not builder then
		warn("[PlotManager] No builder for structure id '" .. entry.id .. "'")
		return
	end
	local model = builder(plot)
	model.Name = "Structure_" .. entry.id
	model.Parent = plot.model
	plot.structures[entry.id] = model
	for _, child in model:GetChildren() do
		if child.Name == "FloorPedestal" and child:IsA("BasePart") then
			table.insert(plot.pedestalAnchors, child)
		end
	end
end

-- Destroy every spawned structure and truncate pedestalAnchors back to the pre-built
-- base count (floor anchors are always positions MaxDisplaySlots+1 and up).
local function clearStructures(plot: Plot)
	for id, model in plot.structures do
		model:Destroy()
		plot.structures[id] = nil
	end
	for i = #plot.pedestalAnchors, GameConfig.MaxDisplaySlots + 1, -1 do
		table.remove(plot.pedestalAnchors, i)
	end
end

-- Clear + re-spawn everything in `data.built`, in catalog array order (floors exist
-- before the windows/rooftop that mount on them). Join path — grants are derived at
-- read time from data.built, so a rebuild can never double-apply them.
function PlotManager.rebuildStructures(player: Player)
	local plot = ownerToPlot[player.UserId]
	local data = DataManager.get(player)
	if not (plot and data) then
		return
	end
	clearStructures(plot)
	for _, entry in BuildGrants.all() do
		if data.built[entry.id] then
			PlotManager.spawnStructure(player, entry)
		end
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
			plot.cookPrompt.Enabled = true -- owner can now cook at their station
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
-- gets a Steal prompt (front pedestals) or is safe (vault shelf). The unit carries
-- its inventory KEY so the steal handler removes the exact stack (variant included);
-- a mutation tints the label with its variant colour. The unit is a real procedural
-- glizzy (GlizzyModel): rarity aura fx on pedestals only (vault stays clean — budget
-- rule), Giant renders at 1.5× (overlap IS the flex).
local function spawnUnit(plot: Plot, anchor: BasePart, dog: HotDogDex.Unit, stealable: boolean)
	local unit = GlizzyModel.build(dog.name, {
		rarity = dog.rarity,
		variant = dog.variant,
		scale = if dog.variant == "Giant" then 1.5 else 1,
		anchored = true,
		fx = stealable,
	})
	unit:SetAttribute("DogName", dog.name)
	unit:SetAttribute("DogKey", dog.key)
	unit:PivotTo(anchor.CFrame * CFrame.new(0, 1.6, 0))
	local primary = unit.PrimaryPart :: BasePart

	local color = HotDogDex.colorFor(dog.rarity)
	local vdef = Variants.def(dog.variant)
	local labelColor = if vdef and dog.variant ~= "base" then vdef.color else color
	local label = makeBillboard(primary, dog.displayName, labelColor, 44)
	local billboard = label.Parent :: BillboardGui
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	unit.Parent = anchor

	if stealable then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Steal"
		prompt.ObjectText = dog.displayName
		prompt.HoldDuration = GameConfig.StealHoldSeconds + plot.holdBonus
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = primary
		prompt.Triggered:Connect(function(thief: Player)
			local victim = plot.owner
			if victim and stealHandler then
				-- Still passes the unit's PrimaryPart as `unitPart`, so StealService's
				-- staleness check (unitPart.Parent) keeps working.
				stealHandler(thief, victim.UserId, dog.key, primary)
			end
		end)
	end
end

-- Current safe-vault / stealable-display capacity: the player's coin-upgrade level
-- (item 5) PLUS bonus slots banked by prestige unlocks / the extra-slots pass
-- (data.bonus*Slots). Capacity beyond the pre-built anchor maximum (Max*Slots) just
-- goes unshown — spawnUnit only fills anchors that exist.
local function vaultCapacity(data: DataManager.PlayerData): number
	local levels = GameConfig.VaultSlotLevels
	local def = levels[data.vaultSlotsLvl] or levels[#levels]
	return def.slots + data.bonusVaultSlots
end

local function displayCapacity(data: DataManager.PlayerData): number
	local levels = GameConfig.DisplaySlotLevels
	local def = levels[data.displaySlotsLvl] or levels[#levels]
	-- Built floors add their pedestal slots (derived from data.built at read time —
	-- never banked — so rebuild-on-join can't double-apply).
	return def.slots + data.bonusDisplaySlots + BuildGrants.displaySlotBonus(data.built)
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

	-- Capacity includes bonus slots from prestige unlocks / the extra-slots pass
	-- (folded into vaultCapacity/displayCapacity).
	local vaultCap = vaultCapacity(data)
	local displayCap = displayCapacity(data)
	-- TODO(M2-vault): honor data.vaultPins first — pinned keys fill the vault before
	-- the auto-top-by-value overflow below.
	local units = HotDogDex.sortedUnits(data.hotDogs)
	-- Top `vaultCap` units -> safe vault; the next `displayCap` -> stealable pedestals.
	for i, unit in units do
		if i <= vaultCap then
			local anchor = plot.vaultAnchors[i]
			if anchor then
				spawnUnit(plot, anchor, unit, false)
			end
		else
			local pedIndex = i - vaultCap
			if pedIndex > displayCap then
				break -- Out of display room; remaining units are "in storage" (not shown).
			end
			local anchor = plot.pedestalAnchors[pedIndex]
			if anchor then
				spawnUnit(plot, anchor, unit, true)
			else
				break
			end
		end
	end
end

-- Show/hide the owner's walk-on pads, set each one's cost label, and colour it GREEN
-- when the player can afford it / RED when it's too expensive. `info[id]` present =>
-- reveal that pad; absent => hide it (e.g. a maxed upgrade). Main computes `info`.
local PAD_GREEN = Theme.Semantic.Affordable
local PAD_RED = Theme.Semantic.Expensive
function PlotManager.updatePads(
	player: Player,
	info: { [string]: { text: string, affordable: boolean } }
)
	local plot = ownerToPlot[player.UserId]
	if not plot then
		return
	end
	for id, pad in plot.pads do
		local entry = info[id]
		local billboard = pad.label.Parent :: BillboardGui
		if entry then
			pad.label.Text = entry.text
			pad.part.Color = if entry.affordable then PAD_GREEN else PAD_RED
			pad.part.Transparency = 0.2
			pad.part.CanTouch = true
			billboard.Enabled = true
		else
			pad.part.Transparency = 1
			pad.part.CanTouch = false
			billboard.Enabled = false
		end
	end
end

-- Create / update / remove the physical stove on the owner's plot. `level` 0 removes it;
-- >=1 shows a stove labelled with its tier + coins/sec (the passive income machine).
function PlotManager.setStove(player: Player, level: number, coinsPerSec: number)
	local plot = ownerToPlot[player.UserId]
	if not plot then
		return
	end
	if level <= 0 then
		if plot.stoveModel then
			plot.stoveModel:Destroy()
			plot.stoveModel = nil
		end
		return
	end
	local model = plot.stoveModel
	if not model then
		local m = Instance.new("Model")
		m.Name = "Stove"
		local body = makePart({
			Name = "StoveBody",
			Size = Vector3.new(5, 3, 4),
			Color = Theme.Palette.Ketchup,
			Material = Enum.Material.Metal,
			CanCollide = true,
			CFrame = plot.facing * CFrame.new(-15, 1.5, 12),
		})
		body.Parent = m
		makeBillboard(body, "", Color3.fromRGB(255, 200, 120), 40, "StoveLabel")
		m.Parent = plot.model
		plot.stoveModel = m
		model = m
	end
	local body = model:FindFirstChild("StoveBody")
	local billboard = body and body:FindFirstChildOfClass("BillboardGui")
	local label = billboard and billboard:FindFirstChildOfClass("TextLabel")
	if label and label:IsA("TextLabel") then
		-- Cooker-slot bonuses make the rate fractional; show one decimal, cleanly.
		local shown = math.floor(coinsPerSec * 10 + 0.5) / 10
		label.Text = "🔥 Stove Lv " .. level .. "  (+" .. shown .. "/s)"
	end
end

-- Update the steal hold-time on this plot (called when a wall is built). Applies
-- to current prompts and is baked into future ones via `plot.holdBonus`. Descendant
-- scan because Steal prompts live on the glizzy model's PrimaryPart, not directly
-- under the anchor.
function PlotManager.setStealHoldBonus(player: Player, bonus: number)
	local plot = ownerToPlot[player.UserId]
	if not plot then
		return
	end
	plot.holdBonus = bonus
	for _, anchor in plot.pedestalAnchors do
		for _, desc in anchor:GetDescendants() do
			if desc:IsA("ProximityPrompt") then
				desc.HoldDuration = GameConfig.StealHoldSeconds + bonus
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
	clearStructures(plot)
	if plot.guardModel then
		plot.guardModel:Destroy()
		plot.guardModel = nil
	end
	if plot.trapModel then
		plot.trapModel:Destroy()
		plot.trapModel = nil
	end
	if plot.stoveModel then
		plot.stoveModel:Destroy()
		plot.stoveModel = nil
	end
	for _, pad in plot.pads do
		pad.part.Transparency = 1
		pad.part.CanTouch = false
		local billboard = pad.label.Parent :: BillboardGui
		billboard.Enabled = false
	end
	plot.holdBonus = 0
	plot.depositPrompt.Enabled = false
	plot.cookPrompt.Enabled = false
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

-- === Accessors for the juice layer (P-C) — Celebrate effects attach to real parts ===
function PlotManager.cookStationOf(player: Player): BasePart?
	local plot = ownerToPlot[player.UserId]
	local station = plot and plot.cookPrompt.Parent
	return if station and station:IsA("BasePart") then station else nil
end

function PlotManager.padPartOf(player: Player, padId: string): BasePart?
	local plot = ownerToPlot[player.UserId]
	local pad = plot and plot.pads[padId]
	return pad and pad.part or nil
end

function PlotManager.signPostOf(player: Player): BasePart?
	local plot = ownerToPlot[player.UserId]
	local billboard = plot and plot.signText.Parent
	local post = billboard and billboard.Parent
	return if post and post:IsA("BasePart") then post else nil
end

Players.PlayerRemoving:Connect(function(player)
	PlotManager.release(player)
end)

return PlotManager
