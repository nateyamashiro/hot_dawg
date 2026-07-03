---
name: ProximityPrompt
last_updated: 2026-07-02T02:14:37Z
inherits:
  - Instance
  - Object
type: class
memory_category: Instances
summary: "An object that lets you prompt players to interact with an object in the 3D world."
---

# Class: ProximityPrompt

> An object that lets you prompt players to interact with an object in the 3D
> world.

## Description

The **ProximityPrompt** instance lets you prompt players to interact with an
object in the 3D world, such as opening a door or picking up an item. A
[ProximityPrompt](/docs/reference/engine/classes/ProximityPrompt.md) object works when parented to a [BasePart](/docs/reference/engine/classes/BasePart.md),
[Attachment](/docs/reference/engine/classes/Attachment.md), or [Model](/docs/reference/engine/classes/Model.md) (with
[PrimaryPart](/docs/reference/engine/classes/Model.md) set) in the workspace. When the player's
character approaches, a UI appears to prompt them for input.

Prompts consist of three primary elements, each of which can be controlled by
the noted properties. The default UI can be swapped out for your own custom
appearance as outlined in [Style](/docs/reference/engine/classes/ProximityPrompt.md).

| Property | Description | Default |
| --- | --- | --- |
| [ObjectText](/docs/reference/engine/classes/ProximityPrompt.md) | An optional name for the object being interacted with. | |
| [ActionText](/docs/reference/engine/classes/ProximityPrompt.md) | An optional action name shown to the player. | Interact |
| [KeyboardKeyCode](/docs/reference/engine/classes/ProximityPrompt.md) | The keyboard key which will trigger the prompt. | E |
| [GamepadKeyCode](/docs/reference/engine/classes/ProximityPrompt.md) | The gamepad button which will trigger the prompt. | ButtonX |

You can connect to proximity prompt events either on the
[ProximityPrompt](/docs/reference/engine/classes/ProximityPrompt.md) object itself or globally through
[ProximityPromptService](/docs/reference/engine/classes/ProximityPromptService.md). The [ProximityPromptService](/docs/reference/engine/classes/ProximityPromptService.md) allows you
to manage all proximity prompt behavior from one location, preventing any need
for duplicate code in your experience.

For more information regarding proximity prompts, see the
[Proximity Prompts](/docs/en-us/ui/proximity-prompts.md) guide.

## Code Samples

**Using a Proximity Prompt with a Seat**

In the example below, a user must interact with a chair to sit in it. Paste
this into a `Script` that is a child of a `ProximityPrompt`, which is itself a
sibling of a `Seat` object named _Seat_.

```lua
local proximityPrompt = script.Parent
local seat = proximityPrompt.Parent.Seat

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	if seat.Occupant then
		proximityPrompt.Enabled = false
	else
		proximityPrompt.Enabled = true
	end
end)

proximityPrompt.Triggered:Connect(function(player)
	seat:Sit(player.Character.Humanoid)
end)
```

**Generating a Custom Proximity Prompt**

The example below generates a custom `ProximityPrompt` UI similar to the
default style, which you may use as a starting point. It should be used in a
`LocalScript`.

