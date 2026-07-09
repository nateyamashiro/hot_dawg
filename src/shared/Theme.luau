--!strict
-- The design system for "Steal a Glizzy" (design plan Part 1). Zero-dependency token
-- module BOTH sides read: world palette, semantic state colors, material + form
-- language, the lighting recipe (applied by EnvironmentService), UI tokens (applied
-- at the P-D window migration), and the VFX vocabulary + restraint budgets.
--
-- Single-source-of-truth boundaries (deliberate — do NOT duplicate here):
--   * Rarity colors live in HotDogDex.RARITY.
--   * Variant (mutation) colors live in Variants.DEFS.
-- Theme owns everything else: the world is painted from Theme.Palette, gameplay
-- states from Theme.Semantic, panels/buttons from Theme.UI.
--
-- Art north star (GDD §4.12 + locked decision #1): low-poly bright cartoon —
-- chunky proportions, flat saturated colors, color-is-the-art (no textures).

local TweenService = game:GetService("TweenService")

local Theme = {}

----------------------------------------------------------------------------------------------------
-- 1.1 World palette — the ketchup-and-mustard world. Every structure/prop color
-- comes from here so the whole map reads as one place.
----------------------------------------------------------------------------------------------------

Theme.Palette = {
	Ketchup = Color3.fromRGB(215, 58, 46), -- primary red: awning stripes, stove body, UI title bars
	KetchupDark = Color3.fromRGB(170, 40, 34), -- red shadow/trim, UI gradient bottom
	Mustard = Color3.fromRGB(245, 190, 46), -- primary yellow: railings, counter trim, road dashes, buttons
	MustardDark = Color3.fromRGB(206, 148, 24), -- yellow trim
	BunTan = Color3.fromRGB(232, 184, 122), -- glizzy buns, floor slabs
	BunCrust = Color3.fromRGB(198, 140, 82), -- slab edges, warm accents
	Cream = Color3.fromRGB(255, 244, 222), -- walls, counters, pedestals, UI panel bg
	CharBrown = Color3.fromRGB(94, 62, 40), -- posts, stairs, planters, sign post, UI outlines/text
	WoodWarm = Color3.fromRGB(146, 104, 66), -- plot floor pad
	SausageBrown = Color3.fromRGB(178, 92, 56), -- glizzy sausage base
	Relish = Color3.fromRGB(122, 194, 66), -- bushes, green accents
	Grass = Color3.fromRGB(106, 192, 92), -- ground slab
	Asphalt = Color3.fromRGB(99, 102, 110), -- street
	Sidewalk = Color3.fromRGB(188, 186, 178), -- sidewalk strips
	SkyBlue = Color3.fromRGB(140, 202, 255), -- window glass tint, flag accents
	Steel = Color3.fromRGB(84, 76, 70), -- machine bodies (cook station)
	VaultGold = Color3.fromRGB(210, 180, 40), -- vault cubes (existing color, kept)
	White = Color3.fromRGB(255, 250, 245), -- highlights, text on red
}

----------------------------------------------------------------------------------------------------
-- 1.2 Semantic colors — gameplay STATES, not decoration. Values match what already
-- shipped (pad green/red, owner highlight) so migrating to these is a no-op visually.
----------------------------------------------------------------------------------------------------

Theme.Semantic = {
	Affordable = Color3.fromRGB(90, 200, 90), -- walk-on pad you CAN buy (was PlotManager PAD_GREEN)
	Expensive = Color3.fromRGB(200, 75, 75), -- walk-on pad you can't afford yet (was PAD_RED)
	Danger = Color3.fromRGB(255, 70, 60), -- thief/alarm red
	Owner = Color3.fromRGB(90, 210, 120), -- "this is YOURS" highlight (shipped owner highlight)
	CoinGold = Color3.fromRGB(255, 200, 60), -- coin feedback / milestone sparkle
	Deposit = Color3.fromRGB(60, 160, 90), -- deposit zone green
}

----------------------------------------------------------------------------------------------------
-- 1.3 Materials + form language. Material carries MEANING: if it glows you can step
-- on/interact with it; if it's metal it's a machine; everything else is structure.
--
-- CHUNK RULES (the low-poly cartoon read — enforce when building parts):
--   * No part thinner than 0.5 studs. Sole exception: walk-on pads at 0.4.
--   * Posts >= 1.5 x 1.5; roofs/awnings overhang their support by >= 1 stud.
--   * Max 3 base colors + 1 accent color per structure.
--   * Boxes and cylinders only — silhouettes stay chunky and readable.
--   * CastShadow = false on any part smaller than 2 studs in every axis.
----------------------------------------------------------------------------------------------------

Theme.Materials = {
	Structure = Enum.Material.SmoothPlastic, -- default everything
	Machine = Enum.Material.Metal, -- stove / cook-station bodies only
	-- Interactive surfaces read through bright SEMANTIC COLORS, not emissive glow —
	-- a world full of Neon at noon is an eyesore. Neon is reserved for SMALL accents
	-- and gameplay signals only (rarity drizzle, rooftop sign drizzle, trap warning,
	-- blaster toys); anything big or decorative stays matte.
	Interactive = Enum.Material.SmoothPlastic,
	Window = Enum.Material.Glass, -- with Theme.WindowTransparency
}
Theme.WindowTransparency = 0.4

----------------------------------------------------------------------------------------------------
-- 1.4 Lighting recipe — bright cartoon noon. EnvironmentService applies this whole
-- table (Lighting props + Atmosphere/Bloom/ColorCorrection/SunRays children + Terrain
-- Clouds). NOTE: Lighting.Technology is NOT scriptable at runtime — set ShadowMap in
-- Studio; EnvironmentService should pcall/skip it and treat this entry as documentation.
----------------------------------------------------------------------------------------------------

Theme.Lighting = {
	Technology = Enum.Technology.ShadowMap, -- mobile-friendly (Studio-set; see note above)
	ClockTime = 13.5,
	GeographicLatitude = 21,
	Brightness = 3,
	ShadowSoftness = 0.9,
	Ambient = Color3.fromRGB(140, 140, 150),
	OutdoorAmbient = Color3.fromRGB(165, 170, 185),
	ColorShift_Top = Color3.fromRGB(255, 240, 215),
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 0.25,

	Atmosphere = {
		Density = 0.25,
		Offset = 0.6,
		Color = Color3.fromRGB(204, 224, 255),
		Decay = Color3.fromRGB(110, 140, 200),
		Glare = 0.2,
		Haze = 1.2,
	},
	-- Soft bloom: high threshold so only genuinely bright spots glow — bloom is the
	-- multiplier that turned every Neon surface into an eyesore at noon.
	Bloom = {
		Intensity = 0.25,
		Size = 14,
		Threshold = 1.6,
	},
	ColorCorrection = {
		Saturation = 0.15,
		Contrast = 0.05,
		TintColor = Color3.fromRGB(255, 252, 245),
	},
	SunRays = {
		Intensity = 0.08,
		Spread = 0.6,
	},
	Clouds = { -- parented to workspace.Terrain
		Cover = 0.4,
		Density = 0.6,
		Color = Color3.fromRGB(255, 255, 255),
	},
}

----------------------------------------------------------------------------------------------------
-- 1.5 UI tokens — the sticker-bomb evolution. Defined NOW so new UI can consume them;
-- the existing panels migrate at P-D (makeWindow migration), not before (locked #6).
----------------------------------------------------------------------------------------------------

local BODY_TEXT = Color3.fromRGB(74, 52, 34)

Theme.UI = {
	PanelBg = Theme.Palette.Cream,
	TitleBar = Theme.Palette.Ketchup, -- with a vertical UIGradient down to TitleBarBottom
	TitleBarBottom = Theme.Palette.KetchupDark,
	TitleText = Theme.Palette.White,
	BodyText = BODY_TEXT,
	RowBg = Color3.fromRGB(255, 236, 200),

	-- Buttons: Primary = mustard, Success = relish, Danger = ketchup.
	ButtonPrimary = Theme.Palette.Mustard,
	ButtonPrimaryText = BODY_TEXT,
	ButtonSuccess = Theme.Palette.Relish,
	ButtonSuccessText = BODY_TEXT,
	ButtonDanger = Theme.Palette.Ketchup,
	ButtonDangerText = Theme.Palette.White,

	-- UICorner radii (px) + the chunky cartoon outline on EVERY panel and button.
	CornerPanel = 12,
	CornerButton = 10,
	StrokeThickness = 3,
	StrokeColor = BODY_TEXT, -- UIStroke ApplyStrokeMode.Border

	TitleFont = Enum.Font.FredokaOne, -- titles + buttons
	BodyFont = Enum.Font.GothamMedium,
	NumberFont = Enum.Font.GothamBold,
}

-- Motion specs shared by the helpers below (hover 1.05, press 0.92, release/back 1.0).
local HOVER_TWEEN = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS_TWEEN = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function ensureScale(gui: GuiObject): UIScale
	local scale = gui:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = gui
	end
	return scale :: UIScale
end

local function tweenScale(scale: UIScale, info: TweenInfo, target: number)
	TweenService:Create(scale, info, { Scale = target }):Play()
end

-- Give a button the cartoon bounce: hover 1.05, press 0.92, release back to 1.0
-- with overshoot. CLIENT-ONLY (hooks input events); safe to call once per button.
function Theme.applyBounce(button: GuiButton)
	local scale = ensureScale(button)
	button.MouseEnter:Connect(function()
		tweenScale(scale, HOVER_TWEEN, 1.05)
	end)
	button.MouseLeave:Connect(function()
		tweenScale(scale, RELEASE_TWEEN, 1)
	end)
	button.MouseButton1Down:Connect(function()
		tweenScale(scale, PRESS_TWEEN, 0.92)
	end)
	button.MouseButton1Up:Connect(function()
		tweenScale(scale, RELEASE_TWEEN, 1)
	end)
end

-- Window-open pop: 0.85 -> 1.0 with Back/Out overshoot. Call each time a window
-- becomes visible. CLIENT-ONLY.
function Theme.popOpen(window: GuiObject)
	local scale = ensureScale(window)
	scale.Scale = 0.85
	tweenScale(scale, RELEASE_TWEEN, 1)
end

----------------------------------------------------------------------------------------------------
-- 1.6 VFX vocabulary + restraint budgets. Effects are PUNCTUATION, not wallpaper —
-- every emitter/light in the game must fit one of these rows and its budget:
--
--   Rarity aura    displayed glizzies       Rate <= AuraMaxRate, <= 1 emitter per dog;
--                                           PointLights Epic+ only, Shadows = false,
--                                           Range <= AuraLightRangeMax;
--                                           pedestal units ONLY, never the vault.
--   Cook burst     one-shot at the station  Emit(CookBurstCount) only — never looping.
--   Purchase pop   pad flash + label pop    client tween only, no emitters.
--   Steal alarm    victim's SignPost        AlarmFlashes red flashes, AlarmSeconds max.
--   Coin sparkle   HUD milestone burst      CoinSparkleLabels tweened emoji labels per
--                                           CoinMilestone-coin cross.
--   Culling        client-side              glizzy emitters + Rainbow hue cycles disabled
--                                           beyond CullDistance studs, checked at CullHz.
----------------------------------------------------------------------------------------------------

Theme.VFX = {
	AuraMaxRate = 6, -- particles/sec ceiling for any rarity aura
	AuraLightRangeMax = 10, -- PointLight range ceiling (Epic+ only, Shadows = false)
	CookBurstCount = 25, -- one-shot Emit() at the cook station
	AlarmFlashes = 3, -- steal-alarm red flashes on the victim's SignPost
	AlarmSeconds = 3, -- steal alarm hard cap
	CoinSparkleLabels = 6, -- tweened 💰 labels per milestone
	CoinMilestone = 5000, -- coins between HUD sparkle bursts
	CullDistance = 60, -- studs; beyond this the client disables dog fx
	CullHz = 1, -- how often the client re-checks culling
}

return Theme
