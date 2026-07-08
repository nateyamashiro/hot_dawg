--!strict
-- Client-side glizzy effects (design plan §3.4 + §1.6 culling):
--   * Rainbow variant: hue-cycles the Sausage + Drizzle parts at 10 Hz within 80
--     studs of the camera. Pure presentation — the server never touches colors.
--   * Culling: rarity-aura ParticleEmitters are disabled beyond Theme.VFX.CullDistance
--     studs, re-checked at Theme.VFX.CullHz. Keeps a 20-stand street cheap on mobile.
--
-- Tracks every "DogUnit" model in workspace (pedestals, vault, carried rigs alike)
-- via one initial scan + DescendantAdded; entries drop when the model is destroyed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))

-- Rainbow hue-cycling stops beyond this range (cheaper than the emitter cull since
-- it's a per-part Color write 10×/sec).
local RAINBOW_RANGE = 80
local HUE_INTERVAL = 0.1 -- 10 Hz

type Entry = {
	model: Model,
	colorParts: { BasePart }, -- Sausage + Drizzle (hue-cycled when Rainbow)
	emitters: { ParticleEmitter },
	rainbow: boolean,
	emittersOn: boolean,
}

local tracked: { [Model]: Entry } = {}

local function register(model: Model)
	if tracked[model] then
		return
	end
	local rainbow = model:GetAttribute("GlizzyVariant") == "Rainbow"
	local colorParts: { BasePart } = {}
	local emitters: { ParticleEmitter } = {}
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") and (desc.Name == "Sausage" or desc.Name == "Drizzle") then
			table.insert(colorParts, desc)
		elseif desc:IsA("ParticleEmitter") then
			table.insert(emitters, desc)
		end
	end
	if not rainbow and #emitters == 0 then
		return -- nothing to animate or cull on this dog
	end
	tracked[model] = {
		model = model,
		colorParts = colorParts,
		emitters = emitters,
		rainbow = rainbow,
		emittersOn = true,
	}
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(Workspace) then
			tracked[model] = nil
		end
	end)
end

Workspace.DescendantAdded:Connect(function(inst)
	if inst:IsA("Model") and inst.Name == "DogUnit" then
		-- Let the model's parts/emitters finish replicating before we scan it.
		task.delay(0.1, register, inst)
	end
end)
for _, inst in Workspace:GetDescendants() do
	if inst:IsA("Model") and inst.Name == "DogUnit" then
		register(inst)
	end
end

local function cameraPosition(): Vector3?
	local cam = Workspace.CurrentCamera
	return cam and cam.CFrame.Position or nil
end

-- Rainbow hue cycle: one shared color per tick (all Rainbows pulse in sync — reads
-- as intentional, and it's one fromHSV call instead of one per dog).
local hueAccum = 0
RunService.Heartbeat:Connect(function(dt: number)
	hueAccum += dt
	if hueAccum < HUE_INTERVAL then
		return
	end
	hueAccum = 0
	local camPos = cameraPosition()
	if not camPos then
		return
	end
	local color = Color3.fromHSV((os.clock() * 0.4) % 1, 0.7, 1)
	for model, entry in tracked do
		if entry.rainbow then
			local primary = model.PrimaryPart
			if primary and (primary.Position - camPos).Magnitude <= RAINBOW_RANGE then
				for _, part in entry.colorParts do
					part.Color = color
				end
			end
		end
	end
end)

-- Emitter culling at CullHz: far-away rarity auras cost zero particle sim.
task.spawn(function()
	while true do
		task.wait(1 / Theme.VFX.CullHz)
		local camPos = cameraPosition()
		if camPos then
			for model, entry in tracked do
				local primary = model.PrimaryPart
				if primary and #entry.emitters > 0 then
					local shouldBeOn = (primary.Position - camPos).Magnitude
						<= Theme.VFX.CullDistance
					if shouldBeOn ~= entry.emittersOn then
						entry.emittersOn = shouldBeOn
						for _, emitter in entry.emitters do
							emitter.Enabled = shouldBeOn
						end
					end
				end
			end
		end
	end
end)
