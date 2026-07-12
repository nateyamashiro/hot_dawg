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
local TweenService = game:GetService("TweenService")

local BuildGrants = require(ReplicatedStorage.Shared.BuildGrants)
local Format = require(ReplicatedStorage.Shared.Format)
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
	-- Physical drop-rates board beside the cook station (additions #16): Main feeds it
	-- the same odds lines the old HUD sidebar showed, per grill level + pity.
	oddsText: TextLabel,
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
-- The OWNER pressed the pickup prompt on one of their own displayed dogs
-- (PickupService owns the rule: builds the hand Tool + excludes the slot).
type PickupHandler = (player: Player, key: string) -> ()
local stealHandler: StealHandler? = nil
local depositHandler: DepositHandler? = nil
local padHandler: PadHandler? = nil
local cookHandler: CookHandler? = nil
local gateHandler: GateHandler? = nil
local pickupHandler: PickupHandler? = nil

function PlotManager.setStealHandler(fn: StealHandler)
	stealHandler = fn
end

function PlotManager.setPickupHandler(fn: PickupHandler)
	pickupHandler = fn
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

-- World-text rules (genre standard, matched to Steal a Brainrot: one FAR label per
-- plot — the owner sign — and everything else small, near-fading, and occludable):
-- defaults are compact (120px wide, 45-stud fade, NOT AlwaysOnTop so walls hide
-- labels behind them). Pass `opts` to widen/extend the few labels that earn it.
type BillboardOpts = {
	width: number?,
	maxDistance: number?,
	alwaysOnTop: boolean?,
	offsetY: number?,
}
local function makeBillboard(
	parent: BasePart,
	text: string,
	color: Color3,
	sizeY: number,
	name: string?,
	opts: BillboardOpts?
): TextLabel
	local o: BillboardOpts = opts or {}
	local bb = Instance.new("BillboardGui")
	if name then
		-- Stable name so the client can find + hide structural labels on rival stands.
		bb.Name = name
	end
	bb.Size = UDim2.fromOffset(o.width or 120, sizeY)
	bb.StudsOffsetWorldSpace = Vector3.new(0, o.offsetY or 2.5, 0)
	bb.AlwaysOnTop = o.alwaysOnTop == true
	bb.MaxDistance = o.maxDistance or 45
	bb.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Theme.UI.TitleFont
	label.Text = text
	label.Parent = bb
	return label
end

-- Compact stacked unit plate — the genre's slot label (name / rarity / $-per-sec in
-- three small lines) instead of one giant name tag. Occludable + fades at 60 studs
-- (same horizon as the GlizzyFx emitter culling).
local function makeUnitPlate(parent: BasePart, dog: HotDogDex.Unit, offsetY: number?)
	local bb = Instance.new("BillboardGui")
	bb.Name = "UnitPlate"
	bb.Size = UDim2.fromOffset(96, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, offsetY or 2.1, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 60
	bb.Parent = parent

	local function line(text: string, color: Color3, y: number, h: number, font: Enum.Font)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, h)
		l.Position = UDim2.fromScale(0, y)
		l.BackgroundTransparency = 1
		l.TextColor3 = color
		l.TextStrokeTransparency = 0
		l.TextScaled = true
		l.Font = font
		l.Text = text
		l.Parent = bb
	end

	local vdef = Variants.def(dog.variant)
	local tierColor = if vdef and dog.variant ~= "base"
		then vdef.color
		else HotDogDex.colorFor(dog.rarity)
	local tierText = if vdef and dog.variant ~= "base"
		then dog.variant .. " " .. dog.rarity
		else dog.rarity
	-- Fractional incomes (variant multipliers) show one decimal, whole ones stay whole.
	local income = math.floor(dog.income * 10 + 0.5) / 10
	local incomeText = Format.comma(income, if income % 1 == 0 then 0 else 1)
	line(dog.name, Color3.fromRGB(255, 255, 255), 0, 0.42, Theme.UI.TitleFont)
	line(tierText, tierColor, 0.42, 0.3, Theme.UI.TitleFont)
	line(
		"💰 " .. incomeText .. "/s",
		Color3.fromRGB(170, 255, 170),
		0.72,
		0.28,
		Theme.UI.NumberFont
	)
end

