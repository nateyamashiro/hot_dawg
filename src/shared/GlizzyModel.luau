--!strict
-- Procedural glizzy builder (design plan Part 3). Replaces the flat colored boxes with
-- a real chunky low-poly hot dog: sausage + bun halves + mustard zigzag, with a rarity
-- fx ladder (Neon drizzle → lights → particles) and variant treatments (Gold recolor;
-- Rainbow is hue-cycled CLIENT-side by GlizzyFx.client; Giant is just a bigger scale
-- passed by the caller). One builder serves every surface: pedestals, the vault shelf,
-- the welded carry rig, and the rooftop statue.
--
-- Mesh escape hatch (locked decision #2): when GameConfig.GlizzyMeshIds has an entry
-- for the dog, we render ONE part with a SpecialMesh instead — AI meshes swap in later
-- with zero code changes. SpecialMesh (not MeshPart) is deliberate: MeshPart.MeshId is
-- not scriptable at runtime; SpecialMesh.MeshId is.

local GameConfig = require(script.Parent.GameConfig)
local HotDogDex = require(script.Parent.HotDogDex)
local Theme = require(script.Parent.Theme)

local GlizzyModel = {}

export type BuildOpts = {
	rarity: string?, -- default "Common"
	variant: string?, -- default "base"
	scale: number?, -- 1 = pedestal; 0.85 = carry; 4 = rooftop statue
	anchored: boolean?, -- true = pedestal (default); false = welded carry rig
	fx: boolean?, -- rarity aura on/off (pedestal true, vault false; default true)
}

local SPARKLES = "rbxasset://textures/particles/sparkles_main.dds"
local EMBERS = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- Secret-tier override colors (the "void glizzy" look) + fixed fx tint.
local SECRET_SAUSAGE = Color3.fromRGB(25, 22, 30)
local SECRET_BUN = Color3.fromRGB(70, 56, 66)
local SECRET_DRIZZLE = Color3.fromRGB(120, 80, 200)
-- Forbidden-tier overrides (additions #8): void meat, electric-violet everything.
local FORBIDDEN_SAUSAGE = Color3.fromRGB(40, 18, 60)
local FORBIDDEN_BUN = Color3.fromRGB(84, 50, 110)
local FORBIDDEN_DRIZZLE = Color3.fromRGB(200, 80, 255)
local MYTHIC_LIGHT = Color3.fromRGB(255, 90, 60)
local GOLD_SAUSAGE = Color3.fromRGB(240, 200, 60)
local GOLD_BUN = Color3.fromRGB(255, 220, 90)

local function makePart(props: { [string]: any }): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(part :: any)[k] = v
	end
	return part
end

-- One rarity-aura emitter, on the sausage. Budgets (Theme.VFX): Rate <= 6, at most
-- one emitter per dog, fire-and-forget (no per-frame server work).
local function addEmitter(parent: BasePart, texture: string, rate: number, color: Color3, s: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture
	emitter.Rate = rate
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.6
	emitter.Size = NumberSequence.new(0.35 * s)
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Speed = NumberRange.new(1.5) -- gentle upward drift
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = parent
end

function GlizzyModel.build(dogName: string, opts: BuildOpts?): Model
	local o: BuildOpts = opts or {}
	local rarity = (o.rarity or "Common") :: HotDogDex.Rarity
	local variant = o.variant or "base"
	local s = o.scale or 1
	local anchored = if o.anchored ~= nil then o.anchored else true
	local fx = if o.fx ~= nil then o.fx else true
	local rank = HotDogDex.rarityRank(rarity)
	local rarityColor = HotDogDex.colorFor(rarity)

	-- === Resolve the color/material recipe (rarity ladder + variant treatment) ===
	-- Rarity reads on the MEAT (sausage lerped toward the tier color); Rare+ upgrades
	-- the drizzle to Neon in the tier color (zero perf cost — it's just material).
	local sausageColor = Theme.Palette.SausageBrown:Lerp(rarityColor, 0.45)
	local bunColor = Theme.Palette.BunTan
	local drizzleColor = Theme.Palette.Mustard
	local drizzleMaterial = Enum.Material.SmoothPlastic
	local meatMaterial = Enum.Material.SmoothPlastic
	if rank >= 3 then
		drizzleMaterial = Enum.Material.Neon
		drizzleColor = rarityColor
	end
	if rarity == "Secret" then
		sausageColor = SECRET_SAUSAGE
		bunColor = SECRET_BUN
		drizzleColor = SECRET_DRIZZLE
	elseif rarity == "Forbidden" then
		sausageColor = FORBIDDEN_SAUSAGE
		bunColor = FORBIDDEN_BUN
		drizzleColor = FORBIDDEN_DRIZZLE
	end
	if variant == "Gold" then
		sausageColor = GOLD_SAUSAGE
		bunColor = GOLD_BUN
		meatMaterial = Enum.Material.Metal
	end

	local model = Instance.new("Model")
	model.Name = "DogUnit" -- clearUnits' name check keeps working
	model:SetAttribute("GlizzyRarity", rarity)
	model:SetAttribute("GlizzyVariant", variant)

	local parts: { BasePart } = {}
	local sausage: BasePart

	local meshDef = GameConfig.GlizzyMeshIds[dogName]
	if meshDef then
		-- Mesh escape hatch: one part + SpecialMesh; rarity fx still attach below.
		sausage = makePart({
			Name = "Sausage",
			Size = Vector3.new(3.2, 1.2, 1.2) * s,
			Color = sausageColor,
			Material = meatMaterial,
			CFrame = CFrame.new(),
		})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = meshDef.meshId
		if meshDef.textureId then
			mesh.TextureId = meshDef.textureId
		end
		mesh.Scale = (meshDef.scale or Vector3.one) * s
		mesh.Parent = sausage
		table.insert(parts, sausage)
	else
		-- === Procedural composition: 6 parts, ~1.15 tall, 3.2 long at scale 1 ===
		-- Cylinders extend along X natively; yaw them 90° so the dog lies along the
		-- model's Z (matches how pedestal anchors + carry welds are oriented).
		local lieAlongZ = CFrame.Angles(0, math.rad(90), 0)
		sausage = makePart({
			Name = "Sausage",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3.2, 1.05, 1.05) * s,
			Color = sausageColor,
			Material = meatMaterial,
			CFrame = lieAlongZ,
		})
		table.insert(parts, sausage)

		for _, side in { -1, 1 } do
			local bun = makePart({
				Name = "Bun",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3.0, 1.15, 1.15) * s,
				Color = bunColor,
				Material = meatMaterial,
				CFrame = CFrame.new(Vector3.new(side * 0.72, -0.08, 0) * s) * lieAlongZ,
			})
			table.insert(parts, bun)
		end

		-- Mustard zigzag: 3 small blocks along the top, alternating yaw.
		for i, zOffset in { -0.9, 0, 0.9 } do
			local yaw = if i % 2 == 1 then 25 else -25
			local drizzle = makePart({
				Name = "Drizzle",
				Size = Vector3.new(0.28, 0.14, 0.7) * s,
				Color = drizzleColor,
				Material = drizzleMaterial,
				CFrame = CFrame.new(Vector3.new(0, 0.55, zOffset) * s)
					* CFrame.Angles(0, math.rad(yaw), 0),
			})
			table.insert(parts, drizzle)
		end
	end

	-- === Rarity aura (server attaches at build; client culls beyond 60 studs) ===
	-- Lights only Epic+ (Shadows off, Range <= 10); at most ONE emitter per dog.
	if fx then
		if rank >= 4 then
			local light = Instance.new("PointLight")
			light.Shadows = false
			if rarity == "Epic" then
				light.Brightness = 0.8
				light.Range = 8
				light.Color = drizzleColor
			elseif rarity == "Legendary" then
				light.Brightness = 1.2
				light.Range = 10
				light.Color = drizzleColor
			elseif rarity == "Mythic" then
				light.Brightness = 1.5
				light.Range = 10
				light.Color = MYTHIC_LIGHT
			elseif rarity == "Forbidden" then
				light.Brightness = 1.8
				light.Range = 10
				light.Color = FORBIDDEN_DRIZZLE
			else -- Secret
				light.Brightness = 1.2
				light.Range = 10
				light.Color = SECRET_DRIZZLE
			end
			light.Parent = sausage
		end
		if rarity == "Legendary" then
			addEmitter(sausage, SPARKLES, 3, drizzleColor, s)
		elseif rarity == "Mythic" then
			addEmitter(sausage, EMBERS, 6, MYTHIC_LIGHT, s)
		elseif rarity == "Secret" then
			addEmitter(sausage, SMOKE, 4, SECRET_DRIZZLE, s)
		elseif rarity == "Forbidden" then
			addEmitter(sausage, SPARKLES, 6, FORBIDDEN_DRIZZLE, s)
		elseif variant == "Gold" then
			-- Gold's sparkle rides the same one-emitter budget: only when the rarity
			-- ladder didn't already claim it.
			addEmitter(sausage, SPARKLES, 2, GOLD_SAUSAGE, s)
		end
	end

	-- === Assemble: anchored pedestal statue, or a massless welded carry rig ===
	for _, part in parts do
		if not anchored then
			part.Anchored = false
			part.Massless = true
			if part ~= sausage then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = part
				weld.Part1 = sausage
				weld.Parent = part
			end
		end
		part.Parent = model
	end
	model.PrimaryPart = sausage

	return model
end

return GlizzyModel
