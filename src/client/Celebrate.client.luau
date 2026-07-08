--!strict
-- Juice renderer (P-C, design plan §4.2). Listens to the one-shot Celebrate remote
-- and plays the world effects locally — the server only ever says WHAT happened:
--   "cook" (burst at the cook station, colored by rarity, + reveal sound/stingers)
--   "purchase" (walk-on pad white flash + label pop)
--   "build" (bun-tan dust puff over the plot + sound)
--   "stealAlarm" (3 red flashes on the victim's sign post, 3s max — Theme.VFX budget)
--   "giantShake" (brief camera shake when a Giant is grabbed nearby)
-- Also owns the client-only coin-milestone sparkle (6 💰 labels per 5,000-coin cross
-- — watches leaderstats, no remote) and starts the ambient sound bed (silence-safe).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HotDogDex = require(Shared:WaitForChild("HotDogDex"))
local Sfx = require(Shared:WaitForChild("Sfx"))
local Theme = require(Shared:WaitForChild("Theme"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local celebrate = remotes:WaitForChild("Celebrate") :: RemoteEvent

local SPARKLES = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- Resolve a remote target (BasePart or Vector3) to a part we can attach effects to.
-- Vector3 targets get a throwaway invisible anchor; the caller must clean it up.
local function resolveTarget(target: any): (BasePart?, boolean)
	if typeof(target) == "Instance" and target:IsA("BasePart") then
		return target, false
	end
	if typeof(target) == "Vector3" then
		local anchor = Instance.new("Part")
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(1, 1, 1)
		anchor.CFrame = CFrame.new(target)
		anchor.Parent = Workspace
		return anchor, true
	end
	return nil, false
end

-- One-shot particle burst on a part (fire-and-forget; emitter destroys itself).
local function burst(part: BasePart, texture: string, color: Color3, count: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Texture = texture
	emitter.Color = ColorSequence.new(color)
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(4, 9)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.6)
	emitter.LightEmission = 0.6
	emitter.Parent = part
	emitter:Emit(count)
	task.delay(2, function()
		emitter:Destroy()
	end)
end

local function onCook(target: any, rarity: any)
	local part, temp = resolveTarget(target)
	if not part then
		return
	end
	local color = HotDogDex.colorFor(rarity :: HotDogDex.Rarity)
	burst(part, SPARKLES, color, Theme.VFX.CookBurstCount)
	Sfx.play("CookReveal", part)
	local rank = HotDogDex.rarityRank(rarity :: HotDogDex.Rarity)
	if rank >= 5 then
		Sfx.play("LegendaryStinger", part)
	elseif rank >= 3 then
		Sfx.play("RareStinger", part)
	end
	if temp then
		task.delay(2.5, function()
			part:Destroy()
		end)
	end
end

local function onPurchase(target: any)
	local part = if typeof(target) == "Instance" and target:IsA("BasePart") then target else nil
	if not part then
		return
	end
	-- White flash back to whatever color the pad currently shows.
	local originalColor = part.Color
	part.Color = Theme.Palette.White
	TweenService:Create(
		part,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Color = originalColor }
	):Play()
	-- Label pop: 1 → 1.3 → 1 with Back/Out.
	local billboard = part:FindFirstChild("PadLabel")
	if billboard and billboard:IsA("BillboardGui") then
		local baseSize = billboard.Size
		local popped = UDim2.fromOffset(
			math.floor(baseSize.X.Offset * 1.3),
			math.floor(baseSize.Y.Offset * 1.3)
		)
		billboard.Size = popped
		TweenService:Create(
			billboard,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = baseSize }
		):Play()
	end
	Sfx.play("Purchase", part)
end

local function onBuild(target: any)
	local part, temp = resolveTarget(target)
	if not part then
		return
	end
	burst(part, SMOKE, Theme.Palette.BunTan, 30)
	Sfx.play("BuildComplete", part)
	if temp then
		task.delay(2.5, function()
			part:Destroy()
		end)
	end
end

local function onStealAlarm(target: any)
	local part = if typeof(target) == "Instance" and target:IsA("BasePart") then target else nil
	if not part then
		return
	end
	if part:FindFirstChild("AlarmLight") then
		return -- one alarm at a time per sign
	end
	local light = Instance.new("PointLight")
	light.Name = "AlarmLight"
	light.Color = Theme.Semantic.Danger
	light.Brightness = 4
	light.Range = 14
	light.Shadows = false
	light.Enabled = false
	light.Parent = part
	Sfx.play("StealAlarm", part)
	task.spawn(function()
		-- 3 flashes, 3s total — the Theme.VFX.AlarmFlashes/AlarmSeconds budget.
		for _ = 1, Theme.VFX.AlarmFlashes do
			light.Enabled = true
			task.wait(0.4)
			light.Enabled = false
			task.wait(Theme.VFX.AlarmSeconds / Theme.VFX.AlarmFlashes - 0.4)
		end
		light:Destroy()
	end)
end

local function onGiantShake(target: any)
	if typeof(target) ~= "Vector3" then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if (camera.CFrame.Position - target).Magnitude > Theme.VFX.CullDistance then
		return -- too far away to feel it
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 0.4 do
			humanoid.CameraOffset =
				Vector3.new((math.random() - 0.5) * 0.8, (math.random() - 0.5) * 0.8, 0)
			task.wait()
		end
		humanoid.CameraOffset = Vector3.zero
	end)
end

celebrate.OnClientEvent:Connect(function(kind: string, target: any, extra: any)
	if kind == "cook" then
		onCook(target, extra)
	elseif kind == "purchase" then
		onPurchase(target)
	elseif kind == "build" then
		onBuild(target)
	elseif kind == "stealAlarm" then
		onStealAlarm(target)
	elseif kind == "giantShake" then
		onGiantShake(target)
	end
end)

-- === Coin-milestone sparkle (client-only; watches leaderstats, no remote) ===
local sparkleGui = Instance.new("ScreenGui")
sparkleGui.Name = "CoinSparkle"
sparkleGui.ResetOnSpawn = false
sparkleGui.Parent = player:WaitForChild("PlayerGui")

local function sparkleBurst()
	for _ = 1, Theme.VFX.CoinSparkleLabels do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(44, 44)
		label.Position = UDim2.new(0.5, math.random(-60, 60), 0.35, math.random(-30, 30))
		label.BackgroundTransparency = 1
		label.Text = "💰"
		label.TextScaled = true
		label.Parent = sparkleGui
		local drift = UDim2.new(0.5, math.random(-220, 220), 0.35, math.random(-180, -80))
		local tween = TweenService:Create(
			label,
			TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = drift, TextTransparency = 1 }
		)
		tween.Completed:Once(function()
			label:Destroy()
		end)
		tween:Play()
	end
end

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")
	local coins = leaderstats:WaitForChild("Coins") :: IntValue
	local lastMilestone = math.floor(coins.Value / Theme.VFX.CoinMilestone)
	coins.Changed:Connect(function(value: number)
		local milestone = math.floor(value / Theme.VFX.CoinMilestone)
		if milestone > lastMilestone then
			sparkleBurst()
		end
		lastMilestone = milestone
	end)
end)

-- Ambient bed (no-op until GameConfig.Sounds.Ambient gets an id).
Sfx.startAmbient(Workspace)
