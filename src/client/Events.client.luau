--!strict
-- Weekly event panel (M4). Shows the live event (banner, points, timer) and lets the
-- player claim reward-track tiers. Untrusted display: renders the server's EventUpdate
-- snapshot and fires ClaimEventReward. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local eventUpdate = remotes:WaitForChild("EventUpdate") :: RemoteEvent
local claimEventReward = remotes:WaitForChild("ClaimEventReward") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyEvents"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Events", "🎉 Events")
local panel, content = MenuLayout.makePanel(gui, "🎉 Weekly Event")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 60)
status.LayoutOrder = 1
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(220, 220, 230)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Text = "Loading…"
status.Parent = content

local claimBtn = Instance.new("TextButton")
claimBtn.Size = UDim2.new(1, 0, 0, 40)
claimBtn.LayoutOrder = 2
claimBtn.BackgroundColor3 = Color3.fromRGB(70, 90, 55)
claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
claimBtn.TextScaled = true
claimBtn.Font = Enum.Font.GothamBold
claimBtn.Text = "Claim reward"
claimBtn.Parent = content
claimBtn.Activated:Connect(function()
	claimEventReward:FireServer()
end)

eventUpdate.OnClientEvent:Connect(function(ev, points)
	-- TODO(M4-event): render the reward-track tiers + a live countdown from the
	-- third arg (secondsLeft), and per-tier claim state.
	if ev then
		status.Text = ev.label .. "\n" .. tostring(points) .. " pts"
	else
		status.Text = "No active event right now."
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
