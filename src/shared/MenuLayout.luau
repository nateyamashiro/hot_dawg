--!strict
-- Shared layout math for the bottom menu row (client UI). Historically every
-- client hardcoded `ROW_START_X = -370 + slot*150`, so adding a button meant
-- editing four files. This module owns the row: a canonical ordered list of
-- PRIMARY slots (auto-centred for however many there are) plus a "⋯ More" tray
-- for the growing set of secondary panels (M4-M6), so the primary row never
-- overflows. Lives in Shared so every client agrees on positions.

local MenuLayout = {}

-- Pixel geometry (matches the original hand-tuned values).
MenuLayout.BUTTON_W = 140
MenuLayout.BUTTON_H = 40
MenuLayout.SPACING = 150
MenuLayout.ROW_Y = -150 -- offset from the bottom edge (UDim2 Y.Offset at scale 1)

-- Canonical primary row, left → right. Index in this list IS the slot number.
-- "More" opens the tray of secondary panels below.
MenuLayout.PRIMARY = { "Upgrades", "Rebirth", "Dex", "Daily", "Shop", "More" }

-- Secondary panels reached via the "⋯ More" tray (stacked above the More button).
MenuLayout.TRAY = {
	"PrestigeShop",
	"Fusion",
	"Events",
	"Leaderboards",
	"Achievements",
	"Codes",
	"Passes",
	"Cosmetics",
	"Trade",
}

-- Slot index (0-based) of a named primary button, or nil if it's not primary.
function MenuLayout.slotOf(name: string): number?
	for i, n in MenuLayout.PRIMARY do
		if n == name then
			return i - 1
		end
	end
	return nil
end

-- Left edge X (offset from screen centre) so the whole PRIMARY row is centred.
local function rowStartX(): number
	local n = #MenuLayout.PRIMARY
	return -(((n - 1) / 2) * MenuLayout.SPACING + MenuLayout.BUTTON_W / 2)
end

-- Bottom-row position for a primary button at 0-based `slot`.
function MenuLayout.primaryPosition(slot: number): UDim2
	return UDim2.new(0.5, rowStartX() + slot * MenuLayout.SPACING, 1, MenuLayout.ROW_Y)
end

-- Position for tray item `index` (0-based): a vertical stack rising above the
-- "More" button's slot.
function MenuLayout.trayPosition(index: number): UDim2
	local moreSlot = MenuLayout.slotOf("More") or (#MenuLayout.PRIMARY - 1)
	local x = rowStartX() + moreSlot * MenuLayout.SPACING
	local y = MenuLayout.ROW_Y - (index + 1) * (MenuLayout.BUTTON_H + 6)
	return UDim2.new(0.5, x, 1, y)
end

-- Player attribute the "⋯ More" button toggles; tray toggles show/hide off it, so
-- the panels stay decoupled LocalScripts (no cross-script signalling needed).
MenuLayout.TRAY_ATTR = "GlizzyTrayOpen"

-- 0-based index of a named tray panel, or nil if it's not in the tray.
function MenuLayout.trayIndexOf(name: string): number?
	for i, n in MenuLayout.TRAY do
		if n == name then
			return i - 1
		end
	end
	return nil
end

-- Client helper: build a tray toggle button for a secondary panel, positioned in
-- the stack and auto-shown/hidden with the More tray. Keeps each panel client tiny.
function MenuLayout.makeTrayToggle(
	parent: Instance,
	player: Player,
	name: string,
	text: string
): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(MenuLayout.BUTTON_W, MenuLayout.BUTTON_H)
	btn.Position = MenuLayout.trayPosition(MenuLayout.trayIndexOf(name) or 0)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.Visible = player:GetAttribute(MenuLayout.TRAY_ATTR) == true
	btn.Parent = parent
	player:GetAttributeChangedSignal(MenuLayout.TRAY_ATTR):Connect(function()
		btn.Visible = player:GetAttribute(MenuLayout.TRAY_ATTR) == true
	end)
	return btn
end

-- Client helper: a hidden, centred panel with a title bar, close button, and a
-- scrolling content column (UIListLayout). Returns (panel, content). Every new
-- feature panel builds on this so they look consistent and stay short.
function MenuLayout.makePanel(parent: Instance, title: string): (Frame, ScrollingFrame)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(460, 380)
	frame.Position = UDim2.new(0.5, -230, 0.5, -190)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	frame.BackgroundTransparency = 0.05
	frame.Visible = false
	frame.Parent = parent

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -60, 0, 44)
	titleLabel.Position = UDim2.fromOffset(12, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 230, 150)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = title
	titleLabel.Parent = frame

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -42, 0, 10)
	close.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextScaled = true
	close.Font = Enum.Font.GothamBold
	close.Text = "✕"
	close.Parent = frame
	close.Activated:Connect(function()
		frame.Visible = false
	end)

	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(1, -24, 1, -64)
	content.Position = UDim2.fromOffset(12, 56)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 6
	content.CanvasSize = UDim2.fromOffset(0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	return frame, content
end

return MenuLayout
