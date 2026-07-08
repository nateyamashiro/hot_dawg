--!strict
-- Daily streak + missions UI (item 10, GDD §4.7). Shows the login streak and its
-- next reward (claimable once per day) plus the active daily missions with progress
-- and per-mission claim buttons. Untrusted display: it renders the server's
-- DailyUpdate snapshot and fires ClaimDaily / ClaimMission requests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local dailyUpdate = remotes:WaitForChild("DailyUpdate") :: RemoteEvent
local claimDaily = remotes:WaitForChild("ClaimDaily") :: RemoteEvent
local claimMission = remotes:WaitForChild("ClaimMission") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

type Mission = {
	id: string,
	label: string,
	target: number,
	progress: number,
	claimed: boolean,
	reward: number,
}
type DailyState = {
	streak: number,
	canClaimStreak: boolean,
	nextReward: number,
	missions: { Mission },
}

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyDaily"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- Toggle button — slot owned in the shared MenuLayout row (P-D themed).
local toggle = MenuLayout.makePrimaryButton(gui, "Daily", "📅 Daily")

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(460, 380)
panel.Position = UDim2.new(0.5, -230, 0.5, -190)
panel.Visible = false
panel.Parent = gui
MenuLayout.themePanel(panel)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 40)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.TextColor3 = MenuLayout.BodyText
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Font = MenuLayout.TitleFont
title.Text = "📅 Daily"
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(36, 36)
close.Position = UDim2.new(1, -42, 0, 10)
close.Text = "✕"
close.Parent = panel
MenuLayout.styleButton(close, "danger")
close.Activated:Connect(function()
	panel.Visible = false
end)

-- Streak row.
local streakLabel = Instance.new("TextLabel")
streakLabel.Size = UDim2.new(1, -24, 0, 34)
streakLabel.Position = UDim2.fromOffset(12, 52)
streakLabel.BackgroundTransparency = 1
streakLabel.TextColor3 = MenuLayout.BodyText
streakLabel.TextXAlignment = Enum.TextXAlignment.Left
streakLabel.TextScaled = true
streakLabel.Font = Enum.Font.GothamBold
streakLabel.Text = "🔥 Streak: -"
streakLabel.Parent = panel

local claimStreakBtn = Instance.new("TextButton")
claimStreakBtn.Size = UDim2.fromOffset(220, 40)
claimStreakBtn.Position = UDim2.fromOffset(12, 90)
claimStreakBtn.Text = "Claim daily reward"
claimStreakBtn.Parent = panel
MenuLayout.styleButton(claimStreakBtn, "success")
claimStreakBtn.Activated:Connect(function()
	claimDaily:FireServer()
end)

-- Missions container (rows rebuilt on each update).
local missionsFrame = Instance.new("Frame")
missionsFrame.Size = UDim2.new(1, -24, 1, -150)
missionsFrame.Position = UDim2.fromOffset(12, 142)
missionsFrame.BackgroundTransparency = 1
missionsFrame.Parent = panel

local missionsList = Instance.new("UIListLayout")
missionsList.Padding = UDim.new(0, 8)
missionsList.SortOrder = Enum.SortOrder.LayoutOrder
missionsList.Parent = missionsFrame

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local function renderMissions(missions: { Mission })
	for _, child in missionsFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, m in missions do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 44)
		row.LayoutOrder = i
		row.BackgroundColor3 = MenuLayout.RowBg
		row.Parent = missionsFrame
		MenuLayout.addChrome(row, 8)

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, -110, 1, 0)
		text.Position = UDim2.fromOffset(8, 0)
		text.BackgroundTransparency = 1
		text.TextColor3 = MenuLayout.BodyText
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.TextScaled = true
		text.Font = Enum.Font.Gotham
		text.Text = string.format("%s  (%d/%d)  +💰%d", m.label, m.progress, m.target, m.reward)
		text.Parent = row

		local claim = Instance.new("TextButton")
		claim.Size = UDim2.fromOffset(96, 36)
		claim.Position = UDim2.new(1, -100, 0.5, -18)
		claim.TextColor3 = Color3.fromRGB(255, 255, 255)
		claim.TextScaled = true
		claim.Font = Enum.Font.GothamBold
		claim.Parent = row
		MenuLayout.addChrome(claim, 8)

		local done = m.progress >= m.target
		if m.claimed then
			claim.Text = "✓ Done"
			claim.BackgroundColor3 = MenuLayout.Disabled
		elseif done then
			claim.Text = "Claim"
			claim.BackgroundColor3 = MenuLayout.SuccessBg
			claim.Activated:Connect(function()
				claimMission:FireServer(m.id)
			end)
		else
			claim.Text = "…"
			claim.BackgroundColor3 = MenuLayout.Disabled
		end
	end
end

dailyUpdate.OnClientEvent:Connect(function(state: DailyState)
	streakLabel.Text = string.format("🔥 Streak: %d days", state.streak)
	if state.canClaimStreak then
		claimStreakBtn.Text =
			string.format("Claim +💰%d (Day %d)", state.nextReward, state.streak + 1)
		claimStreakBtn.BackgroundColor3 = MenuLayout.SuccessBg
		claimStreakBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		claimStreakBtn.Active = true
		claimStreakBtn.AutoButtonColor = true
	else
		claimStreakBtn.Text = "✓ Claimed today"
		claimStreakBtn.BackgroundColor3 = MenuLayout.Disabled
		claimStreakBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		claimStreakBtn.AutoButtonColor = false
	end
	renderMissions(state.missions)
end)

gui.Parent = player:WaitForChild("PlayerGui")
requestState:FireServer() -- request streak + missions now that we're listening
