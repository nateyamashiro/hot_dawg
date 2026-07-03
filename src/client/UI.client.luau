--!strict
-- Client UI. Runs on each player's device. This side is NOT trusted with any
-- economy logic — it just shows the current values and sends "please buy"
-- requests to the server. We even build the whole UI in code so there's
-- nothing to place by hand in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyUpgrade = remotes:WaitForChild("BuyUpgrade") :: RemoteEvent

-- The server creates leaderstats for us; wait for it and its values.
local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins") :: IntValue
local level = leaderstats:WaitForChild("Upgrade") :: IntValue

-- === Build the UI ===
local gui = Instance.new("ScreenGui")
gui.Name = "TycoonUI"
gui.ResetOnSpawn = false

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(240, 44)
label.Position = UDim2.fromOffset(20, 20)
label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Parent = gui

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(240, 54)
button.Position = UDim2.fromOffset(20, 72)
button.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Parent = gui

local function refresh()
	label.Text = string.format("Coins: %d   |   Lv %d", coins.Value, level.Value)
	button.Text = "Buy Upgrade"
end

coins.Changed:Connect(refresh)
level.Changed:Connect(refresh)
refresh()

button.Activated:Connect(function()
	buyUpgrade:FireServer()
end)

gui.Parent = player:WaitForChild("PlayerGui")
