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

	-- Ground: one big grass slab (top at y 0, flush with a Studio baseplate if
	-- present). Oversized past the street so the P-E horizon props sit on grass.
	local ground = makePart({
		Name = "Ground",
		Size = Vector3.new(1600, 1, 1600),
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

	-- === Glizzy-land horizon (P-E): surreal skyline dressing beyond the plots. ===
	-- Bun hills: half-buried bun-tan domes ringing the map (fixed layout — every
	-- server shows the same skyline).
	local hills: { { x: number, z: number, size: number } } = {
		{ x = -580, z = 620, size = 150 },
		{ x = -300, z = 660, size = 100 },
		{ x = 250, z = 640, size = 130 },
		{ x = 590, z = 600, size = 90 },
		{ x = -520, z = -610, size = 140 },
		{ x = -80, z = -650, size = 95 },
		{ x = 420, z = -620, size = 120 },
		{ x = 640, z = 150, size = 110 },
		{ x = -650, z = -120, size = 125 },
		{ x = 660, z = -300, size = 85 },
	}
	for _, hill in hills do
		local dome = makePart({
			Name = "BunHill",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(hill.size, hill.size, hill.size),
			Color = Theme.Palette.BunTan,
			CanCollide = true,
			-- Centered at ground level = exactly half-buried dome.
			CFrame = CFrame.new(hill.x, 0, hill.z),
		})
		dome.Parent = map
	end

	-- Mustard river: a glowing yellow ribbon across the far north horizon.
	local river = makePart({
		Name = "MustardRiver",
		Size = Vector3.new(1200, 0.4, 14),
		Color = Theme.Palette.Mustard,
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(0, 0.2, 700),
	})
	river.Parent = map

	-- Ketchup geyser prop (static — VFX budgets keep looping emitters off the map).
	local pool = makePart({
		Name = "KetchupPool",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 24, 24),
		Color = Theme.Palette.Ketchup,
		CFrame = CFrame.new(620, 0.4, -540) * CFrame.Angles(0, 0, math.rad(90)),
	})
	pool.Parent = map
	local column = makePart({
		Name = "KetchupColumn",
		Size = Vector3.new(5, 22, 5),
		Color = Theme.Palette.Ketchup,
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(620, 11, -540),
	})
	column.Parent = map
	local blob = makePart({
		Name = "KetchupBlob",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(9, 9, 9),
		Color = Theme.Palette.Ketchup,
		Material = Enum.Material.Neon,
		CastShadow = false,
		CFrame = CFrame.new(620, 23, -540),
	})
	blob.Parent = map

	map.Parent = Workspace
end

function EnvironmentService.init()
	applyLighting()
	buildMap()
end

return EnvironmentService