```lua
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
while LocalPlayer == nil do
	Players.ChildAdded:wait()
	LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}

local KeyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}

local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

KeyCodeToTextMapping[Enum.KeyCode.PageUp] = "PgUp"
KeyCodeToTextMapping[Enum.KeyCode.PageDown] = "PgDn"
KeyCodeToTextMapping[Enum.KeyCode.Home] = "Home"
KeyCodeToTextMapping[Enum.KeyCode.End] = "End"
KeyCodeToTextMapping[Enum.KeyCode.Insert] = "Ins"
KeyCodeToTextMapping[Enum.KeyCode.Delete] = "Del"

local KeyCodeToFontSize = {
	[Enum.KeyCode.LeftControl] = 12,
	[Enum.KeyCode.RightControl] = 12,
	[Enum.KeyCode.LeftAlt] = 12,
	[Enum.KeyCode.RightAlt] = 12,
	[Enum.KeyCode.F10] = 12,
	[Enum.KeyCode.F11] = 12,
	[Enum.KeyCode.F12] = 12,
	[Enum.KeyCode.PageUp] = 8,
	[Enum.KeyCode.PageDown] = 8,
	[Enum.KeyCode.Home] = 8,
	[Enum.KeyCode.End] = 10,
	[Enum.KeyCode.Insert] = 10,
	[Enum.KeyCode.Delete] = 10,
}

-- Colors
local BackgroundColor = Color3.new(0.07, 0.07, 0.07)
local ContentColor = Color3.new(1, 1, 1)
local SecondaryContentColor = Color3.new(0.7, 0.7, 0.7)

-- TweenInfo presets
local tweenInfoQuick = TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local tweenInfoOutHalfSecond = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getScreenGui()
	local screenGui = PlayerGui:FindFirstChild("ProximityPrompts")
	if screenGui == nil then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ProximityPrompts"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui
		screenGui.IgnoreGuiInset = true
	end
	return screenGui
end

local progressGradientFuzz = 0.01
local function createProgressBarGradient(parent, leftSide, tweensForFadeOut, tweensForFadeIn)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.5, 1)
	frame.Position = UDim2.fromScale(leftSide and 0 or 0.5, 0)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.Visible = false
	frame.Parent = parent

	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(2, 1)
	image.Position = UDim2.fromScale(leftSide and 0 or -1, 0)
	image.Image = "rbxasset://textures/ui/Controls/RadialFill.png"
	image.Parent = frame

	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new {
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.5 + progressGradientFuzz, 1),
		NumberSequenceKeypoint.new(1, 1)
	}
	gradient.Rotation = leftSide and 180 or 0
	gradient.Parent = image

	table.insert(tweensForFadeOut, TweenService:Create(image, tweenInfoQuick, { ImageTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(image, tweenInfoQuick, { ImageTransparency = 0 }))

	return gradient, frame
end

local function createCircularProgressBar(tweensForFadeOut, tweensForFadeIn)
	local bar = Instance.new("Frame")
	bar.Name = "CircularProgressBar"
	bar.Size = UDim2.fromOffset(58, 58)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(0.5, 0.5)
	bar.BackgroundTransparency = 1

	local leftGradient, leftFrame = createProgressBarGradient(bar, true, tweensForFadeOut, tweensForFadeIn)
	local rightGradient, rightFrame = createProgressBarGradient(bar, false, tweensForFadeOut, tweensForFadeIn)

	local progress = Instance.new("NumberValue")
	progress.Name = "Progress"
	progress.Parent = bar
	progress.Changed:Connect(function(value)
		local angle = math.clamp(value * 360, 0, 360)
		leftFrame.Visible = progress.Value > 0.5
		leftGradient.Rotation = math.clamp(angle, 180, 360)
		rightFrame.Visible = progress.Value > progressGradientFuzz
		rightGradient.Rotation = math.clamp(angle, 0, 180)
	end)

	return bar
end

local function createPrompt(prompt, inputType, gui)
	local tweensForButtonHoldBegin = {}
	local tweensForButtonHoldEnd = {}
	local tweensForFadeOut = {}
	local tweensForFadeIn = {}
	local tweenInfoInFullDuration = TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	local promptUI = Instance.new("BillboardGui")
	promptUI.Name = "Prompt"
	promptUI.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.5, 1)
	frame.BackgroundTransparency = 1
	frame.BackgroundColor3 = BackgroundColor
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(0.5, 0)
	frame.Size = UDim2.fromScale(0, 1)
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.Parent = promptUI

	-- Add right padding
	local padding = Instance.new("UIPadding")
	padding.Parent = frame

	local roundedCorner = Instance.new("UICorner")
	roundedCorner.Parent = frame

	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.fromScale(1, 1)
	inputFrame.BackgroundTransparency = 1
	inputFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
	inputFrame.Parent = frame

	local resizeableInputFrame = Instance.new("Frame")
	resizeableInputFrame.Size = UDim2.fromScale(1, 1)
	resizeableInputFrame.Position = UDim2.fromScale(0.5, 0.5)
	resizeableInputFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	resizeableInputFrame.BackgroundTransparency = 1
	resizeableInputFrame.Parent = inputFrame

	local inputFrameScaler = Instance.new("UIScale")
	inputFrameScaler.Parent = resizeableInputFrame

	local inputFrameScaleFactor = inputType == Enum.ProximityPromptInputType.Touch and 1.6 or 1.33
	table.insert(tweensForButtonHoldBegin, TweenService:Create(inputFrameScaler, tweenInfoFast, { Scale = inputFrameScaleFactor }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(inputFrameScaler, tweenInfoFast, { Scale = 1 }))

	local actionText = Instance.new("TextLabel")
	actionText.Name = "ActionText"
	actionText.Font = Enum.Font.GothamMedium
	actionText.TextSize = 19
	actionText.BackgroundTransparency = 1
	actionText.TextTransparency = 1
	actionText.TextColor3 = ContentColor
	actionText.TextXAlignment = Enum.TextXAlignment.Left
	table.insert(tweensForButtonHoldBegin, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))
	table.insert(tweensForFadeOut, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(actionText, tweenInfoFast, { TextTransparency = 0 }))

	local objectText = Instance.new("TextLabel")
	objectText.Name = "ObjectText"
	objectText.Font = Enum.Font.GothamMedium
	objectText.TextSize = 14
	objectText.BackgroundTransparency = 1
	objectText.TextTransparency = 1
	objectText.TextColor3 = SecondaryContentColor
	objectText.TextXAlignment = Enum.TextXAlignment.Left

	-- Add list layout, as well a tween out to mimic old shrinking
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.Padding = UDim.new(-0.25, 0)
	listLayout.Parent = frame
	table.insert(tweensForButtonHoldBegin, TweenService:Create(listLayout, tweenInfoFast, { Padding = UDim.new(-0.25, 0) }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(listLayout, tweenInfoFast, { Padding = UDim.new(0, 0) }))
	table.insert(tweensForFadeOut, TweenService:Create(listLayout, tweenInfoFast, { Padding = UDim.new(-0.25, 0) }))
	table.insert(tweensForFadeIn, TweenService:Create(listLayout, tweenInfoFast, { Padding = UDim.new(0, 0) }))

	-- Add container for text labels
	local textFrame = Instance.new("Frame")
	textFrame.Name = "TextFrame"
	textFrame.Size = UDim2.fromScale(0, 1)
	textFrame.AutomaticSize = Enum.AutomaticSize.X
	textFrame.BackgroundTransparency = 1
	textFrame.Parent = frame

	-- ActionText and ObjectText automatic sizing, parent to textFrame
	actionText.Size = UDim2.fromScale(0, 1)
	actionText.AutomaticSize = Enum.AutomaticSize.X
	actionText.Parent = textFrame

	objectText.Size = UDim2.fromScale(0, 1)
	objectText.AutomaticSize = Enum.AutomaticSize.X
	objectText.Parent = textFrame

	table.insert(tweensForButtonHoldBegin, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))
	table.insert(tweensForFadeOut, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(objectText, tweenInfoFast, { TextTransparency = 0 }))

	table.insert(tweensForButtonHoldBegin, TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = 1 }))
	table.insert(tweensForButtonHoldEnd, TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = 0.2 }))
	table.insert(tweensForFadeOut, TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(frame, tweenInfoFast, { BackgroundTransparency = 0.2 }))

	local roundFrame = Instance.new("Frame")
	roundFrame.Name = "RoundFrame"
	roundFrame.Size = UDim2.fromOffset(48, 48)

	roundFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	roundFrame.Position = UDim2.fromScale(0.5, 0.5)
	roundFrame.BackgroundTransparency = 1
	roundFrame.Parent = resizeableInputFrame

	local roundedFrameCorner = Instance.new("UICorner")
	roundedFrameCorner.CornerRadius = UDim.new(0.5, 0)
	roundedFrameCorner.Parent = roundFrame

	table.insert(tweensForFadeOut, TweenService:Create(roundFrame, tweenInfoQuick, { BackgroundTransparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(roundFrame, tweenInfoQuick, { BackgroundTransparency = 0.5 }))

	if inputType == Enum.ProximityPromptInputType.Gamepad then

		local mappedIconImage = UserInputService:GetImageForKeyCode(prompt.GamepadKeyCode)

		if mappedIconImage then
			local icon = Instance.new("ImageLabel")
			icon.Name = "ButtonImage"
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Size = UDim2.fromOffset(24, 24)
			icon.Position = UDim2.fromScale(0.5, 0.5)
			icon.BackgroundTransparency = 1
			icon.ImageTransparency = 1
			icon.Image = mappedIconImage
			icon.Parent = resizeableInputFrame
			table.insert(tweensForFadeOut, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 1 }))
			table.insert(tweensForFadeIn, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 0 }))
		end
	elseif inputType == Enum.ProximityPromptInputType.Touch then
		local buttonImage = Instance.new("ImageLabel")
		buttonImage.Name = "ButtonImage"
		buttonImage.BackgroundTransparency = 1
		buttonImage.ImageTransparency = 1
		buttonImage.Size = UDim2.fromOffset(25, 31)
		buttonImage.AnchorPoint = Vector2.new(0.5, 0.5)
		buttonImage.Position = UDim2.fromScale(0.5, 0.5)
		buttonImage.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"
		buttonImage.Parent = resizeableInputFrame

		table.insert(tweensForFadeOut, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 0 }))
	else
		local buttonImage = Instance.new("ImageLabel")
		buttonImage.Name = "ButtonImage"
		buttonImage.BackgroundTransparency = 1
		buttonImage.ImageTransparency = 1
		buttonImage.Size = UDim2.fromOffset(28, 30)
		buttonImage.AnchorPoint = Vector2.new(0.5, 0.5)
		buttonImage.Position = UDim2.fromScale(0.5, 0.5)
		buttonImage.Image = "rbxasset://textures/ui/Controls/key_single.png"
		buttonImage.Parent = resizeableInputFrame
		table.insert(tweensForFadeOut, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 1 }))
		table.insert(tweensForFadeIn, TweenService:Create(buttonImage, tweenInfoQuick, { ImageTransparency = 0 }))

		local buttonTextString = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)

		local buttonTextImage = KeyboardButtonImage[prompt.KeyboardKeyCode]
		if buttonTextImage == nil then
			buttonTextImage = KeyboardButtonIconMapping[buttonTextString]
		end

		if buttonTextImage == nil then
			local keyCodeMappedText = KeyCodeToTextMapping[prompt.KeyboardKeyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end

		if buttonTextImage then
			local icon = Instance.new("ImageLabel")
			icon.Name = "ButtonImage"
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Size = UDim2.fromOffset(36, 36)
			icon.Position = UDim2.fromScale(0.5, 0.5)
			icon.BackgroundTransparency = 1
			icon.ImageTransparency = 1
			icon.Image = buttonTextImage
			icon.Parent = resizeableInputFrame
			table.insert(tweensForFadeOut, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 1 }))
			table.insert(tweensForFadeIn, TweenService:Create(icon, tweenInfoQuick, { ImageTransparency = 0 }))
		elseif buttonTextString ~= nil and buttonTextString ~= '' then
			local buttonText = Instance.new("TextLabel")
			buttonText.Name = "ButtonText"
			buttonText.AutoLocalize = false
			buttonText.Position = UDim2.fromOffset(0, -1)
			buttonText.Size = UDim2.fromScale(1, 1)
			buttonText.Font = Enum.Font.GothamMedium

			local buttonTextSize = KeyCodeToFontSize[prompt.KeyboardKeyCode]
			if buttonTextSize == nil then
				buttonTextSize = 14
			end
			buttonText.TextSize = buttonTextSize

			buttonText.BackgroundTransparency = 1
			buttonText.TextTransparency = 1
			buttonText.TextColor3 = ContentColor
			buttonText.TextXAlignment = Enum.TextXAlignment.Center
			buttonText.Text = buttonTextString
			buttonText.Parent = resizeableInputFrame
			table.insert(tweensForFadeOut, TweenService:Create(buttonText, tweenInfoQuick, { TextTransparency = 1 }))
			table.insert(tweensForFadeIn, TweenService:Create(buttonText, tweenInfoQuick, { TextTransparency = 0 }))
		else
			error("ProximityPrompt '" .. prompt.Name .. "' has an unsupported keycode for rendering UI: " .. tostring(prompt.KeyboardKeyCode))
		end
	end

	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then
		local button = Instance.new("TextButton")
		button.BackgroundTransparency = 1
		button.TextTransparency = 1
		button.Size = UDim2.fromScale(1, 1)
		button.Parent = promptUI
		button.Selectable = false

		local buttonDown = false

		button.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) and
				input.UserInputState ~= Enum.UserInputState.Change then
				prompt:InputHoldBegin()
				buttonDown = true
			end
		end)
		button.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				if buttonDown then
					buttonDown = false
					prompt:InputHoldEnd()
				end
			end
		end)

		promptUI.Active = true
	end

	if prompt.HoldDuration > 0 then
		local circleBar = createCircularProgressBar(tweensForFadeOut, tweensForFadeIn)
		circleBar.Parent = resizeableInputFrame
		table.insert(tweensForButtonHoldBegin, TweenService:Create(circleBar.Progress, tweenInfoInFullDuration, { Value = 1 }))
		table.insert(tweensForButtonHoldEnd, TweenService:Create(circleBar.Progress, tweenInfoOutHalfSecond, { Value = 0 }))
	end

	local holdBeganConnection
	local holdEndedConnection
	local triggeredConnection
	local triggerEndedConnection

	if prompt.HoldDuration > 0 then
		holdBeganConnection = prompt.PromptButtonHoldBegan:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldBegin) do
				tween:Play()
			end
		end)

		holdEndedConnection = prompt.PromptButtonHoldEnded:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldEnd) do
				tween:Play()
			end
		end)
	end

	triggeredConnection = prompt.Triggered:Connect(function()
		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end
	end)

	triggerEndedConnection = prompt.TriggerEnded:Connect(function()
		for _, tween in ipairs(tweensForFadeIn) do
			tween:Play()
		end
	end)

	local function updateUIFromPrompt()
		local promptHeight = 72
		local promptWidth = 72
		local textPaddingRight = 24

		local actionTextYOffset = 0
		if prompt.ObjectText ~= nil and prompt.ObjectText ~= '' then
			actionTextYOffset = 9
		end

		actionText.Text = prompt.ActionText
		objectText.Text = prompt.ObjectText
		actionText.AutoLocalize = prompt.AutoLocalize
		actionText.RootLocalizationTable = prompt.RootLocalizationTable
		objectText.AutoLocalize = prompt.AutoLocalize
		objectText.RootLocalizationTable = prompt.RootLocalizationTable

		textPaddingRight = textPaddingRight - actionTextYOffset

		if
			(prompt.ActionText ~= nil and prompt.ActionText ~= '')
			or (prompt.ObjectText ~= nil and prompt.ObjectText ~= '')
		then
			padding.PaddingRight = UDim.new(0, textPaddingRight)
		else
			padding.PaddingRight = UDim.new(0, 0)
		end

		actionText.Position = UDim2.new(0, 0, 0, actionTextYOffset)
		objectText.Position = UDim2.new(0, 0, 0, -10)

		promptUI.Size = UDim2.fromOffset(promptWidth, promptHeight)
		promptUI.SizeOffset = Vector2.new(prompt.UIOffset.X / promptUI.Size.Width.Offset, prompt.UIOffset.Y / promptUI.Size.Height.Offset)

		-- BillboardGuis can't be automatically sized, so we need to calculate
		-- the size based on the automatically sized prompt frame.
		task.defer(function ()
			-- Automatic sizing takes approximately 2 render cycles to be calculated
			RunService.RenderStepped:Wait()
			RunService.RenderStepped:Wait()

			promptWidth = frame.AbsoluteSize.X
			promptUI.Size = UDim2.fromOffset(promptWidth, promptHeight)
			promptUI.SizeOffset = Vector2.new(prompt.UIOffset.X / promptUI.Size.Width.Offset, prompt.UIOffset.Y / promptUI.Size.Height.Offset)
		end)
	end

	local changedConnection = prompt.Changed:Connect(updateUIFromPrompt)
	updateUIFromPrompt()

	promptUI.Adornee = prompt.Parent
	promptUI.Parent = gui

	local function updateUIAncestry()
		promptUI.Adornee = prompt.Parent
	end
	local ancestryConnection = prompt.AncestryChanged:Connect(updateUIAncestry)

	for _, tween in ipairs(tweensForFadeIn) do
		tween:Play()
	end

	local function cleanup()
		if holdBeganConnection then
			holdBeganConnection:Disconnect()
		end

		if holdEndedConnection then
			holdEndedConnection:Disconnect()
		end

		triggeredConnection:Disconnect()
		triggerEndedConnection:Disconnect()
		changedConnection:Disconnect()
		ancestryConnection:Disconnect()

		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end

		wait(0.2)

		promptUI.Parent = nil
	end

	return cleanup
end

local function createIndicator(prompt, gui)
	local tweensForFadeOut = {}
	local tweensForFadeIn = {}

	local indicatorUI = Instance.new("BillboardGui")
	indicatorUI.Name = "Indicator"
	indicatorUI.Size = UDim2.fromOffset(15, 15)
	indicatorUI.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BackgroundColor3 = BackgroundColor
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(0.5, 0)
	frame.Parent = indicatorUI

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

    local stroke = Instance.new("UIStroke")
	stroke.Color = ContentColor
	stroke.Thickness = 1.5
	stroke.Transparency = 1
	stroke.Parent = frame

	table.insert(tweensForFadeOut, TweenService:Create(frame, tweenInfoQuick, { BackgroundTransparency = 1 }))
	table.insert(tweensForFadeOut, TweenService:Create(stroke, tweenInfoQuick, { Transparency = 1 }))
	table.insert(tweensForFadeIn, TweenService:Create(frame, tweenInfoQuick, { BackgroundTransparency = 0.2 }))
	table.insert(tweensForFadeIn, TweenService:Create(stroke, tweenInfoQuick, { Transparency = 0.2 }))

	indicatorUI.Adornee = prompt.Parent
	indicatorUI.Parent = gui

	local function updateUIAncestry()
		indicatorUI.Adornee = prompt.Parent
	end
	local ancestryConnection = prompt.AncestryChanged:Connect(updateUIAncestry)

	for _, tween in ipairs(tweensForFadeIn) do
		tween:Play()
	end

	local function cleanup()
		ancestryConnection:Disconnect()

		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end

		wait(0.2)

		indicatorUI.Parent = nil
	end

	return cleanup
end

local function onLoad()
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return
		end

		local gui = getScreenGui()

		local cleanupFunction = createPrompt(prompt, inputType, gui)

		-- Wait for either the prompt being hidden or destroyed
		local yield = Instance.new("BindableEvent")
		local con = prompt.PromptHidden:Connect(function()
			yield:Fire()
		end)
		local con2 = prompt.Destroying:Connect(function()
			yield:Fire()
		end)
		yield.Event:Wait()
		con:Disconnect()
		con2:Disconnect()

		cleanupFunction()
    end)

	ProximityPromptService.IndicatorShown:Connect(function(prompt)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return
		end

		local gui = getScreenGui()

		local cleanupFunction = createIndicator(prompt, gui)

		-- Wait for either the indicator being hidden or the prompt is destroyed
		local yield = Instance.new("BindableEvent")
		local con = prompt.IndicatorHidden:Connect(function()
			yield:Fire()
		end)
		local con2 = prompt.Destroying:Connect(function()
			yield:Fire()
		end)
		yield.Event:Wait()
		con:Disconnect()
		con2:Disconnect()

		cleanupFunction()
	end)
end

onLoad()
```

