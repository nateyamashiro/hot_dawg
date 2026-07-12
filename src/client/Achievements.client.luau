--!strict
-- Achievements panel (M4). A grid of milestone goals with progress + a claim button
-- per completed one. Untrusted display: renders the server's AchievementUpdate
-- snapshot and fires ClaimAchievement. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
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
	for i, ach in list do
		local done = ach.progress >= ach.target
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, 0, 0, 44)
		row.LayoutOrder = i
		row.BackgroundColor3 = if ach.claimed
			then MenuLayout.Disabled
			elseif done then MenuLayout.SuccessBg
			else MenuLayout.AccentBg
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.TextScaled = true
		row.Font = Enum.Font.GothamBold
		row.Text = if ach.claimed
			then "✅ " .. ach.label
			elseif done then "🎁 "
				.. ach.label
				.. " — claim +"
				.. Format.comma(ach.reward)
				.. "!"
			else string.format(
				"%s  (%d/%d) → +%s",
				tostring(ach.label),
				ach.progress,
				ach.target,
				Format.comma(ach.reward)
			)
		row.Parent = content

		-- Slim progress bar along the bottom edge of the row.
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Position = UDim2.fromScale(0, 1)
		bar.Size = UDim2.new(math.clamp(ach.progress / math.max(ach.target, 1), 0, 1), 0, 0, 4)
		bar.BackgroundColor3 = MenuLayout.SuccessText
		bar.BorderSizePixel = 0
		bar.Parent = row

		-- Claim only fires when there's actually something to claim (server
		-- re-validates anyway; this just avoids junk requests + error toasts).
		row.Activated:Connect(function()
			if done and not ach.claimed then
				claimAchievement:FireServer(ach.id)
			end
		end)
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
