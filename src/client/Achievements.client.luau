--!strict
-- Achievements panel (M4). A grid of milestone goals with progress + a claim button
-- per completed one. Untrusted display: renders the server's AchievementUpdate
-- snapshot and fires ClaimAchievement. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local achievementUpdate = remotes:WaitForChild("AchievementUpdate") :: RemoteEvent
local claimAchievement = remotes:WaitForChild("ClaimAchievement") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyAchievements"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Achievements", "🏅 Goals")
local panel, content = MenuLayout.makePanel(gui, "🏅 Achievements")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

achievementUpdate.OnClientEvent:Connect(function(list)
	for _, child in content:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if type(list) ~= "table" then
		return
	end
	-- TODO(M4-ach): show a real progress bar + only enable claim when complete.
	for i, ach in list do
		local done = ach.progress >= ach.target
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.LayoutOrder = i
		row.BackgroundColor3 = if ach.claimed
			then Color3.fromRGB(45, 45, 55)
			elseif done then Color3.fromRGB(70, 90, 55)
			else Color3.fromRGB(55, 55, 75)
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.TextScaled = true
		row.Font = Enum.Font.GothamBold
		row.Text = ach.label
			.. "  ("
			.. tostring(ach.progress)
			.. "/"
			.. tostring(ach.target)
			.. ")"
		row.Parent = content
		row.Activated:Connect(function()
			claimAchievement:FireServer(ach.id)
		end)
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
