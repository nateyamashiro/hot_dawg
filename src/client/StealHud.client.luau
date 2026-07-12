--!strict
-- Steal/defense HUD. Untrusted UI: it only displays server-pushed state and fires
-- request RemoteEvents. Shows steal charges + shield timer, a "you're carrying"
-- banner, a "you're being robbed!" alert with a directional arrow to the thief,
-- buy-defense buttons, and toast feedback. (The Net is a Tool in your backpack.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stealAlert = remotes:WaitForChild("StealAlert") :: RemoteEvent
local vaultBreach = remotes:WaitForChild("VaultBreach") :: RemoteEvent
local carryUpdate = remotes:WaitForChild("CarryUpdate") :: RemoteEvent
local stealFeedback = remotes:WaitForChild("StealFeedback") :: RemoteEvent
local statsUpdate = remotes:WaitForChild("StatsUpdate") :: RemoteEvent
local buyDefense = remotes:WaitForChild("BuyDefense") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

-- === Build UI ===
local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyStealHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- Steal charges + shield readout (top-right).
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.fromOffset(240, 48)
statsLabel.Position = UDim2.new(1, -260, 0, 20)
statsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statsLabel.BackgroundTransparency = 0.3
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.TextScaled = true
statsLabel.Font = Enum.Font.GothamBold
statsLabel.Text = "⚡ Charges: -/-"
statsLabel.Parent = gui

-- Carry banner (top-center, hidden until carrying).
local carryBanner = Instance.new("TextLabel")
carryBanner.Size = UDim2.fromOffset(520, 52)
carryBanner.Position = UDim2.new(0.5, -260, 0, 70)
carryBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
carryBanner.BackgroundTransparency = 0.15
carryBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
carryBanner.TextScaled = true
carryBanner.Font = Enum.Font.GothamBlack
carryBanner.Text = ""
carryBanner.Visible = false
carryBanner.Parent = gui

-- Robbed alert (top-center, below carry banner).
local robbedBanner = Instance.new("TextLabel")
robbedBanner.Size = UDim2.fromOffset(520, 44)
robbedBanner.Position = UDim2.new(0.5, -260, 0, 128)
robbedBanner.BackgroundColor3 = Color3.fromRGB(240, 150, 20)
robbedBanner.BackgroundTransparency = 0.15
robbedBanner.TextColor3 = Color3.fromRGB(40, 20, 0)
robbedBanner.TextScaled = true
robbedBanner.Font = Enum.Font.GothamBlack
robbedBanner.Text = ""
robbedBanner.Visible = false
robbedBanner.Parent = gui

-- Directional arrow toward a thief (full-screen overlay).
local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.fromOffset(70, 70)
arrow.BackgroundTransparency = 1
arrow.TextColor3 = Color3.fromRGB(255, 60, 60)
arrow.TextStrokeTransparency = 0.2
arrow.TextScaled = true
arrow.Font = Enum.Font.GothamBlack
arrow.Text = "➤"
arrow.Visible = false
arrow.Parent = gui

-- Toast (bottom-center).
local toast = Instance.new("TextLabel")
toast.Size = UDim2.fromOffset(520, 44)
toast.Position = UDim2.new(0.5, -260, 1, -90)
toast.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toast.BackgroundTransparency = 0.2
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextScaled = true
toast.Font = Enum.Font.GothamBold
toast.Text = ""
toast.Visible = false
toast.Parent = gui

-- Buy-defense buttons (bottom-left).
local function makeBuyButton(text: string, yOffset: number, which: string): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(200, 44)
	btn.Position = UDim2.new(0, 20, 1, yOffset)
	btn.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.Parent = gui
	btn.Activated:Connect(function()
		buyDefense:FireServer(which)
	end)
	return btn
end
-- (The 🧱 Wall button is gone — the perimeter wall is a BuildCatalog structure now,
-- bought on the 🏗️ build pad at your stand.)
makeBuyButton(string.format("🛡️ Guard (%s)", Format.comma(GameConfig.GuardCost)), -60, "guard")
makeBuyButton(string.format("🪤 Trap (%s)", Format.comma(GameConfig.TrapCost)), -110, "trap")
-- Vault Breaker (additions #7): the offense consumable rides the same validated
-- BuyDefense remote; the owned count on the label updates via StatsUpdate.
local breakerBtn = makeBuyButton(
	string.format("🔓 Breaker (%s)", Format.comma(GameConfig.VaultBreakerCost)),
	-160,
	"breaker"
)

gui.Parent = player:WaitForChild("PlayerGui")

-- === State ===
local shieldUntil = 0

local function refreshStats(charges: number, maxCharges: number)
	local shieldLeft = shieldUntil - os.time()
	if shieldLeft > 0 then
		statsLabel.Text = string.format("⚡ %d/%d   🛡️ %ds", charges, maxCharges, shieldLeft)
	else
		statsLabel.Text = string.format("⚡ Charges: %d/%d", charges, maxCharges)
	end
end

local lastCharges, lastMax = 0, GameConfig.MaxStealCharges
statsUpdate.OnClientEvent:Connect(
	function(charges: number, maxCharges: number, newShieldUntil: number, breakers: number?)
		lastCharges, lastMax = charges, maxCharges
		shieldUntil = newShieldUntil
		refreshStats(charges, maxCharges)
		if type(breakers) == "number" then
			breakerBtn.Text = string.format(
				"🔓 Breaker ×%d (%s)",
				breakers,
				Format.comma(GameConfig.VaultBreakerCost)
			)
		end
	end
)
-- Keep the shield countdown ticking even without new pushes.
task.spawn(function()
	while true do
		task.wait(1)
		refreshStats(lastCharges, lastMax)
	end
end)

carryUpdate.OnClientEvent:Connect(function(carrying: boolean, dogName: string)
	if carrying then
		carryBanner.Text = string.format("🏃 Carrying %s — get to your stand!", dogName)
		carryBanner.Visible = true
	else
		carryBanner.Visible = false
	end
end)

-- Toast helper.
local toastToken = 0
local function showToast(message: string, ok: boolean)
	toast.Text = message
	toast.TextColor3 = ok and Color3.fromRGB(150, 255, 170) or Color3.fromRGB(255, 170, 170)
	toast.Visible = true
	toastToken += 1
	local myToken = toastToken
	task.delay(3, function()
		if myToken == toastToken then
			toast.Visible = false
		end
	end)
end
stealFeedback.OnClientEvent:Connect(function(ok: boolean, message: string)
	showToast(message, ok)
end)

-- === Robbed alert + directional arrow ===
local alertUntil = 0
local thiefUserId: number? = nil
stealAlert.OnClientEvent:Connect(function(userId: number, thiefName: string, dogName: string)
	robbedBanner.Text = string.format("🚨 %s is stealing your %s!", thiefName, dogName)
	robbedBanner.Visible = true
	arrow.Visible = true
	thiefUserId = userId
	alertUntil = os.clock() + 8
end)

-- Vault-breach alarm (additions #7): same banner + arrow, but the countdown IS the
-- counterplay window — net/trap/blast the driller before it hits zero.
vaultBreach.OnClientEvent:Connect(function(userId: number, thiefName: string, seconds: number)
	robbedBanner.Text =
		string.format("💥 %s is DRILLING YOUR VAULT! %ds to stop them!", thiefName, seconds)
	robbedBanner.Visible = true
	arrow.Visible = true
	thiefUserId = userId
	alertUntil = os.clock() + seconds
end)

local camera = Workspace.CurrentCamera
RunService.RenderStepped:Connect(function()
	if os.clock() >= alertUntil then
		robbedBanner.Visible = false
		arrow.Visible = false
		return
	end
	local id = thiefUserId
	local thief = id and Players:GetPlayerByUserId(id)
	local char = thief and thief.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (hrp and camera) then
		arrow.Visible = false
		return
	end
	arrow.Visible = true
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
	local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
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
	-- Place the arrow partway from center toward the thief, clamped to a ring.
	local ring = math.min(viewport.X, viewport.Y) * 0.35
	local pos = center + unit * ring
	arrow.Position = UDim2.fromOffset(pos.X - 35, pos.Y - 35)
	arrow.Rotation = math.deg(math.atan2(unit.Y, unit.X))
end)

-- Ask the server to (re)send our steal charges + shield now that we're listening.
requestState:FireServer()
