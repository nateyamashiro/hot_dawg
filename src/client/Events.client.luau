--!strict
-- Weekly event panel (M4). Shows the live event (banner, modifier blurb, points,
-- live countdown) plus the reward track — one row per tier: ✅ claimed, green when
-- claimable, muted while locked. Untrusted display: renders the server's EventUpdate
-- snapshot and fires ClaimEventReward. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local eventUpdate = remotes:WaitForChild("EventUpdate") :: RemoteEvent
local claimEventReward = remotes:WaitForChild("ClaimEventReward") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

-- What each modifier actually does, in player words (server math lives in Main).
local MODIFIER_BLURBS: { [string]: string } = {
	income2x = "All income is DOUBLED while this event runs!",
	freeCookBursts = "Free glizzies rain on everyone every few minutes!",
	cookHalfPrice = "Cook ×10 costs HALF PRICE all event long!",
}

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyEvents"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Events", "🎉 Events")
local panel, content = MenuLayout.makePanel(gui, "🎉 Weekly Event")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local banner = Instance.new("TextLabel")
banner.Size = UDim2.new(1, 0, 0, 34)
banner.LayoutOrder = 1
banner.BackgroundTransparency = 1
banner.TextColor3 = MenuLayout.BodyText
banner.TextScaled = true
banner.Font = MenuLayout.TitleFont
banner.Text = "Loading…"
banner.Parent = content

local blurb = Instance.new("TextLabel")
blurb.Size = UDim2.new(1, 0, 0, 24)
blurb.LayoutOrder = 2
blurb.BackgroundTransparency = 1
blurb.TextColor3 = MenuLayout.MutedText
blurb.TextScaled = true
blurb.Font = Enum.Font.Gotham
blurb.TextWrapped = true
blurb.Text = ""
blurb.Parent = content

local pointsLabel = Instance.new("TextLabel")
pointsLabel.Size = UDim2.new(1, 0, 0, 26)
pointsLabel.LayoutOrder = 3
pointsLabel.BackgroundTransparency = 1
pointsLabel.TextColor3 = MenuLayout.BodyText
pointsLabel.TextScaled = true
pointsLabel.Font = Enum.Font.GothamBold
pointsLabel.Text = ""
pointsLabel.Parent = content

-- One row per reward tier (the track is static config; only row STATE changes).
local tierRows: { TextLabel } = {}
for i, need in GameConfig.EventRewardTiers do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.LayoutOrder = 3 + i
	row.BackgroundColor3 = MenuLayout.RowBg
	row.TextColor3 = MenuLayout.BodyText
	row.TextScaled = true
	row.Font = Enum.Font.Gotham
	row.Text = string.format(
		"Tier %d — %d pts → +%d coins",
		i,
		need,
		GameConfig.EventRewardCoins[i] or 0
	)
	row.Parent = content
	MenuLayout.addChrome(row, 8)
	table.insert(tierRows, row)
end

local claimBtn = Instance.new("TextButton")
claimBtn.Size = UDim2.new(1, 0, 0, 40)
claimBtn.LayoutOrder = 20
claimBtn.Text = "Claim rewards"
claimBtn.Parent = content
MenuLayout.styleButton(claimBtn, "success")
claimBtn.Activated:Connect(function()
	claimEventReward:FireServer()
end)

-- Latest snapshot (deadline derived from secondsLeft so the countdown ticks locally).
local points = 0
local claimed = 0
local deadline = 0
local hasEvent = false

local function formatLeft(seconds: number): string
	if seconds >= 24 * 3600 then
		return string.format("%dd %dh", seconds // (24 * 3600), (seconds % (24 * 3600)) // 3600)
	elseif seconds >= 3600 then
		return string.format("%dh %dm", seconds // 3600, (seconds % 3600) // 60)
	end
	return string.format("%dm %ds", seconds // 60, seconds % 60)
end

local function render()
	if not hasEvent then
		pointsLabel.Text = ""
		return
	end
	local left = math.max(0, deadline - os.time())
	pointsLabel.Text = string.format("⭐ %d pts   ·   ⏳ %s left", points, formatLeft(left))
	local claimable = 0
	for i, row in tierRows do
		local need = GameConfig.EventRewardTiers[i]
		if i <= claimed then
			row.TextColor3 = MenuLayout.MutedText
			row.BackgroundColor3 = MenuLayout.Disabled
			row.Text = string.format("✅ Tier %d claimed", i)
		elseif points >= need then
			row.TextColor3 = MenuLayout.BodyText
			row.BackgroundColor3 = MenuLayout.SuccessBg
			row.Text = string.format(
				"🎁 Tier %d READY — +%d coins",
				i,
				GameConfig.EventRewardCoins[i] or 0
			)
			claimable += GameConfig.EventRewardCoins[i] or 0
		else
			row.TextColor3 = MenuLayout.BodyText
			row.BackgroundColor3 = MenuLayout.RowBg
			row.Text = string.format(
				"Tier %d — %d pts → +%d coins",
				i,
				need,
				GameConfig.EventRewardCoins[i] or 0
			)
		end
	end
	claimBtn.Text = if claimable > 0
		then string.format("Claim rewards (+%d coins)", claimable)
		else "Nothing to claim yet"
end

eventUpdate.OnClientEvent:Connect(function(ev, pts, secondsLeft, claimedCount)
	if ev and type(ev) == "table" then
		hasEvent = true
		banner.Text = tostring(ev.label)
		blurb.Text = MODIFIER_BLURBS[tostring(ev.modifier)] or ""
		points = if type(pts) == "number" then pts else 0
		claimed = if type(claimedCount) == "number" then claimedCount else 0
		deadline = os.time() + (if type(secondsLeft) == "number" then secondsLeft else 0)
	else
		hasEvent = false
		banner.Text = "No active event right now."
		blurb.Text = ""
	end
	render()
end)

-- Tick the countdown locally between server pushes (only while someone's looking).
task.spawn(function()
	while true do
		task.wait(1)
		if panel.Visible and hasEvent then
			render()
		end
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
