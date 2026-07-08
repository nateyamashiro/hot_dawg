--!strict
-- Shared layout math + THE design-system chrome for the menu UI (P-D restyle).
-- Historically every client hardcoded `ROW_START_X = -370 + slot*150`; this module
-- owns the row (a canonical ordered PRIMARY list, auto-centred) plus the "⋯ More"
-- tray of secondary panels. Since the P-D restyle it also owns the Theme.UI look:
-- every panel is a draggable Cream window with a ketchup-gradient title bar, chunky
-- UIStroke outlines, FredokaOne titles, and bouncing buttons — so 15+ feature
-- clients stay tiny and consistent. Lives in Shared so every client agrees.

local UserInputService = game:GetService("UserInputService")

local Sfx = require(script.Parent.Sfx)
local Theme = require(script.Parent.Theme)

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
	"Build",
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

-- === P-D design tokens, re-exported for panel clients (which already require this
-- module). Panel BODY colors — dark warm text and light warm rows on Cream panels.
MenuLayout.BodyText = Theme.UI.BodyText
MenuLayout.MutedText = Color3.fromRGB(150, 122, 96) -- locked/undiscovered/secondary
MenuLayout.RowBg = Theme.UI.RowBg
MenuLayout.SuccessText = Color3.fromRGB(58, 122, 34) -- "owned!" style good-news text
MenuLayout.SuccessBg = Color3.fromRGB(96, 164, 50) -- deep relish; white text reads on it
MenuLayout.AccentBg = Theme.Palette.MustardDark -- secondary action buttons (white text)
MenuLayout.DangerBg = Theme.Palette.KetchupDark -- destructive action buttons
MenuLayout.Disabled = Color3.fromRGB(150, 134, 108) -- claimed/disabled buttons

-- Rounded corner + the chunky cartoon outline, per Theme.UI.
function MenuLayout.addChrome(gui: GuiObject, corner: number)
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, corner)
	uiCorner.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = Theme.UI.StrokeThickness
	stroke.Color = Theme.UI.StrokeColor
	stroke.Parent = gui
end

-- Style a button into the design language: "primary" (mustard + dark text, the
-- default), "success" (relish), "danger" (ketchup + white). Adds corner, stroke,
-- the cartoon bounce, and the UI click sound.
function MenuLayout.styleButton(btn: TextButton, kind: string?)
	if kind == "danger" then
		btn.BackgroundColor3 = Theme.UI.ButtonDanger
		btn.TextColor3 = Theme.UI.ButtonDangerText
	elseif kind == "success" then
		btn.BackgroundColor3 = Theme.UI.ButtonSuccess
		btn.TextColor3 = Theme.UI.ButtonSuccessText
	else
		btn.BackgroundColor3 = Theme.UI.ButtonPrimary
		btn.TextColor3 = Theme.UI.ButtonPrimaryText
	end
	btn.Font = Theme.UI.TitleFont
	btn.TextScaled = true
	btn.BorderSizePixel = 0
	MenuLayout.addChrome(btn, Theme.UI.CornerButton)
	Theme.applyBounce(btn)
	btn.Activated:Connect(function()
		Sfx.play("UIClick")
	end)
end

-- Theme a hand-rolled panel frame (Dex/Daily/Shop keep custom layouts): Cream body,
-- panel corner + stroke. Content colors are the caller's job (use the tokens above).
function MenuLayout.themePanel(frame: Frame)
	frame.BackgroundColor3 = Theme.UI.PanelBg
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	MenuLayout.addChrome(frame, Theme.UI.CornerPanel)
end

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