-- Walk-on tycoon pads laid across the front apron of the pad (local offsets; +Z is the
-- stand's front, toward the street). Order left→right. Their dynamic cost/visibility is
-- driven by Main via PlotManager.updatePads; stepping on one routes through padHandler.
local PAD_LAYOUT: { { id: string, offset: Vector3 } } = {
	{ id = "stove", offset = Vector3.new(-19, 0.7, 25) },
	{ id = "grill", offset = Vector3.new(-6, 0.7, 25) },
	{ id = "display", offset = Vector3.new(6, 0.7, 25) },
	{ id = "vault", offset = Vector3.new(19, 0.7, 25) },
	-- Building pads (P-B): each offers ONE item at a time — the next structural (🏗️)
	-- or decor (🎪) BuildCatalog entry — never 15 pads. Main.syncPads fills the label.
	{ id = "build", offset = Vector3.new(32, 0.7, 25) },
	{ id = "decor", offset = Vector3.new(-32, 0.7, 25) },
	-- Machine row (Phase 4/5): ⚙️ upgrader beside the stove (shown once the stove is
	-- built), 🌍 zone expansion beside the cook station (priced in PRESTIGE).
	{ id = "upgrader", offset = Vector3.new(-28, 0.7, 17) },
	{ id = "zone", offset = Vector3.new(28, 0.7, 17) },
}

-- Build one walk-on pad for `plot` at a facing-local offset. Owner-only + debounced:
-- only the player who owns the plot this pad sits on triggers it, at most ~2/sec.
local function makeBuyPad(model: Model, facing: CFrame, id: string, offset: Vector3): Pad
	local part = makePart({
		Name = "Pad_" .. id,
		Size = Vector3.new(6, 0.4, 6),
		Color = Color3.fromRGB(90, 150, 90),
		-- Matte (Theme.Materials rule): the green/red SEMANTIC color is the signal;
		-- eight glowing pads per plot was glare soup.
		CanCollide = false,
		CFrame = facing * CFrame.new(offset),
	})
	part.Parent = model
	local label =
		makeBillboard(part, "", Color3.fromRGB(220, 255, 210), 34, "PadLabel", { width = 104 })
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

-- Roof (additions #15): every stand is capped above its TOPMOST floor — y 13 over the
-- bare shell, y 26 over floor 2, y 39 over floor 3 — recomputed whenever structures
-- change (spawnStructure / rebuildStructures / release). Striped Ketchup/Cream slab
-- (hot-dog-stand awning look). Sides stay OPEN above parapets/waist walls, so raider
-- access (truss, over-wall, front doorway) is never blocked — the roof is cosmetic
-- cover, not a defense.
local function applyRoofTo(model: Model, facing: CFrame, structures: { [string]: Model })
	local existing = model:FindFirstChild("Roof")
	if existing then
		existing:Destroy()
	end
	local roofY = if structures["floor3"] then 39 elseif structures["floor2"] then 26 else 13
	local roof = Instance.new("Model")
	roof.Name = "Roof"
	for i = 1, 5 do
		local strip = makePart({
			Name = "RoofStrip",
			Size = Vector3.new(62, 1, 6),
			Color = if i % 2 == 1 then Theme.Palette.Ketchup else Theme.Palette.Cream,
			CanCollide = true,
			CFrame = facing * CFrame.new(0, roofY, -5.5 + (i - 3) * 6),
		})
		strip.Parent = roof
	end
	-- Support posts when the roof floats above the shell top (the bare-shell roof
	-- rests on the 12-tall shell posts directly; floor 2/3 roofs need their own).
	if roofY > 13 then
		for _, sx in { -29, 29 } do
			for _, sz in { 8, -19 } do
				local post = makePart({
					Name = "RoofPost",
					Size = Vector3.new(1, 12, 1),
					Color = Theme.Palette.CharBrown,
					CanCollide = true,
					CFrame = facing * CFrame.new(sx, roofY - 6.5, sz),
				})
				post.Parent = roof
			end
		end
	end
	roof.Parent = model
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
		CFrame = facing * CFrame.new(0, 4, -15),
	})
	signPost.Parent = model
	-- The ONE far-visible label per plot (genre convention: the owner sign carries
	-- identity at range; everything else reveals on approach).
	local signText = makeBillboard(signPost, "Empty Plot", Color3.fromRGB(255, 240, 200), 44, nil, {
		width = 170,
		maxDistance = 160,
		alwaysOnTop = true,
	})

	-- === Floor-1 shell (STATIC on every plot): a humble open-air stall ===
	-- GROWN 2026-07-11 (additions #3). Envelope x ∈ [-30,30], z ∈ [-19,9], 12 tall;
	-- stations (z=14) + pads (z=25/17) stay outside in front. Buildable floors 2/3
	-- stack on top (BUILDERS below: slab2 y=13, slab3 y=26, roof above the top floor).
	local function shellPart(props: { [string]: any })
		local part = makePart(props)
		part.CanCollide = true
		part.CFrame = facing * (props.CFrame :: CFrame)
		part.Parent = model
	end
	for _, sx in { -29, 29 } do
		for _, sz in { 8, -19 } do
			shellPart({
				Name = "ShellPost",
				Size = Vector3.new(1.5, 12, 1.5),
				Color = Theme.Palette.CharBrown,
				CFrame = CFrame.new(sx, 6.5, sz),
			})
		end
	end
	shellPart({
		Name = "BackWall",
		Size = Vector3.new(60, 12, 1),
		Color = Theme.Palette.Cream,
		CFrame = CFrame.new(0, 6.5, -19),
	})
	-- Waist-high side walls — open above so the stall never reads as a box.
	for _, sx in { -29.5, 29.5 } do
		shellPart({
			Name = "SideWall",
			Size = Vector3.new(1, 3.5, 26),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 2.25, -5),
		})
	end
	-- Front counters + mustard tops, leaving a permanent 12-stud entrance x ∈ [-6,6]
	-- (the deposit pad sits in that doorway — an always-open ground route, rule 1).
	for _, sx in { -18, 18 } do
		shellPart({
			Name = "Counter",
			Size = Vector3.new(24, 2.5, 1.5),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 1.75, 8),
		})
		shellPart({
			Name = "CounterTop",
			Size = Vector3.new(24, 0.5, 2),
			Color = Theme.Palette.Mustard,
			CFrame = CFrame.new(sx, 3.25, 8),
		})
	end

	-- Front row: stealable pedestals. Build the MAXIMUM up front; syncDisplay only
	-- fills up to the owner's current DisplaySlots level (upgrades reveal more).
	local pedestalAnchors: { BasePart } = {}
	local slots = GameConfig.MaxDisplaySlots
	-- Each slot is a little vendor stand (dark base + slim column + red serving
	-- tray) instead of a bare block, so the glizzy on top reads as merchandise.
	-- The TRAY is the anchor part — spawn/steal plumbing is unchanged.
	-- Pitch 3.0 (was 2.6): display glizzies render at 1.8× now (additions #3), so the
	-- merchandise needs elbow room. 18 anchors span x ±25.5 inside the 60-wide shell.
	for i = 1, slots do
		local offsetX = (i - (slots + 1) / 2) * 3.0
		local base = makePart({
			Name = "PedestalBase",
			Size = Vector3.new(2, 0.4, 2),
			Color = Theme.Palette.CharBrown,
			CanCollide = true,
			CFrame = facing * CFrame.new(offsetX, 0.2, 4),
		})
		base.Parent = model
		local column = makePart({
			Name = "PedestalColumn",
			Size = Vector3.new(0.8, 1.55, 0.8),
			Color = Theme.Palette.Cream,
			CanCollide = false,
			CFrame = facing * CFrame.new(offsetX, 1.15, 4),
		})
		column.Parent = model
		local tray = makePart({
			Name = "Pedestal" .. i,
			Size = Vector3.new(2.4, 0.35, 2.4),
			Color = Theme.Palette.Ketchup,
			CanCollide = true,
			CFrame = facing * CFrame.new(offsetX, 2.1, 4),
		})
		tray.Parent = model
		-- Ground-floor anchor (additions #6: rarity sort assigns best dogs to the
		-- HIGHEST floor — anchors carry their floor so syncDisplay can order them).
		tray:SetAttribute("PlotFloor", 1)
		table.insert(pedestalAnchors, tray)
	end

	-- Back shelf: safe vault slots (also built to the maximum; filled per level).
	local vaultAnchors: { BasePart } = {}
	local vaultSlots = GameConfig.MaxVaultSlots
	for i = 1, vaultSlots do
		local offsetX = (i - (vaultSlots + 1) / 2) * 3.0
		local anchor = makePart({
			Name = "Vault" .. i,
			Size = Vector3.new(2.2, 2.2, 2.2),
			Color = Theme.Palette.VaultGold,
			CanCollide = true,
			CFrame = facing * CFrame.new(offsetX, 1.6, -13),
		})
		anchor.Parent = model
		-- ONE small "Vault" tag on the middle anchor (was one per slot = text soup);
		-- the gold shelf color already reads as the safe zone.
		if i == math.ceil(vaultSlots / 2) then
			makeBillboard(anchor, "🔒 Vault", Color3.fromRGB(255, 230, 120), 20, "VaultLabel", {
				width = 76,
				maxDistance = 35,
			})
		end
		table.insert(vaultAnchors, anchor)
	end

	-- Deposit pad (drop stolen dogs here to claim them).
	local depositPad = makePart({
		Name = "DepositPad",
		Size = Vector3.new(6, 0.6, 6),
		Color = Theme.Semantic.Deposit,
		CanCollide = true,
		CFrame = facing * CFrame.new(0, 0.6, 8),
	})
	depositPad.Parent = model
	makeBillboard(depositPad, "Deposit", Color3.fromRGB(180, 255, 200), 20, "DepositLabel", {
		width = 84,
		maxDistance = 35,
		offsetY = 1.6,
	})

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
	-- Additions #2: a real kettle grill — body on legs, grate rods, charcoal glow
	-- (small Neon accent = allowed), propped lid, side shelf. The BODY stays named
	-- "CookStation" and carries the prompt, so all existing plumbing is untouched.
	local cookStation = makePart({
		Name = "CookStation",
		Size = Vector3.new(5, 2.6, 4),
		Color = Theme.Palette.Steel,
		Material = Enum.Material.Metal,
		CanCollide = true,
		CFrame = facing * CFrame.new(19, 1.7, 14),
	})
	cookStation.Parent = model
	for _, gx in { -2, 2 } do
		for _, gz in { -1.5, 1.5 } do
			local leg = makePart({
				Name = "GrillLeg",
				Size = Vector3.new(0.4, 1.4, 0.4),
				Color = Theme.Palette.CharBrown,
				CFrame = facing * CFrame.new(19 + gx, 0.7, 14 + gz),
			})
			leg.Parent = model
		end
	end
	-- Charcoal bed peeks between body and rods (the ONE glow accent on the station).
	local charcoal = makePart({
		Name = "GrillCharcoal",
		Size = Vector3.new(4.2, 0.2, 3.2),
		Color = Color3.fromRGB(255, 120, 40),
		Material = Enum.Material.Neon,
		CastShadow = false,
		CFrame = facing * CFrame.new(19, 3.05, 14),
	})
	charcoal.Parent = model
	for i = 1, 5 do
		local rod = makePart({
			Name = "GrillRod",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3.6, 0.22, 0.22),
			Color = Theme.Palette.CharBrown,
			CastShadow = false,
			-- Cylinder axis is X; rotate 90° so the rods span the grill's depth (Z).
			CFrame = facing
				* CFrame.new(19 - 2.4 + i * 0.8, 3.25, 14)
				* CFrame.Angles(0, math.rad(90), 0),
		})
		rod.Parent = model
	end
	local lid = makePart({
		Name = "GrillLid",
		Size = Vector3.new(5, 0.5, 4),
		Color = Theme.Palette.Ketchup,
		Material = Enum.Material.Metal,
		CFrame = facing * CFrame.new(19, 4.1, 12.2) * CFrame.Angles(math.rad(55), 0, 0),
	})
	lid.Parent = model
	local shelf = makePart({
		Name = "GrillShelf",
		Size = Vector3.new(2, 0.3, 3.4),
		Color = Theme.Palette.WoodWarm,
		CFrame = facing * CFrame.new(15.8, 2.8, 14),
	})
	shelf.Parent = model
	makeBillboard(cookStation, "🌭 Cook", Color3.fromRGB(255, 220, 150), 22, "CookLabel", {
		width = 90,
		maxDistance = 50,
		offsetY = 3.4,
	})

	-- Drop-rates board beside the grill (additions #16): replaces the old HUD odds
	-- sidebar. Main.setOddsSign feeds it the owner's live odds + pity lines.
	local oddsPost = makePart({
		Name = "OddsPost",
		Size = Vector3.new(1, 5, 1),
		Color = Theme.Palette.CharBrown,
		CFrame = facing * CFrame.new(26.5, 2.5, 14),
	})
	oddsPost.Parent = model
	local oddsBoard = makePart({
		Name = "OddsBoard",
		Size = Vector3.new(6.5, 4.5, 0.6),
		Color = Theme.Palette.Cream,
		CFrame = facing * CFrame.new(26.5, 6, 14),
	})
	oddsBoard.Parent = model
	local oddsText = makeBillboard(oddsBoard, "", Theme.Palette.CharBrown, 150, "OddsLabel", {
		width = 140,
		maxDistance = 40,
		offsetY = 0,
	})
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

	-- Every stand ships roofed (additions #15); recomputed as floors go up.
	applyRoofTo(model, facing, {})

	model.Parent = workspace

	return {
		index = index,
		model = model,
		center = center,
		facing = facing,
		signText = signText,
		oddsText = oddsText,
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
	-- Slab at y=13 (the 12-tall shell's ceiling line); interior heights grew with the
	-- footprint (additions #3).
	local model = Instance.new("Model")
	structurePart(model, plot, {
		Name = "Slab2",
		Size = Vector3.new(60, 1, 27),
		Color = Theme.Palette.BunTan,
		CFrame = CFrame.new(0, 13, -5.5),
	})
	-- Railings are JUMPABLE by design (rule 2) — they slow a thief, never stop one.
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(60, 2.5, 0.5),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(0, 14.75, 8),
	})
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(60, 2.5, 0.5),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(0, 14.75, -19),
	})
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(0.5, 2.5, 26),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(29.75, 14.75, -5.5),
	})
	-- West rail split: 6-stud stair opening z ∈ [-18,-12] (the stairs2 landing).
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(0.5, 2.5, 1),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(-29.75, 14.75, -18.5),
	})
	structurePart(model, plot, {
		Name = "Rail",
		Size = Vector3.new(0.5, 2.5, 20),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(-29.75, 14.75, -2),
	})
	for _, sx in { -4, 4 } do
		local pedestal = structurePart(model, plot, {
			Name = "FloorPedestal",
			Size = Vector3.new(2, 2, 2),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 14.5, -2),
		})
		pedestal:SetAttribute("PlotFloor", 2)
	end
	return model
