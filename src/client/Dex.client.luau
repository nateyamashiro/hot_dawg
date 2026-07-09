--!strict
-- Dex / collection UI (item 8, GDD §4.4). A toggleable grid of every hot dog in the
-- game: owned ones show their name in rarity colour, undiscovered ones are locked
-- silhouettes. Owned tiles carry a 📌 toggle — pinned dogs are held in the safe
-- vault first (manual vault selection; the server honours data.vaultPins). The
-- owned set comes from the server's InventoryUpdate snapshot (leaderstats only
-- carries counts, not which dogs). Untrusted display only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)
local Variants = require(ReplicatedStorage.Shared.Variants)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryUpdate = remotes:WaitForChild("InventoryUpdate") :: RemoteEvent
local setVaultPin = remotes:WaitForChild("SetVaultPin") :: RemoteEvent
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
grid.Size = UDim2.new(1, -24, 1, -84)
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

-- Latest server snapshot: inventory (composite keys) + which keys are vault-pinned.
local lastOwned: { [string]: number } = {}
local lastPins: { [string]: boolean } = {}

-- Every owned inventory key for a base dog ("Chicago Dog" matches "Chicago Dog#Gold").
local function ownedKeysFor(dogName: string): { string }
	local keys = {}
	for key, count in lastOwned do
		if count > 0 and Variants.baseName(key) == dogName then
			table.insert(keys, key)
		end
	end
	return keys
end

-- Build one tile per dog; keep a handle so we can flip owned/locked on updates.
-- Event-exclusive dogs get tiles TOO (the FOMO teaser) but are excluded from the
-- completion count — they're only obtainable while their weekly event runs.
type Tile = { frame: Frame, label: TextLabel, pin: TextButton, dog: HotDogDex.HotDog }
local roster: { HotDogDex.HotDog } = HotDogDex.all()
for _, dog in HotDogDex.eventDogs() do
	table.insert(roster, dog)
end
local tiles: { Tile } = {}
for i, dog in roster do
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

	-- 📌 vault-pin toggle (owned tiles only). One tap flips the whole dog family
	-- (base + every owned variant) with an explicit desired state, so a mixed
	-- pinned/unpinned family can't half-toggle.
	local pin = Instance.new("TextButton")
	pin.Size = UDim2.fromOffset(22, 22)
	pin.Position = UDim2.new(1, -24, 0, 2)
	pin.BackgroundTransparency = 1
	pin.TextScaled = true
	pin.Text = "📌"
	pin.Visible = false
	pin.Parent = frame
	pin.Activated:Connect(function()
		local keys = ownedKeysFor(dog.name)
		local anyPinned = false
		for _, key in keys do
			if lastPins[key] then
				anyPinned = true
				break
			end
		end
		for _, key in keys do
			setVaultPin:FireServer(key, not anyPinned)
		end
	end)

	table.insert(tiles, { frame = frame, label = label, pin = pin, dog = dog })
end

local pinHint = Instance.new("TextLabel")
pinHint.Size = UDim2.new(1, -24, 0, 22)
pinHint.Position = UDim2.new(0, 12, 1, -28)
pinHint.BackgroundTransparency = 1
pinHint.TextColor3 = MenuLayout.MutedText
pinHint.TextScaled = true
pinHint.Font = Enum.Font.Gotham
pinHint.TextXAlignment = Enum.TextXAlignment.Left
pinHint.Text = "📌 pins fill your safe vault first — vault dogs can't be stolen"
pinHint.Parent = panel

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

inventoryUpdate.OnClientEvent:Connect(function(owned: { [string]: number }, pins)
	lastOwned = if type(owned) == "table" then owned else {}
	lastPins = if type(pins) == "table" then pins else {}
	-- Aggregate composite keys down to base dogs: owning only "Chicago Dog#Gold"
	-- still lights up the Chicago Dog tile (and counts toward completion).
	local ownedBase: { [string]: boolean } = {}
	local pinnedBase: { [string]: boolean } = {}
	for key, count in lastOwned do
		if count > 0 then
			local base = Variants.baseName(key)
			ownedBase[base] = true
			if lastPins[key] then
				pinnedBase[base] = true
			end
		end
	end
	local ownedCount = 0
	local baseTotal = 0
	for _, tile in tiles do
		local has = ownedBase[tile.dog.name] == true
		if not tile.dog.eventOnly then
			baseTotal += 1
			if has then
				ownedCount += 1
			end
		end
		if has then
			tile.frame.BackgroundColor3 = HotDogDex.colorFor(tile.dog.rarity)
			tile.label.Text = tile.dog.name
			tile.label.TextColor3 = Color3.fromRGB(20, 20, 20)
		else
			tile.frame.BackgroundColor3 = MenuLayout.RowBg
			-- Event exclusives tease where they come from instead of a bare "???".
			tile.label.Text = if tile.dog.eventOnly then "🎉 Event\nreward!" else "???"
			tile.label.TextColor3 = MenuLayout.MutedText
		end
		tile.pin.Visible = has
		tile.pin.TextTransparency = if pinnedBase[tile.dog.name] then 0 else 0.6
	end
	-- Completion (and its one-time reward) is over the BASE roster only.
	completion.Text = string.format("%d / %d", ownedCount, baseTotal)
end)

gui.Parent = player:WaitForChild("PlayerGui")
requestState:FireServer() -- request the owned-dogs snapshot now that we're listening
