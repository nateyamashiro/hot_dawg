--!strict
-- Leaderboards panel (M4). Shows global top-N for richest / most steals / rarest.
-- Untrusted display: renders the server's LeaderboardUpdate snapshot (cached top-N
-- read from OrderedDataStore) and can request a refresh. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local leaderboardUpdate = remotes:WaitForChild("LeaderboardUpdate") :: RemoteEvent
local requestLeaderboard = remotes:WaitForChild("RequestLeaderboard") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyLeaderboards"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Leaderboards", "🏆 Ranks")
local panel, content = MenuLayout.makePanel(gui, "🏆 Leaderboards")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	requestLeaderboard:FireServer("coins") -- refresh the board on open
end)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 60)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(220, 220, 230)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Text = "Loading…"
status.Parent = content

leaderboardUpdate.OnClientEvent:Connect(function(tops)
	-- TODO(M4-lb): render three tabs (coins/steals/rarest), a row per entry with
	-- rank + display name + value, and highlight the local player's rank.
	local coins = type(tops) == "table" and tops.coins or nil
	local n = coins and #coins or 0
	status.Text = "Richest: " .. tostring(n) .. " ranked (scaffold)"
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
