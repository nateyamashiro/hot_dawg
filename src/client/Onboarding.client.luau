--!strict
-- Onboarding first-60s (GDD §4.9): guided arrows for brand-new players —
-- cook → stove → build. Pure untrusted display: the SERVER derives the stage from
-- data and pushes it via OnboardingUpdate; this script points a screen-edge arrow
-- (StealHud's ring pattern) + a Highlight at the right station on the player's own
-- plot (found via the replicated OwnerUserId attribute). Stage 0 = done — veterans
-- derive straight to 0 and never see any of this.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local onboardingUpdate = remotes:WaitForChild("OnboardingUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local TIPS: { [number]: string } = {
	[1] = "Step 1/3 — Cook your first glizzy at the 🌭 station!",
	[2] = "Step 2/3 — Walk onto the 🔥 pad to build a stove!",
	[3] = "Step 3/3 — Grab your first 🏗️ build!",
}
-- Arrow targets per stage, in priority order, all inside the player's own plot.
-- (Stage 2 prefers the built stove body so the arrow stays honest mid-transition.)
local TARGETS: { [number]: { string } } = {
	[1] = { "CookStation" },
	[2] = { "StoveBody", "Pad_stove" },
	[3] = { "Pad_build" },
}

local ARROW_COLOR = Color3.fromRGB(255, 200, 60)

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyOnboarding"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local banner = Instance.new("TextLabel")
banner.Size = UDim2.fromOffset(520, 46)
banner.Position = UDim2.new(0.5, -260, 0, 60)
banner.BackgroundColor3 = MenuLayout.RowBg
banner.TextColor3 = MenuLayout.BodyText
banner.TextScaled = true
banner.Font = Enum.Font.FredokaOne
banner.Visible = false
banner.Parent = gui
MenuLayout.addChrome(banner, 10)

local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.fromOffset(70, 70)
arrow.BackgroundTransparency = 1
arrow.Text = "➤"
arrow.TextScaled = true
arrow.TextColor3 = ARROW_COLOR
arrow.TextStrokeTransparency = 0.4
arrow.Visible = false
arrow.Parent = gui

local stage = 0
local target: BasePart? = nil
local highlight: Highlight? = nil
local nextResolveAt = 0

local function clearTarget()
	target = nil
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
end

local function ownPlot(): Model?
	for _, child in Workspace:GetChildren() do
		if child:IsA("Model") and string.match(child.Name, "^Plot%d+$") then
			if child:GetAttribute("OwnerUserId") == player.UserId then
				return child
			end
		end
	end
	return nil
end

-- Lazy + throttled: the plot/pads may replicate after the stage push lands, so
-- keep retrying every half second until the target part shows up.
local function resolveTarget()
	if os.clock() < nextResolveAt then
		return
	end
	nextResolveAt = os.clock() + 0.5
	local plot = ownPlot()
	if not plot then
		return
	end
	for _, name in TARGETS[stage] or {} do
		local inst = plot:FindFirstChild(name, true)
		if inst and inst:IsA("BasePart") then
			target = inst
			local h = Instance.new("Highlight")
			h.FillColor = ARROW_COLOR
			h.FillTransparency = 0.6
			h.OutlineColor = Color3.fromRGB(255, 255, 255)
			h.Parent = inst
			highlight = h
			return
		end
	end
end

local camera = Workspace.CurrentCamera
RunService.RenderStepped:Connect(function()
	if stage < 1 or stage > 3 then
		return
	end
	local part = target
	if not (part and part.Parent) then
		clearTarget()
		resolveTarget()
		part = target
	end
	if not (part and camera) then
		arrow.Visible = false
		return
	end
	arrow.Visible = true
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
	local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
	local dir: Vector2
	if onScreen and screenPos.Z > 0 then
		dir = Vector2.new(screenPos.X, screenPos.Y) - center
	else
		-- Behind the camera: flip so the arrow still points the right way.
		dir = center - Vector2.new(screenPos.X, screenPos.Y)
	end
	if dir.Magnitude < 1 then
		dir = Vector2.new(0, -1)
	end
	local unit = dir.Unit
	-- Place the arrow partway from center toward the target, clamped to a ring.
	local ring = math.min(viewport.X, viewport.Y) * 0.35
	local pos = center + unit * ring
	arrow.Position = UDim2.fromOffset(pos.X - 35, pos.Y - 35)
	arrow.Rotation = math.deg(math.atan2(unit.Y, unit.X))
end)

onboardingUpdate.OnClientEvent:Connect(function(newStage: number)
	stage = newStage
	clearTarget()
	nextResolveAt = 0
	local tip = TIPS[stage]
	if tip then
		banner.Text = tip
		banner.Visible = true
	else
		banner.Visible = false
		arrow.Visible = false
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