end

BUILDERS.stairs2 = function(plot: Plot): Model
	local model = Instance.new("Model")
	-- Outdoor west-side stairs up to the floor-2 rail opening. CanCollide=true —
	-- thieves climb them too (rule 2).
	for i = 1, 12 do
		structurePart(model, plot, {
			Name = "Step",
			Size = Vector3.new(4, 1, 2.2),
			Color = Theme.Palette.CharBrown,
			CFrame = CFrame.new(-33, i, 10 - (i - 1) * 2.1),
		})
	end
	structurePart(model, plot, {
		Name = "Landing",
		Size = Vector3.new(5, 1, 4),
		Color = Theme.Palette.CharBrown,
		CFrame = CFrame.new(-33, 13, -15.5),
	})
	return model
end

BUILDERS.wall = function(plot: Plot): Model
	-- Perimeter fence. The 16-stud front opening (x ∈ [-8,8]) is PERMANENT (rule 1):
	-- walls buy hold-time (WallHoldBonusSeconds), they never seal the plot. (The #4
	-- Security Field is the deliberate, telegraphed exception layered ON this line.)
	-- Sized from the config footprint so it hugs the pad edge.
	local model = Instance.new("Model")
	local w = GameConfig.PlotPadWidth -- 76
	local d = GameConfig.PlotPadDepth -- 58
	structurePart(model, plot, {
		Name = "WallBack",
		Size = Vector3.new(w, 6, 1),
		Color = Theme.Palette.Cream,
		CFrame = CFrame.new(0, 3, -(d / 2 - 0.5)),
	})
	for _, sx in { -(w / 2 - 0.5), w / 2 - 0.5 } do
		structurePart(model, plot, {
			Name = "WallSide",
			Size = Vector3.new(1, 6, d - 2),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 3, 0),
		})
	end
	local frontSeg = (w - 16) / 2 -- each side of the permanent gap
	for _, sx in { -(8 + frontSeg / 2), 8 + frontSeg / 2 } do
		structurePart(model, plot, {
			Name = "WallFront",
			Size = Vector3.new(frontSeg, 6, 1),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 3, d / 2 - 0.5),
		})
	end
	return model
