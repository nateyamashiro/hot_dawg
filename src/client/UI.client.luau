--!strict
-- Client UI. Runs on each player's device. This side is NOT trusted with any
-- economy logic — it shows the current values and sends "please cook" requests
-- to the server, then reveals whatever the server rolled. The whole UI is built
-- in code so there's nothing to place by hand in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local cookHotDog = remotes:WaitForChild("CookHotDog") :: RemoteEvent
local cookResult = remotes:WaitForChild("CookResult") :: RemoteEvent

-- The server creates leaderstats for us; wait for it and its values.
local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins") :: IntValue
local dogs = leaderstats:WaitForChild("Dogs") :: IntValue

-- === Build the UI ===
local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyUI"
gui.ResetOnSpawn = false

-- Stats readout (coins + dogs owned).
local stats = Instance.new("TextLabel")
stats.Size = UDim2.fromOffset(260, 48)
stats.Position = UDim2.fromOffset(20, 20)
stats.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
stats.BackgroundTransparency = 0.3
stats.TextColor3 = Color3.fromRGB(255, 255, 255)
stats.TextScaled = true
stats.Font = Enum.Font.GothamBold
stats.Parent = gui

-- Cook button.
local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(260, 58)
button.Position = UDim2.fromOffset(20, 76)
button.BackgroundColor3 = Color3.fromRGB(220, 120, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Text = string.format("🌭 Cook a Hot Dog (%d)", GameConfig.CookCost)
button.Parent = gui

-- Reveal label: shows the last hot dog you cooked, coloured by rarity.
local reveal = Instance.new("TextLabel")
reveal.Size = UDim2.fromOffset(260, 44)
reveal.Position = UDim2.fromOffset(20, 144)
reveal.BackgroundTransparency = 1
reveal.TextColor3 = Color3.fromRGB(255, 255, 255)
reveal.TextTransparency = 1
reveal.TextScaled = true
reveal.Font = Enum.Font.GothamBlack
reveal.Text = ""
reveal.Parent = gui

local function refreshStats()
	stats.Text = string.format("💰 %d    🌭 %d", coins.Value, dogs.Value)
end

coins.Changed:Connect(refreshStats)
dogs.Changed:Connect(refreshStats)
refreshStats()

button.Activated:Connect(function()
	cookHotDog:FireServer()
end)

-- Show the reveal, then fade it out.
cookResult.OnClientEvent:Connect(function(name: string, rarity: HotDogDex.Rarity)
	reveal.Text = string.format("%s  [%s]", name, rarity)
	reveal.TextColor3 = HotDogDex.colorFor(rarity)
	reveal.TextTransparency = 0
	-- Pop in, then fade over a second.
	TweenService:Create(reveal, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.6), {
		TextTransparency = 1,
	}):Play()
end)

gui.Parent = player:WaitForChild("PlayerGui")
