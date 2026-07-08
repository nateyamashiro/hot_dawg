--!strict
-- World look: applies Theme.Lighting (bright cartoon noon + post fx + clouds) and
-- builds the shared map — ground, the central street with mustard lane dashes,
-- sidewalks, and lamp posts — so the game is self-contained (no Studio baseplate
-- reliance). Called ONCE from Main before PlotManager.build() so plots land on a
-- world that already reads as a place.
--
-- Everything is anchored + CastShadow-tuned; colors come from Theme.Palette so the
-- street reads as the same universe as the stands (ketchup-and-mustard land).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Theme = require(ReplicatedStorage.Shared.Theme)

local EnvironmentService = {}

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

local function applyLighting()
	local spec = Theme.Lighting

	-- Lighting.Technology is NOT scriptable at runtime — it must be set to ShadowMap
	-- in Studio. pcall'd so this documents the intent without erroring live servers.
	pcall(function()
		local lighting: any = Lighting
		lighting.Technology = spec.Technology
	end)

	Lighting.ClockTime = spec.ClockTime
	Lighting.GeographicLatitude = spec.GeographicLatitude
	Lighting.Brightness = spec.Brightness
	Lighting.ShadowSoftness = spec.ShadowSoftness
	Lighting.Ambient = spec.Ambient
	Lighting.OutdoorAmbient = spec.OutdoorAmbient
	Lighting.ColorShift_Top = spec.ColorShift_Top
	Lighting.EnvironmentDiffuseScale = spec.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = spec.EnvironmentSpecularScale

	-- Post-processing children (idempotent: clear ours before re-adding).
	for _, name in
		{ "GlizzyAtmosphere", "GlizzyBloom", "GlizzyColor", "GlizzySunRays", "GlizzySky" }
	do
		local existing = Lighting:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "GlizzyAtmosphere"
	atmosphere.Density = spec.Atmosphere.Density
	atmosphere.Offset = spec.Atmosphere.Offset
	atmosphere.Color = spec.Atmosphere.Color
	atmosphere.Decay = spec.Atmosphere.Decay
	atmosphere.Glare = spec.Atmosphere.Glare
	atmosphere.Haze = spec.Atmosphere.Haze
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "GlizzyBloom"
	bloom.Intensity = spec.Bloom.Intensity
	bloom.Size = spec.Bloom.Size
	bloom.Threshold = spec.Bloom.Threshold
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "GlizzyColor"
	color.Saturation = spec.ColorCorrection.Saturation
	color.Contrast = spec.ColorCorrection.Contrast
	color.TintColor = spec.ColorCorrection.TintColor
	color.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "GlizzySunRays"
	sunRays.Intensity = spec.SunRays.Intensity
	sunRays.Spread = spec.SunRays.Spread
	sunRays.Parent = Lighting

	-- Cartoon clouds live on Terrain, not Lighting.
	local terrain = Workspace.Terrain
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = spec.Clouds.Cover
	clouds.Density = spec.Clouds.Density
	clouds.Color = spec.Clouds.Color
	clouds.Parent = terrain

	-- Optional custom skybox (P-E: Nate fills GameConfig.SkyboxAssetId; "" = default sky).
	if GameConfig.SkyboxAssetId ~= "" then
		local sky = Instance.new("Sky")
		sky.Name = "GlizzySky"
		local id = GameConfig.SkyboxAssetId
		sky.SkyboxBk = id
		sky.SkyboxDn = id
		sky.SkyboxFt = id
		sky.SkyboxLf = id
		sky.SkyboxRt = id
		sky.SkyboxUp = id
		sky.Parent = Lighting
	end
end

local function buildMap()
	local existing = Workspace:FindFirstChild("Environment")
	if existing then
		existing:Destroy()
	end
	local map = Instance.new("Model")
	map.Name = "Environment"

	-- Ground: one big grass slab (top at y 0, flush with a Studio baseplate if present).
	local ground = makePart({
		Name = "Ground",
		Size = Vector3.new(1200, 1, 1200),
		Color = Theme.Palette.Grass,
		CanCollide = true,
		CFrame = CFrame.new(0, -0.5, 0),
	})
	ground.Parent = map

	-- Street: the central aisle between the two plot rows (also the Phase-4 belt lane).
	local street = makePart({
		Name = "Street",
		Size = Vector3.new(1040, 0.7, 56),
		Color = Theme.Palette.Asphalt,
		CanCollide = true,
		CFrame = CFrame.new(0, 0.05, 0),
	})
	street.Parent = map

	-- Lane dashes: mustard road paint (on-theme), 20 dashes down the middle.
	for x = -456, 456, 48 do
		local dash = makePart({
			Name = "LaneDash",
			Size = Vector3.new(6, 0.1, 1.2),
			Color = Theme.Palette.Mustard,
			CastShadow = false,
			CFrame = CFrame.new(x, 0.45, 0),
		})
		dash.Parent = map
	end

	-- Sidewalk strips flanking the street.
	for _, side in { -1, 1 } do
		local sidewalk = makePart({
			Name = "Sidewalk",
			Size = Vector3.new(1040, 0.5, 8),
			Color = Theme.Palette.Sidewalk,
			CanCollide = true,
			CFrame = CFrame.new(0, 0.15, side * 32),
		})
		sidewalk.Parent = map
	end

	-- Lamp posts along both sidewalks (decorative — no PointLights; noon is bright).
	for x = -480, 480, 96 do
		for _, side in { -1, 1 } do
			local pole = makePart({
				Name = "LampPole",
				Size = Vector3.new(1, 9, 1),
				Color = Theme.Palette.Steel,
				CanCollide = true,
				CFrame = CFrame.new(x, 4.5, side * 30),
			})
			pole.Parent = map
			local head = makePart({
				Name = "LampHead",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2.4, 2.4, 2.4),
				Color = Theme.Palette.Cream,
				Material = Enum.Material.Neon,
				CastShadow = false,
				CFrame = CFrame.new(x, 9.7, side * 30),
			})
			head.Parent = map
		end
	end

	map.Parent = Workspace
end

function EnvironmentService.init()
	applyLighting()
	buildMap()
end

return EnvironmentService