end

BUILDERS.floor3 = function(plot: Plot): Model
	-- Slab at y=26 (floor 2 gets 12.5 studs of headroom under it).
	local model = Instance.new("Model")
	for _, sx in { -29, 29 } do
		for _, sz in { 8, -19 } do
			structurePart(model, plot, {
				Name = "Post3",
				Size = Vector3.new(1.5, 12, 1.5),
				Color = Theme.Palette.CharBrown,
				CFrame = CFrame.new(sx, 19.5, sz),
			})
		end
	end
	structurePart(model, plot, {
		Name = "Slab3",
		Size = Vector3.new(60, 1, 27),
		Color = Theme.Palette.BunTan,
		CFrame = CFrame.new(0, 26, -5.5),
	})
	-- Parapets, with a 4-stud gap in the east rail at z=-14 where the truss lands.
	structurePart(model, plot, {
		Name = "Parapet",
		Size = Vector3.new(60, 2.5, 0.5),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(0, 27.75, 8),
	})
	structurePart(model, plot, {
		Name = "Parapet",
		Size = Vector3.new(60, 2.5, 0.5),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(0, 27.75, -19),
	})
	structurePart(model, plot, {
		Name = "Parapet",
		Size = Vector3.new(0.5, 2.5, 26),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(-29.75, 27.75, -5.5),
	})
	structurePart(model, plot, {
		Name = "Parapet",
		Size = Vector3.new(0.5, 2.5, 3),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(29.75, 27.75, -17.5),
	})
	structurePart(model, plot, {
		Name = "Parapet",
		Size = Vector3.new(0.5, 2.5, 20),
		Color = Theme.Palette.Mustard,
		CFrame = CFrame.new(29.75, 27.75, -2),
	})
	-- Climbable truss, ground → east rail gap: floor 3's THEFT-ACCESS GUARANTEE
	-- (rule 2). Ships in the same model so the floor can never exist without it.
	local truss = Instance.new("TrussPart")
	truss.Anchored = true
	truss.Size = Vector3.new(2, 27, 2)
	truss.Color = Theme.Palette.CharBrown
	truss.CFrame = plot.facing * CFrame.new(31.5, 13.5, -14)
	truss.Parent = model
	for _, sx in { 0, -6, 6 } do
		local pedestal = structurePart(model, plot, {
			Name = "FloorPedestal",
			Size = Vector3.new(2, 2, 2),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 27.5, -2),
		})
		pedestal:SetAttribute("PlotFloor", 3)
	end
	return model
end