**Healing Proximity Prompt**

The example below illustrates a prompt that requires the user to hold the
button down in order to heal their character. This should be used in a
`Script` that is a child of a `ProximityPrompt`.

```lua
local RunService = game:GetService("RunService")

local prompt = script.Parent

local playersHealing = {}

RunService.Stepped:Connect(function(_currentTime, deltaTime)
	for player, _value in pairs(playersHealing) do
		local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.Health + 30 * deltaTime
		end
	end
end)

prompt.Triggered:Connect(function(player)
	playersHealing[player] = true
end)

prompt.TriggerEnded:Connect(function(player)
	playersHealing[player] = nil
end)
```

## Properties

### Property: ProximityPrompt.ActionText

```json
{
  "type": "string",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property determines the action text shown to the user.

### Property: ProximityPrompt.AutoLocalize

```json
{
  "type": "boolean",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Localization",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property determines whether the prompt's
[ProximityPrompt.ActionText](/docs/reference/engine/classes/ProximityPrompt.md) and [ProximityPrompt.ObjectText](/docs/reference/engine/classes/ProximityPrompt.md)
will be localized according to the
[ProximityPrompt.RootLocalizationTable](/docs/reference/engine/classes/ProximityPrompt.md). When set to true,
localization will be applied.

### Property: ProximityPrompt.ClickablePrompt

```json
{
  "type": "boolean",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property determines whether the prompt can be activated by
clicking/tapping on the prompt's UI. When set to false, the prompt cannot
be activated by click/tap except on mobile.

### Property: ProximityPrompt.Enabled

```json
{
  "type": "boolean",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property indicates whether or this [ProximityPrompt](/docs/reference/engine/classes/ProximityPrompt.md) should be
shown.

### Property: ProximityPrompt.Exclusivity

```json
{
  "type": "ProximityPromptExclusivity",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property is used to customize which prompts can be shown at the same
time.

### Property: ProximityPrompt.GamepadKeyCode

```json
{
  "type": "KeyCode",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property determines the gamepad button the player should press to
trigger the [ProximityPrompt](/docs/reference/engine/classes/ProximityPrompt.md). Default is
**ButtonX**.

### Property: ProximityPrompt.HoldDuration

```json
{
  "type": "float",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property indicates the duration, in seconds, that the player must
hold the button/key down to trigger the prompt.

### Property: ProximityPrompt.KeyboardKeyCode

```json
{
  "type": "KeyCode",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property determines the key the player should press to trigger the
[ProximityPrompt](/docs/reference/engine/classes/ProximityPrompt.md). Default is <kbd>E</kbd>.

### Property: ProximityPrompt.MaxActivationDistance

```json
{
  "type": "float",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property determines the maximum distance a Player's
[character](/docs/reference/engine/classes/Player.md) can be from the [ProximityPrompt](/docs/reference/engine/classes/ProximityPrompt.md)
for the prompt to appear.

### Property: ProximityPrompt.MaxIndicatorDistance

```json
{
  "type": "float",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

### Property: ProximityPrompt.ObjectText

```json
{
  "type": "string",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This optional property determines the optional object name text shown to
the user.

### Property: ProximityPrompt.RequiresLineOfSight

```json
{
  "type": "boolean",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property indicates whether the prompt is hidden if the path between
the player's [Camera](/docs/reference/engine/classes/Camera.md) and object parented to the
[ProximityPrompt](/docs/reference/engine/classes/ProximityPrompt.md) is obstructed. If true, this prompt will only be
shown if there is a clear path from the camera to the object.

The parent [Part](/docs/reference/engine/classes/Part.md) or [Model](/docs/reference/engine/classes/Model.md) of the prompt will be excluded
from this check.

### Property: ProximityPrompt.RootLocalizationTable

```json
{
  "type": "LocalizationTable",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Localization",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property serves as a reference to the [LocalizationTable](/docs/reference/engine/classes/LocalizationTable.md) used
to apply automated localization to the prompt's
[ProximityPrompt.ActionText](/docs/reference/engine/classes/ProximityPrompt.md) and [ProximityPrompt.ObjectText](/docs/reference/engine/classes/ProximityPrompt.md).
In order for this to apply, [ProximityPrompt.AutoLocalize](/docs/reference/engine/classes/ProximityPrompt.md) must be
set.

Developers can set this to reference a LocalizationTable anywhere in the
[DataModel](/docs/reference/engine/classes/DataModel.md). It is not required to be a child of
[LocalizationService](/docs/reference/engine/classes/LocalizationService.md). If there is no translation available in the
referenced table it will look for a translation in the parent of that
table, if it is also a LocalizationTable, and so on.

### Property: ProximityPrompt.Style

```json
{
  "type": "ProximityPromptStyle",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property indicates the prompt's style. When set to Custom, no default
UI will be provided.

The provided UI can be swapped out for a custom UI. In order to do this,
set Style to Custom. Then, listen to the
[ProximityPrompt.PromptShown](/docs/reference/engine/classes/ProximityPrompt.md) and
[ProximityPrompt.PromptHidden](/docs/reference/engine/classes/ProximityPrompt.md) events in a [LocalScript](/docs/reference/engine/classes/LocalScript.md),
where developers should create and tear down the UI.

Developers may also use [ProximityPrompt.PromptButtonHoldBegan](/docs/reference/engine/classes/ProximityPrompt.md) and
[ProximityPrompt.PromptButtonHoldEnded](/docs/reference/engine/classes/ProximityPrompt.md) in order to utilize the
[ProximityPrompt.HoldDuration](/docs/reference/engine/classes/ProximityPrompt.md) progress animation feature.

### Property: ProximityPrompt.UIOffset

```json
{
  "type": "Vector2",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "UI",
    "Input"
  ]
}
```

This property indicates the pixel offset applied to the prompt's UI.

## Methods

### Method: ProximityPrompt:InputHoldBegin

**Signature:** `ProximityPrompt:InputHoldBegin(): ()`

This function triggers a signal indicating that the user began pressing
the [ProximityPrompt](/docs/reference/engine/classes/ProximityPrompt.md) prompt button. It should be used by developers
who wish to customize the prompt and trigger it from a prompt GUI button
press.

*Security: None · Thread Safety: Unsafe · Capabilities: UI, Input*

**Returns:** `()`

### Method: ProximityPrompt:InputHoldEnd

**Signature:** `ProximityPrompt:InputHoldEnd(): ()`

A counterpoint to [ProximityPrompt:InputHoldBegin()](/docs/reference/engine/classes/ProximityPrompt.md), this signals
that the user ended pressing the prompt GUI button.

*Security: None · Thread Safety: Unsafe · Capabilities: UI, Input*

**Returns:** `()`

## Events

### Event: ProximityPrompt.IndicatorHidden

**Signature:** `ProximityPrompt.IndicatorHidden()`

*Security: None · Capabilities: UI, Input*

### Event: ProximityPrompt.IndicatorShown

**Signature:** `ProximityPrompt.IndicatorShown()`

*Security: None · Capabilities: UI, Input*

### Event: ProximityPrompt.PromptButtonHoldBegan

**Signature:** `ProximityPrompt.PromptButtonHoldBegan(playerWhoTriggered: Player)`

This event triggers when a player begins holding down the
[key](/docs/reference/engine/classes/ProximityPrompt.md)/button on a prompt with a
non-zero [ProximityPrompt.HoldDuration](/docs/reference/engine/classes/ProximityPrompt.md). One possible usage includes
to animate a hold progress bar.

*Security: None · Capabilities: UI, Input*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `playerWhoTriggered` | `Player` | The [Player](/docs/reference/engine/classes/Player.md) who begins holding down the prompt button. |

### Event: ProximityPrompt.PromptButtonHoldEnded

**Signature:** `ProximityPrompt.PromptButtonHoldEnded(playerWhoTriggered: Player)`

This event triggers when the player ends holding down the button on a
prompt with a non-zero [ProximityPrompt.HoldDuration](/docs/reference/engine/classes/ProximityPrompt.md). One possible
usage includes to animate a hold progress bar.

*Security: None · Capabilities: UI, Input*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `playerWhoTriggered` | `Player` | The player who ended the input hold. |

### Event: ProximityPrompt.PromptHidden

**Signature:** `ProximityPrompt.PromptHidden()`

This event triggers when the [prompt](/docs/reference/engine/classes/ProximityPrompt.md) becomes
hidden. This event is triggered client-side for `LocalScripts`.

*Security: None · Capabilities: UI, Input*

### Event: ProximityPrompt.PromptShown

**Signature:** `ProximityPrompt.PromptShown(inputType: ProximityPromptInputType)`

This event triggers when the [prompt](/docs/reference/engine/classes/ProximityPrompt.md) becomes
visible. This event is triggered client-side for `LocalScripts`.

*Security: None · Capabilities: UI, Input*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `inputType` | `ProximityPromptInputType` | The input that triggers the prompt. |

### Event: ProximityPrompt.Triggered

**Signature:** `ProximityPrompt.Triggered(playerWhoTriggered: Player)`

This event is triggered when the prompt
[key](/docs/reference/engine/classes/ProximityPrompt.md)/button is pressed, or after a
specified amount of time holding the button, if
[ProximityPrompt.HoldDuration](/docs/reference/engine/classes/ProximityPrompt.md) is used.

*Security: None · Capabilities: UI, Input*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `playerWhoTriggered` | `Player` | The [Player](/docs/reference/engine/classes/Player.md) who triggered the prompt. |

### Event: ProximityPrompt.TriggerEnded

**Signature:** `ProximityPrompt.TriggerEnded(playerWhoTriggered: Player)`

This event is triggered when the
[key](/docs/reference/engine/classes/ProximityPrompt.md)/button is released, for longer
events where the user is required to hold down the button (e.g. heal
another player over time.)

*Security: None · Capabilities: UI, Input*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `playerWhoTriggered` | `Player` | The [Player](/docs/reference/engine/classes/Player.md) who released the key/button, ending the trigger event. |

## Inherited Members

### From [Instance](/docs/reference/engine/classes/Instance.md)

- **Property `Archivable`** (`boolean`): Determines if an Instance and its descendants can be cloned using
- **Property `archivable`** (`boolean`):  *(deprecated, hidden)*
- **Property `Capabilities`** (`SecurityCapabilities`): The set of capabilities allowed to be used for scripts inside this
- **Property `Name`** (`string`): A non-unique identifier of the Instance.
- **Property `Parent`** (`Instance`): Determines the hierarchical parent of the Instance.
- **Property `PredictionMode`** (`PredictionMode`): 
- **Property `RobloxLocked`** (`boolean`): A deprecated property that used to protect CoreGui objects. *(hidden)*
- **Property `Sandboxed`** (`boolean`): When enabled, the instance can only access abilities in its `Capabilities`
- **Property `UniqueId`** (`UniqueId`): A unique identifier for the instance.
- **Method `AddTag(tag: string): ()`**: Applies a tag to the instance.
- **Method `children(): Instances`**: Returns an array of the object's children. *(deprecated)*
- **Method `ClearAllChildren(): ()`**: This method destroys all of an instance's children.
- **Method `Clone(): Instance`**: Create a copy of an instance and all its descendants, ignoring instances
- **Method `clone(): Instance`**:  *(deprecated)*
- **Method `Destroy(): ()`**: Sets the Instance.Parent property to `nil`, locks the
- **Method `destroy(): ()`**:  *(deprecated)*
- **Method `FindFirstAncestor(name: string): Instance?`**: Returns the first ancestor of the Instance whose
- **Method `FindFirstAncestorOfClass(className: string): Instance?`**: Returns the first ancestor of the Instance whose
- **Method `FindFirstAncestorWhichIsA(className: string): Instance?`**: Returns the first ancestor of the Instance for whom
- **Method `FindFirstChild(name: string, recursive?: boolean): Instance?`**: Returns the first child of the Instance found with the given name.
- **Method `findFirstChild(name: string, recursive?: boolean): Instance`**:  *(deprecated)*
- **Method `FindFirstChildOfClass(className: string): Instance?`**: Returns the first child of the Instance whose
- **Method `FindFirstChildWhichIsA(className: string, recursive?: boolean): Instance?`**: Returns the first child of the Instance for whom
- **Method `FindFirstDescendant(name: string): Instance?`**: Returns the first descendant found with the given Instance.Name.
- **Method `GetActor(): Actor?`**: Returns the Actor associated with the Instance, if any.
- **Method `GetAttribute(attribute: string): Variant`**: Returns the value which has been assigned to the given attribute name.
- **Method `GetAttributeChangedSignal(attribute: string): RBXScriptSignal`**: Returns an event that fires when the given attribute changes.
- **Method `GetAttributes(): Dictionary`**: Returns a dictionary of the instance's attributes.
- **Method `GetChildren(): Instances`**: Returns an array containing all of the instance's children.
- **Method `getChildren(): Instances`**:  *(deprecated)*
- **Method `GetDebugId(scopeLength?: int): string`**: Returns a coded string of the debug ID used internally by Roblox.
- **Method `GetDescendants(): Instances`**: Returns an array containing all of the descendants of the instance.
- **Method `GetFullName(): string`**: Returns a string describing the instance's ancestry.
- **Method `GetStyled(name: string, selector: string?): Variant`**: Returns the styled or explicitly modified value of the specified property,
- **Method `GetStyledPropertyChangedSignal(property: string): RBXScriptSignal`**: 
- **Method `GetTags(): Array`**: Gets an array of all tags applied to the instance.
- **Method `HasTag(tag: string): boolean`**: Check whether the instance has a given tag.
- **Method `IsAncestorOf(descendant: Instance): boolean`**: Returns true if an Instance is an ancestor of the given
- **Method `IsDescendantOf(ancestor: Instance): boolean`**: Returns `true` if an Instance is a descendant of the given
- **Method `isDescendantOf(ancestor: Instance): boolean`**:  *(deprecated)*
- **Method `IsPropertyModified(property: string): boolean`**: Returns `true` if the value stored in the specified property is not equal
- **Method `QueryDescendants(selector: string): Instances`**: Returns an array containing all descendants of the instance that match the
- **Method `Remove(): ()`**: Sets the object's `Parent` to `nil`, and does the same for all its *(deprecated)*
- **Method `remove(): ()`**:  *(deprecated)*
- **Method `RemoveTag(tag: string): ()`**: Removes a tag from the instance.
- **Method `ResetPropertyToDefault(property: string): ()`**: Resets a property to its default value.
- **Method `SetAttribute(attribute: string, value: Variant): ()`**: Sets the attribute with the given name to the given value.
- **Method `WaitForChild(childName: string, timeOut: double): Instance`**: Returns the child of the Instance with the given name. If the
- **Event `AncestryChanged`**: Fires when the Instance.Parent property of this object or one of
- **Event `AttributeChanged`**: Fires whenever an attribute is changed on the Instance.
- **Event `ChildAdded`**: Fires after an object is parented to this Instance.
- **Event `childAdded`**:  *(deprecated)*
- **Event `ChildRemoved`**: Fires after a child is removed from this Instance.
- **Event `DescendantAdded`**: Fires after a descendant is added to the Instance.
- **Event `DescendantRemoving`**: Fires immediately before a descendant of the Instance is removed.
- **Event `Destroying`**: Fires immediately before (or is deferred until after) the instance is
- **Event `StyledPropertiesChanged`**: Fires whenever any style property is changed on the instance, including

### From [Object](/docs/reference/engine/classes/Object.md)

- **Property `ClassName`** (`string`): A read-only string representing the class this Object belongs to.
- **Property `className`** (`string`):  *(deprecated)*
- **Method `GetPropertyChangedSignal(property: string): RBXScriptSignal`**: Get an event that fires when a given property of the object changes.
- **Method `IsA(className: string): boolean`**: Returns true if an object's class matches or inherits from a given class.
- **Method `isA(className: string): boolean`**:  *(deprecated)*
- **Event `Changed`**: Fires immediately after a property of the object changes, with some