-- A styled bottom-row button in the named PRIMARY slot. All row clients build their
-- toggle through this so the whole row shares the sticker-bomb look.
function MenuLayout.makePrimaryButton(parent: Instance, name: string, text: string): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(MenuLayout.BUTTON_W, MenuLayout.BUTTON_H)
	btn.Position = MenuLayout.primaryPosition(MenuLayout.slotOf(name) or 0)
	btn.Text = text
	btn.Parent = parent
	MenuLayout.styleButton(btn, "primary")
	return btn
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
	btn.Text = text
	btn.Visible = player:GetAttribute(MenuLayout.TRAY_ATTR) == true
	btn.Parent = parent
	MenuLayout.styleButton(btn, "primary")
	player:GetAttributeChangedSignal(MenuLayout.TRAY_ATTR):Connect(function()
		btn.Visible = player:GetAttribute(MenuLayout.TRAY_ATTR) == true
	end)
	return btn
end

-- Make `dragHandle` drag `moveTarget` around the screen (used by makeWindow's title
-- bar). Standard offset-delta drag; works for mouse + touch.
local function makeDraggable(dragHandle: GuiObject, moveTarget: GuiObject)
	local dragging = false
	local dragStart = Vector3.zero
	local startPos = moveTarget.Position
	dragHandle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = moveTarget.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart
			moveTarget.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- Client helper (the window system, fully themed at P-D): a hidden, centred Cream
-- window with a ketchup-gradient title bar that doubles as a DRAG handle, a minimize
-- button (collapse to the bar), a close button, and a scrolling content column
-- (UIListLayout). Windows pop open (Theme.popOpen) with the UIOpen sound. Returns
-- (frame, content) — every feature panel builds on this so the screen stays
-- consistent and uncluttered.
function MenuLayout.makeWindow(parent: Instance, title: string): (Frame, ScrollingFrame)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(460, 380)
	frame.Position = UDim2.new(0.5, -230, 0.5, -190)
	frame.Visible = false
	frame.Parent = parent
	MenuLayout.themePanel(frame)

	-- Title bar doubles as the drag handle. Ketchup gradient + white FredokaOne.
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 44)
	titleBar.BackgroundColor3 = Theme.UI.TitleBar
	titleBar.BorderSizePixel = 0
	titleBar.Parent = frame
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, Theme.UI.CornerPanel)
	barCorner.Parent = titleBar
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Theme.UI.TitleBar, Theme.UI.TitleBarBottom)
	gradient.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -96, 1, -8)
	titleLabel.Position = UDim2.fromOffset(14, 4)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Theme.UI.TitleText
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextScaled = true
	titleLabel.Font = Theme.UI.TitleFont
	titleLabel.Text = title
	titleLabel.Parent = titleBar

	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(1, -24, 1, -64)
	content.Position = UDim2.fromOffset(12, 52)
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

	-- Minimize: collapse the window to just its title bar (content hidden), toggle back.
	local minimize = Instance.new("TextButton")
	minimize.Size = UDim2.fromOffset(36, 36)
	minimize.Position = UDim2.new(1, -84, 0, 4)
	minimize.Text = "—"
	minimize.Parent = titleBar
	MenuLayout.styleButton(minimize, "primary")

	local fullSize = frame.Size
	local minimized = false
	minimize.Activated:Connect(function()
		minimized = not minimized
		content.Visible = not minimized
		minimize.Text = minimized and "▢" or "—"
		frame.Size = minimized and UDim2.fromOffset(fullSize.X.Offset, 44) or fullSize
	end)

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -42, 0, 4)
	close.Text = "✕"
	close.Parent = titleBar
	MenuLayout.styleButton(close, "danger")
	close.Activated:Connect(function()
		frame.Visible = false
	end)

	makeDraggable(titleBar, frame)

	-- Cartoon open: 0.85 → 1.0 pop + the UIOpen sound whenever the window shows.
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if frame.Visible then
			Theme.popOpen(frame)
			Sfx.play("UIOpen")
		end
	end)

	return frame, content
end

-- Back-compat panel helper: since the P-D restyle this IS the window system — every
-- tray panel that called makePanel got dragging, minimize, and the theme for free.
function MenuLayout.makePanel(parent: Instance, title: string): (Frame, ScrollingFrame)
	return MenuLayout.makeWindow(parent, title)
end

return MenuLayout