BUILDERS.gate = function(plot: Plot): Model
	local model = Instance.new("Model")
	local gateZ = GameConfig.PlotPadDepth / 2 - 0.5 -- sits in the wall's front gap
	for _, sx in { -8, 8 } do
		structurePart(model, plot, {
			Name = "GatePost",
			Size = Vector3.new(1.5, 7, 1.5),
			Color = Theme.Palette.Ketchup,
			CFrame = CFrame.new(sx, 3.5, gateZ),
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
			CFrame = CFrame.new(-6.9 + (i - 1) * 2.3, 4.5, gateZ),
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
	for _, sz in { 4, 7 } do
		structurePart(model, plot, {
			Name = "ElevatorPole",
			Size = Vector3.new(1, 27, 1),
			Color = Theme.Palette.CharBrown,
			CFrame = CFrame.new(29, 13.5, sz),
		})
	end
	local pads: { BasePart } = {}
	for _, sy in { 1.05, 27.25 } do
		local padPart = structurePart(model, plot, {
			Name = "ElevatorPad",
			Size = Vector3.new(4, 0.5, 4),
			Color = Theme.Palette.Mustard,
			CFrame = CFrame.new(27, sy, 5.5),
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
	for sx = -24, 24, 12 do
		stripeIndex += 1
		structurePart(model, plot, {
			Name = "AwningStripe",
			Size = Vector3.new(12, 0.6, 7),
			Color = if stripeIndex % 2 == 1 then Theme.Palette.Ketchup else Theme.Palette.Cream,
			CanCollide = false,
			CFrame = CFrame.new(sx, 11.5, 10.8) * CFrame.Angles(math.rad(-18), 0, 0),
		})
	end
	return model
end

BUILDERS.planters = function(plot: Plot): Model
	local model = Instance.new("Model")
	for _, sx in { -11, 11 } do
		structurePart(model, plot, {
			Name = "PlanterBox",
			Size = Vector3.new(6, 1.5, 2),
			Color = Theme.Palette.CharBrown,
			CFrame = CFrame.new(sx, 1.25, 10.5),
		})
		for _, dx in { -1.8, 0, 1.8 } do
			structurePart(model, plot, {
				Name = "Bush",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.6, 1.6, 1.6),
				Color = Theme.Palette.Relish,
				CanCollide = false,
				CastShadow = false,
				CFrame = CFrame.new(sx + dx, 2.6, 10.5),
			})
		end
		structurePart(model, plot, {
			Name = "Tomato",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.9, 0.9, 0.9),
			Color = Theme.Palette.Ketchup,
			CanCollide = false,
			CastShadow = false,
			CFrame = CFrame.new(sx + 2.2, 2.3, 10.9),
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
		CFrame = CFrame.new(0, 15.5, 9.3),
	})
	structurePart(model, plot, {
		Name = "SignBun",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 1.8, 1.8),
		Color = Theme.Palette.BunTan,
		CanCollide = false,
		CFrame = CFrame.new(0, 15.2, 10),
	})
	structurePart(model, plot, {
		Name = "SignSausage",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6.4, 1.1, 1.1),
		Color = Theme.Palette.Ketchup,
		-- Matte body; the thin mustard drizzle below stays Neon — a small accent
		-- reads as "lit sign" without floodlighting the roofline.
		CanCollide = false,
		CFrame = CFrame.new(0, 15.75, 10),
	})
	structurePart(model, plot, {
		Name = "SignDrizzle",
		Size = Vector3.new(4, 0.25, 0.25),
		Color = Theme.Palette.Mustard,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
		CFrame = CFrame.new(0, 16.35, 10),
	})
	return model
end

BUILDERS.window2 = function(plot: Plot): Model
	local model = Instance.new("Model")
	for _, sx in { -16, 16 } do
		structurePart(model, plot, {
			Name = "WindowPanel",
			Size = Vector3.new(18, 6, 1),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 17.5, 8),
		})
		for _, dx in { -4, 4 } do
			structurePart(model, plot, {
				Name = "WindowGlass",
				Size = Vector3.new(5, 3.5, 1.2),
				Color = Theme.Palette.SkyBlue,
				Material = Enum.Material.Glass,
				Transparency = Theme.WindowTransparency,
				CanCollide = false,
				CFrame = CFrame.new(sx + dx, 17.5, 8),
			})
			structurePart(model, plot, {
				Name = "WindowSill",
				Size = Vector3.new(5.5, 0.5, 1.4),
				Color = Theme.Palette.Mustard,
				CanCollide = false,
				CastShadow = false,
				CFrame = CFrame.new(sx + dx, 15.4, 8),
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
	for _, sideX in { -29, 29 } do
		local from = Vector3.new(sideX, 12.5, 8)
		local to = Vector3.new(0, 15, 9.8)
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
	-- 10×4 checkerboard laid over the interior floor. Pure decor: CanCollide=false.
	local model = Instance.new("Model")
	for col = 1, 10 do
		for row = 1, 4 do
			structurePart(model, plot, {
				Name = "Tile",
				Size = Vector3.new(5.5, 0.2, 5.5),
				Color = if (col + row) % 2 == 0 then Theme.Palette.Ketchup else Theme.Palette.Cream,
				CanCollide = false,
				CFrame = CFrame.new((col - 5.5) * 5.6, 0.6, (row - 2.5) * 5.6 - 5.5),
			})
		end
	end
	return model
end

BUILDERS.window3 = function(plot: Plot): Model
	-- Mirrors window2 one floor up.
	local model = Instance.new("Model")
	for _, sx in { -16, 16 } do
		structurePart(model, plot, {
			Name = "WindowPanel",
			Size = Vector3.new(18, 6, 1),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 30.5, 8),
		})
		for _, dx in { -4, 4 } do
			structurePart(model, plot, {
				Name = "WindowGlass",
				Size = Vector3.new(5, 3.5, 1.2),
				Color = Theme.Palette.SkyBlue,
				Material = Enum.Material.Glass,
				Transparency = Theme.WindowTransparency,
				CanCollide = false,
				CFrame = CFrame.new(sx + dx, 30.5, 8),
			})
			structurePart(model, plot, {
				Name = "WindowSill",
				Size = Vector3.new(5.5, 0.5, 1.4),
				Color = Theme.Palette.Mustard,
				CanCollide = false,
				CastShadow = false,
				CFrame = CFrame.new(sx + dx, 28.4, 8),
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
		CFrame = CFrame.new(32, 3.5, 18),
	})
	local upright = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis X → Y
	structurePart(model, plot, {
		Name = "CanopyBig",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 8, 8),
		Color = Theme.Palette.Ketchup,
		CanCollide = false,
		CFrame = CFrame.new(32, 6.4, 18) * upright,
	})
	structurePart(model, plot, {
		Name = "CanopySmall",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 5, 5),
		Color = Theme.Palette.Mustard,
		CanCollide = false,
		CFrame = CFrame.new(32, 7, 18) * upright,
	})
	structurePart(model, plot, {
		Name = "Table",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 4, 4),
		Color = Theme.Palette.Cream,
		CFrame = CFrame.new(32, 2.6, 18) * upright,
	})
	for _, sx in { 29.5, 34.5 } do
		structurePart(model, plot, {
			Name = "Stool",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, 1.6, 1.6),
			Color = Theme.Palette.Cream,
			CFrame = CFrame.new(sx, 1.1, 18) * upright,
		})
	end
	return model
