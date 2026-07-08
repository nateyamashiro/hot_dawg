--!strict
-- Dex / collection UI (item 8, GDD §4.4). A toggleable grid of every hot dog in the
-- game: owned ones show their name in rarity colour, undiscovered ones are locked
-- silhouettes. The owned set comes from the server's InventoryUpdate snapshot
-- (leaderstats only carries counts, not which dogs). Untrusted display only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryUpdate = remotes:WaitForChild("InventoryUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyDex"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- Toggle button — slot owned in the shared MenuLayout row (P-D themed).
local toggle = MenuLayout.makePrimaryButton(gui, "Dex", "📖 Dex")

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(560, 400)
panel.Position = UDim2.new(0.5, -280, 0.5, -200)
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
title.Text = "📖 Hot Dog Dex"
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

local grid = Instance.new("ScrollingFrame")
grid.Size = UDim2.new(1, -24, 1, -60)
grid.Position = UDim2.fromOffset(12, 52)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollBarThickness = 8
grid.CanvasSize = UDim2.new()
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(128, 54)
layout.CellPadding = UDim2.fromOffset(8, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

-- Build one tile per dog; keep a handle so we can flip owned/locked on updates.
type Tile = { frame: Frame, label: TextLabel, dog: HotDogDex.HotDog }
local tiles: { Tile } = {}
for i, dog in HotDogDex.all() do
	local frame = Instance.new("Frame")
	frame.LayoutOrder = i
	frame.BackgroundColor3 = MenuLayout.RowBg
	frame.Parent = grid
	MenuLayout.addChrome(frame, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = MenuLayout.MutedText
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = "???"
	label.TextWrapped = true
	label.Parent = frame

	table.insert(tiles, { frame = frame, label = label, dog = dog })
end

local completion = Instance.new("TextLabel")
completion.Size = UDim2.fromOffset(240, 40)
completion.Position = UDim2.fromOffset(200, 8)
completion.BackgroundTransparency = 1
completion.TextColor3 = MenuLayout.SuccessText
completion.TextScaled = true
completion.Font = Enum.Font.GothamBold
completion.Text = ""
completion.Parent = panel

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

inventoryUpdate.OnClientEvent:Connect(function(owned: { [string]: number })
	local ownedCount = 0
	for _, tile in tiles do
		local has = (owned[tile.dog.name] or 0) > 0
		if has then
			ownedCount += 1
			tile.frame.BackgroundColor3 = HotDogDex.colorFor(tile.dog.rarity)
			tile.label.Text = tile.dog.name
			tile.label.TextColor3 = Color3.fromRGB(20, 20, 20)
		else
			tile.frame.BackgroundColor3 = MenuLayout.RowBg
			tile.label.Text = "???"
			tile.label.TextColor3 = MenuLayout.MutedText
		end
	end
	completion.Text = string.format("%d / %d", ownedCount, #tiles)
end)

gui.Parent = player:WaitForChild("PlayerGui")
requestState:FireServer() -- request the owned-dogs snapshot now that we're listening
