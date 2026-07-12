--!strict
-- Leaderboards panel (M4). Global top-N for richest / most steals / rarest, as three
-- tabs over the server's cached OrderedDataStore snapshot. Untrusted display: renders
-- LeaderboardUpdate and can request a refresh. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local leaderboardUpdate = remotes:WaitForChild("LeaderboardUpdate") :: RemoteEvent
local requestLeaderboard = remotes:WaitForChild("RequestLeaderboard") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

type Entry = { name: string, value: number }
type Tops = { [string]: { Entry } }

local TABS = {
	{ id = "coins", label = "💰 Richest" },
	{ id = "steals", label = "🥷 Steals" },
	{ id = "rarest", label = "🌭 Rarest" },
}
local MAX_ROWS = 10

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyLeaderboards"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Leaderboards", "🏆 Ranks")
local panel, content = MenuLayout.makePanel(gui, "🏆 Leaderboards")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		requestLeaderboard:FireServer() -- refresh the snapshot on open
	end
end)

-- Tab strip (one horizontal row above the entry rows).
local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, 0, 0, 36)
tabRow.LayoutOrder = 1
tabRow.BackgroundTransparency = 1
tabRow.Parent = content

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabRow

local activeTab = "coins"
local latestTops: Tops = {}
local tabButtons: { [string]: TextButton } = {}

-- Pre-built entry rows, retexted on every update (no churn).
local rows: { TextLabel } = {}
for i = 1, MAX_ROWS do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, 0, 0, 26)
	row.LayoutOrder = 1 + i
	row.BackgroundColor3 = MenuLayout.RowBg
	row.TextColor3 = MenuLayout.BodyText
	row.TextScaled = true
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Font = Enum.Font.Gotham
	row.Text = ""
	row.Visible = false
	row.Parent = content
	MenuLayout.addChrome(row, 6)
	table.insert(rows, row)
end

local function formatValue(tab: string, value: number): string
	if tab == "rarest" then
		-- The server stores best-unit income ×100 (OrderedDataStore is integer-only).
		return Format.comma(value / 100, 1) .. "/s"
	end
	return Format.comma(value)
end

local function render()
	-- styleButton is one-shot (it stacks chrome/connections), so tabs only flip
	-- colours here; the chrome was applied once at creation.
	for id, btn in tabButtons do
		btn.BackgroundColor3 = if id == activeTab then MenuLayout.SuccessBg else MenuLayout.AccentBg
	end
	local entries = latestTops[activeTab] or {}
	for i, row in rows do
		local entry = entries[i]
		if entry then
			local mine = entry.name == player.Name
			row.Visible = true
			row.Text = string.format(
				" %2d. %s%s — %s",
				i,
				entry.name,
				if mine then "  ⭐" else "",
				formatValue(activeTab, entry.value)
			)
			row.BackgroundColor3 = if mine then MenuLayout.SuccessBg else MenuLayout.RowBg
			row.Font = if mine then Enum.Font.GothamBold else Enum.Font.Gotham
		else
			row.Visible = i == 1 -- keep one row for the empty-board message
			if i == 1 then
				row.Text = " No entries yet — be the first on the board!"
				row.BackgroundColor3 = MenuLayout.RowBg
				row.Font = Enum.Font.Gotham
			end
		end
	end
end

for i, tab in TABS do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1 / #TABS, -4, 1, 0)
	btn.LayoutOrder = i
	btn.Text = tab.label
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundColor3 = MenuLayout.AccentBg
	btn.BorderSizePixel = 0
	btn.Parent = tabRow
	MenuLayout.addChrome(btn, 8)
	tabButtons[tab.id] = btn
	btn.Activated:Connect(function()
		activeTab = tab.id
		render()
	end)
end

leaderboardUpdate.OnClientEvent:Connect(function(tops)
	if type(tops) ~= "table" then
		return
	end
	latestTops = tops
	render()
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