end

BUILDERS.rooftop = function(plot: Plot): Model
	-- The floor-3 capstone gag: a giant glizzy statue ON THE ROOF (the #15 roof sits
	-- at y=39 whenever floor3 exists, and rooftop's prereq is floor3).
	local model = Instance.new("Model")
	structurePart(model, plot, {
		Name = "WienerMount",
		Size = Vector3.new(3, 1.5, 3),
		Color = Theme.Palette.CharBrown,
		CFrame = CFrame.new(0, 40.25, -5.5),
	})
	local wiener = GlizzyModel.build("Plain Dog", {
		rarity = "Common",
		scale = 4,
		anchored = true,
		fx = false,
	})
	-- Not "DogUnit": nothing should ever try to steal or fx-track the statue.
	wiener.Name = "RooftopWiener"
	wiener:PivotTo(plot.facing * CFrame.new(0, 42.8, -5.5) * CFrame.Angles(0, 0, math.rad(8)))
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
	-- The roof rides above the topmost floor — recompute whenever a floor lands.
	if entry.id == "floor2" or entry.id == "floor3" then
		applyRoofTo(plot.model, plot.facing, plot.structures)
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
	applyRoofTo(plot.model, plot.facing, plot.structures) -- roof drops back to the shell
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
-- Display (stealable) units render enlarged — they're the storefront merchandise;
-- vault copies stay compact on the shelf. Giant multiplies on top.
local DISPLAY_SCALE = 1.8
local function spawnUnit(plot: Plot, anchor: BasePart, dog: HotDogDex.Unit, stealable: boolean)
	local scale = (if stealable then DISPLAY_SCALE else 1)
		* (if dog.variant == "Giant" then 1.5 else 1)
	local unit = GlizzyModel.build(dog.name, {
		rarity = dog.rarity,
		variant = dog.variant,
		scale = scale,
		anchored = true,
		fx = stealable,
	})
	unit:SetAttribute("DogName", dog.name)
	unit:SetAttribute("DogKey", dog.key)
	-- Rest the dog on the anchor's top face whatever the anchor's height: half the
	-- anchor + half the glizzy (1.15 tall at scale 1) + a whisker of air.
	local lift = anchor.Size.Y / 2 + (1.15 * scale) / 2 + 0.05
	unit:PivotTo(anchor.CFrame * CFrame.new(0, lift, 0))
	local primary = unit.PrimaryPart :: BasePart

	makeUnitPlate(primary, dog, 1.2 + 0.9 * scale)
	unit.Parent = anchor

	if stealable then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StealPrompt"
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

		-- Owner pickup: hold your own glizzy in hand (PickupService owns the rules).
		-- F (not E) so it can never key-clash with Steal; the server re-checks the
		-- owner, and PlotPresentation hides this prompt on stands you don't own.
		-- DISPLAY units only (deliberate): picking from the vault would free a slot
		-- that auto-fills with your best displayed dog — a quiet shelter trick.
		local pickup = Instance.new("ProximityPrompt")
		pickup.Name = "PickupPrompt"
		pickup.ActionText = "Pick Up"
		pickup.ObjectText = dog.displayName
		pickup.KeyboardKeyCode = Enum.KeyCode.F
		pickup.HoldDuration = 0.25
		pickup.MaxActivationDistance = 8
		pickup.RequiresLineOfSight = false
		pickup.Parent = primary
		pickup.Triggered:Connect(function(picker: Player)
			if plot.owner == picker and pickupHandler then
				pickupHandler(picker, dog.key)
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
	-- Extra-slots pass derives at read time from data.passes (refund-safe).
	local passBonus = if data.passes.extraSlots then GameConfig.ExtraSlotsPassVault else 0
	return def.slots + data.bonusVaultSlots + passBonus
end

local function displayCapacity(data: DataManager.PlayerData): number
	local levels = GameConfig.DisplaySlotLevels
	local def = levels[data.displaySlotsLvl] or levels[#levels]
	-- Built floors + the zone tier add slots (derived at read time from data.built /
	-- data.zoneLvl — never banked — so rebuild-on-join can't double-apply).
	local zoneTier = GameConfig.ZoneTiers[data.zoneLvl]
	local zoneBonus = zoneTier and zoneTier.extraSlots or 0
	local passBonus = if data.passes.extraSlots then GameConfig.ExtraSlotsPassDisplay else 0
	return def.slots
		+ data.bonusDisplaySlots
		+ BuildGrants.displaySlotBonus(data.built)
		+ zoneBonus
		+ passBonus
end

-- One inventory key per player currently "in hand" (PickupService). syncDisplay
-- skips one count of it so the stand reflects what left with the owner.
local heldKeys: { [number]: string } = {}
function PlotManager.setHeldKey(player: Player, key: string?)
	heldKeys[player.UserId] = key
	PlotManager.syncDisplay(player)
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
	-- Manual vault selection (M2 fast-follow): pinned keys claim vault slots FIRST
	-- (in value order — sortedUnits is income-descending), then the vault tops up
	-- with the best unpinned units; everything left overflows to the pedestals.
	local units = HotDogDex.sortedUnits(data.hotDogs)
	-- One copy of the held key is riding in the owner's HAND (PickupService) —
	-- leave that one off the stand so the hand copy isn't also displayed.
	local heldKey = heldKeys[player.UserId]
	if heldKey then
		for i, unit in units do
			if unit.key == heldKey then
				table.remove(units, i)
				break
			end
		end
	end
	local vaultUnits: { HotDogDex.Unit } = {}
	local overflow: { HotDogDex.Unit } = {}
	for _, unit in units do
		if data.vaultPins[unit.key] and #vaultUnits < vaultCap then
			table.insert(vaultUnits, unit)
		else
			table.insert(overflow, unit)
		end
	end
	while #vaultUnits < vaultCap and #overflow > 0 do
		table.insert(vaultUnits, table.remove(overflow, 1) :: HotDogDex.Unit)
	end
	for i, unit in vaultUnits do
		local anchor = plot.vaultAnchors[i]
		if anchor then
			spawnUnit(plot, anchor, unit, false)
		end
	end
	-- Rarity auto-sort (additions #6): the best overflow dogs go HIGH. Anchors are
	-- ordered floor DESC (3 → 2 → ground; the PlotFloor attribute set at build time),
	-- stable by build order within a floor — so floor 3's pedestals hold the top
	-- units, floor 2 the next, and the ground floor the rest. Height = defense value:
	-- thieves pay climb time for the good stuff. (Vault pins above still win first.)
	local anchorIndex: { [BasePart]: number } = {}
	for i, anchor in plot.pedestalAnchors do
		anchorIndex[anchor] = i
	end
	local orderedAnchors = table.clone(plot.pedestalAnchors)
	table.sort(orderedAnchors, function(a, b)
		local fa = (a:GetAttribute("PlotFloor") :: number?) or 1
		local fb = (b:GetAttribute("PlotFloor") :: number?) or 1
		if fa ~= fb then
			return fa > fb
		end
		return (anchorIndex[a] or 0) < (anchorIndex[b] or 0)
	end)
	-- The next `displayCap` overflow units -> stealable pedestals (best-first onto
	-- the highest floors); the rest are "in storage" (not shown).
	for i, unit in overflow do
		if i > displayCap then
			break
		end
		local anchor = orderedAnchors[i]
		if anchor then
			spawnUnit(plot, anchor, unit, true)
		else
			break
		end
	end
end

-- Storage-fullness snapshot for the HUD (additions #9): how many display pedestals
-- and vault shelves are filled vs the player's current capacity. Mirrors syncDisplay's
-- fill math (vault always tops up to capacity first; one held copy excluded) without
-- touching instances. Pins only choose WHICH dogs sit in the vault, never how many.
function PlotManager.getStorageInfo(player: Player): {
	shown: number,
	displayCap: number,
	vaultUsed: number,
	vaultCap: number,
}?
	local data = DataManager.get(player)
	if not data then
		return nil
	end
	local vaultCap = vaultCapacity(data)
	local displayCap = displayCapacity(data)
	local total = 0
	for _, count in data.hotDogs do
		total += count
	end
	if heldKeys[player.UserId] then
		total = math.max(0, total - 1)
	end
	local vaultUsed = math.min(total, vaultCap)
	local shown = math.min(total - vaultUsed, displayCap)
	return { shown = shown, displayCap = displayCap, vaultUsed = vaultUsed, vaultCap = vaultCap }
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

-- Cosmetic NPC chef (additions #1): static anchored parts (no Humanoid exists in this
-- game) "working" the stove via synced looping tweens on the flip arm + spatula.
-- Lives inside the stove model so it appears/disappears with the stove.
local function buildChef(parent: Model, facing: CFrame)
	local chef = Instance.new("Model")
	chef.Name = "Chef"
	local function chefPart(props: { [string]: any }): BasePart
		local part = makePart(props)
		part.CFrame = facing * (props.CFrame :: CFrame)
		part.Parent = chef
		return part
	end
	chefPart({
		Name = "ChefLegs",
		Size = Vector3.new(1.8, 2, 1),
		Color = Theme.Palette.CharBrown,
		CFrame = CFrame.new(-19, 1, 17),
	})
	chefPart({
		Name = "ChefTorso",
		Size = Vector3.new(2.2, 2.4, 1.2),
		Color = Theme.Palette.Cream,
		CFrame = CFrame.new(-19, 3.2, 17),
	})
	-- Apron faces the stove (the chef looks away from the street, at his burgers).
	chefPart({
		Name = "ChefApron",
		Size = Vector3.new(1.6, 2, 0.3),
		Color = Theme.Palette.Ketchup,
		CFrame = CFrame.new(-19, 3, 16.3),
	})
	chefPart({
		Name = "ChefHead",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.6, 1.6, 1.6),
		Color = Color3.fromRGB(240, 210, 170),
		CFrame = CFrame.new(-19, 5.1, 17),
	})
	chefPart({
		Name = "ChefHat",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.4, 1.5, 1.5),
		Color = Color3.fromRGB(250, 250, 250),
		CFrame = CFrame.new(-19, 6.2, 17) * CFrame.Angles(0, 0, math.rad(90)),
	})
	chefPart({
		Name = "ChefArm",
		Size = Vector3.new(0.7, 2, 0.7),
		Color = Theme.Palette.Cream,
		CFrame = CFrame.new(-20.4, 3.4, 17),
	})
	-- The working arm: pivots at the shoulder between "resting over the stove" and
	-- "flip!", spatula riding along (two synced tweens — anchored parts, no physics).
	local shoulder = facing * CFrame.new(-17.6, 4.4, 16.9)
	local armDown = shoulder * CFrame.Angles(math.rad(20), 0, 0) * CFrame.new(0, -1, 0)
	local armUp = shoulder * CFrame.Angles(math.rad(-55), 0, 0) * CFrame.new(0, -1, 0)
	local spatOffset = CFrame.new(0, -1.4, -0.3) * CFrame.Angles(math.rad(80), 0, 0)
	local arm = makePart({
		Name = "ChefFlipArm",
		Size = Vector3.new(0.7, 2, 0.7),
		Color = Theme.Palette.Cream,
		CFrame = armDown,
	})
	arm.Parent = chef
	local spatula = makePart({
		Name = "ChefSpatula",
		Size = Vector3.new(0.9, 1.6, 0.25),
		Color = Theme.Palette.Steel,
		CFrame = armDown * spatOffset,
	})
	spatula.Parent = chef
	local info =
		TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0.5)
	TweenService:Create(arm, info, { CFrame = armUp }):Play()
	TweenService:Create(spatula, info, { CFrame = armUp * spatOffset }):Play()
	chef.Parent = parent
end

-- Create / update / remove the physical stove on the owner's plot. `level` 0 removes it;
-- >=1 shows a stove labelled with its tier + coins/sec (the passive income machine).
-- Additions #2/#10: reads as a real range (burners / oven door / handle) and steps up
-- per tier band — 1 (Lv1-3): single ketchup range · 2 (Lv4-5): double-wide · 3 (Lv6+):
-- industrial steel with a vent stack. The chef (#1) works whichever stove stands.
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
	local band = if level >= 6 then 3 elseif level >= 4 then 2 else 1
	local model = plot.stoveModel
	if model and model:GetAttribute("Band") ~= band then
		model:Destroy()
		model = nil
		plot.stoveModel = nil
	end
	if not model then
		local m = Instance.new("Model")
		m.Name = "Stove"
		m:SetAttribute("Band", band)
		local width = if band >= 2 then 8 else 5
		local bodyColor = if band == 3 then Theme.Palette.Steel else Theme.Palette.Ketchup
		local body = makePart({
			Name = "StoveBody",
			Size = Vector3.new(width, 3, 4),
			Color = bodyColor,
			Material = Enum.Material.Metal,
			CanCollide = true,
			CFrame = plot.facing * CFrame.new(-19, 1.5, 14),
		})
		body.Parent = m
		-- Burner rings on the cooktop (4 on the single range, 6 on wider bands).
		local burnerXs = if band >= 2 then { -2.8, 0, 2.8 } else { -1.2, 1.2 }
		for _, bx in burnerXs do
			for _, bz in { -1.1, 1.1 } do
				local burner = makePart({
					Name = "StoveBurner",
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(0.25, 1.5, 1.5),
					Color = Theme.Palette.CharBrown,
					CastShadow = false,
					CFrame = plot.facing
						* CFrame.new(-19 + bx, 3.15, 14 + bz)
						* CFrame.Angles(0, 0, math.rad(90)),
				})
				burner.Parent = m
			end
		end
		-- Oven door + handle on the street face.
		local door = makePart({
			Name = "StoveDoor",
			Size = Vector3.new(width - 1.4, 1.8, 0.25),
			Color = Theme.Palette.CharBrown,
			CFrame = plot.facing * CFrame.new(-19, 1.1, 16.1),
		})
		door.Parent = m
		local handle = makePart({
			Name = "StoveHandle",
			Size = Vector3.new(width - 2.4, 0.2, 0.2),
			Color = Theme.Palette.Cream,
			CastShadow = false,
			CFrame = plot.facing * CFrame.new(-19, 1.9, 16.3),
		})
		handle.Parent = m
		if band == 3 then
			local vent = makePart({
				Name = "StoveVent",
				Size = Vector3.new(1.2, 6, 1.2),
				Color = Theme.Palette.Steel,
				Material = Enum.Material.Metal,
				CFrame = plot.facing * CFrame.new(-21.5, 6, 12.8),
			})
			vent.Parent = m
		end
		-- A wisp of griddle smoke (tiny budget: one low-rate emitter per stove).
		local smoke = Instance.new("ParticleEmitter")
		smoke.Rate = 0.8
		smoke.Lifetime = NumberRange.new(1, 1.6)
		smoke.Speed = NumberRange.new(1, 1.5)
		smoke.Size = NumberSequence.new(0.5, 1.4)
		smoke.Transparency = NumberSequence.new(0.5, 1)
		smoke.Color = ColorSequence.new(Color3.fromRGB(230, 230, 230))
		smoke.Parent = body
		makeBillboard(body, "", Color3.fromRGB(255, 200, 120), 22, "StoveLabel", {
			width = 110,
			maxDistance = 50,
			offsetY = 3.2,
		})
		buildChef(m, plot.facing)
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
		local shownText = Format.comma(shown, if shown % 1 == 0 then 0 else 1)
		local tier = GameConfig.AutoCookerTiers[level]
		local tierName = if tier then tier.name else "Stove"
		label.Text = "🔥 " .. tierName .. " Lv " .. level .. "  (+" .. shownText .. "/s)"
	end
end

-- Feed the physical drop-rates board beside the grill (additions #16). Main builds
-- the lines (per-rarity odds for the owner's grill level + the pity counter) and
-- pushes them on join / grill upgrade / cook.
function PlotManager.setOddsSign(player: Player, text: string)
	local plot = ownerToPlot[player.UserId]
	if plot then
		plot.oddsText.Text = text
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

-- Resize the plot's ground pad for a zone tier (Phase 5). Cosmetic footprint flex —
-- the capacity half of the grant is derived in displayCapacity, never banked here.
-- At the top tier (×1.5 on a 96-stud pitch) pads keep a ≥6-stud gap to neighbours.
function PlotManager.applyZone(player: Player, mult: number)
	local plot = ownerToPlot[player.UserId]
	if not plot then
		return
	end
	local pad = plot.model:FindFirstChild("Pad")
	if pad and pad:IsA("BasePart") then
		pad.Size = Vector3.new(GameConfig.PlotPadWidth * mult, 1, GameConfig.PlotPadDepth * mult)
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
	-- Undo any zone expansion for the next tenant.
	local basePad = plot.model:FindFirstChild("Pad")
	if basePad and basePad:IsA("BasePart") then
		basePad.Size = Vector3.new(GameConfig.PlotPadWidth, 1, GameConfig.PlotPadDepth)
	end
	plot.signText.Text = "Empty Plot"
	plot.oddsText.Text = ""
	plot.model:SetAttribute("OwnerUserId", nil)
	plot.owner = nil
	heldKeys[player.UserId] = nil -- defensive; PickupService also clears on leave
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
	return plot.facing * CFrame.new(0, 5, 16) * CFrame.Angles(0, math.pi, 0)
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
