---
title: "Create interactive UI"
url: /docs/en-us/tutorials/use-case-tutorials/ui/interactive-ui
last_updated: 2026-07-02T02:14:45Z
description: "Learn how to build interactive UI and connect stateful scripts to power it."
---

# Create interactive UI

A **HUD** (**Heads-Up Display**) in your experience commonly displays non‑interactive UI elements such as the health meter demonstrated in [Create HUD meters](/docs/en-us/tutorials/use-case-tutorials/ui/create-hud-meters.md). Atop this, almost every experience requires **interactive** UI such as buttons that respond to player activation, animate when activated, tween in/out menus with other interactive controls, etc.

![In-game view showing a settings button and settings menu with volume sliders.](../../../assets/tutorials/interactive-ui/Intro.png)

Using [UI Fundamentals - HUD Meter](https://www.roblox.com/games/104506915856758/UI-Fundamentals-HUD-Meter) as a starting place and [UI Fundamentals - Interactivity](https://www.roblox.com/games/138499606610292/UI-Fundamentals-Interactivity) as a finished reference place, this tutorial demonstrates:

- How to position a settings button along the top screen edge.
- Design of a settings menu containing interactive draggable sliders.
- Usage of a `Class.ModuleScript|ModuleScripts` to form "controller" modules for extensible control of UI objects with stateful declarations.
- How to connect buttons to player activation to toggle in/out the settings menu.
- How to connect draggable UI sliders to adjust the volume of sound effects and background ambience separately.

## Enable the Device Emulator

As noted in [Create HUD meters](/docs/en-us/tutorials/use-case-tutorials/ui/create-hud-meters.md), phones and tablets have the least amount of screen space, so it's important that your UI elements fit on smaller screens and that they're clearly visible to players. If you haven't done so already, enable the [Device Emulator](/docs/en-us/studio/testing-modes.md#device-emulation) in Studio:

1. Open the [UI Fundamentals - HUD Meter](https://www.roblox.com/games/104506915856758/UI-Fundamentals-HUD-Meter) template in Studio.
2. From Studio's **Test** menu, toggle on **Device Emulator**.
3. From the bar directly above the main viewport, select a phone emulation such as **iPhone X** or **Samsung Galaxy A51**. Then, set the view size to **Fit to Window** to utilize the maximum space in Studio.![Device Emulator settings options indicated at top of viewport window.](../../../assets/studio/general/Device-Emulator-Phone.png)

## Create the settings button

`Class.GuiButton|GuiButtons` are interactive user interface elements with built‑in functionality such as the multi‑platform `Class.GuiButton.Activated|Activated` event which fires when the button is clicked or tapped. The `Class.GuiButton` class extends to two variations, `Class.TextButton` and `Class.ImageButton`, and this tutorial uses a "gear" shaped `Class.ImageButton` to toggle the settings menu open or closed.

![Roblox component used for the settings button.](../../../assets/tutorials/interactive-ui/Settings-Button-Design-Components.png)

To construct the settings button:

1. In the **Explorer** window, locate **HUDContainer** inside `Class.StarterGui`.![Explorer window showing the HUDContainer selected.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer.png)
2. Insert an `Class.ImageButton` into **HUDContainer** and rename it to **SettingsButton**.![Explorer window showing new ImageButton inserted and renamed to SettingsButton.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsButton.png)![New ImageButton in viewport.](../../../assets/tutorials/interactive-ui/Settings-Button-Design-Initial.png)
3. With the new button selected, set the following in the **Properties** window:
  - `Class.ImageButton.AnchorPoint|AnchorPoint` = `0.5, 0.25` (horizontal center and vertical upper quarter)
  - `Class.ImageButton.BackgroundTransparency|BackgroundTransparency` = `1` (fully transparent)
  - `Class.ImageButton.Position|Position` = `0.5, 0, 0, 0` (top-center positioning)
  - `Class.ImageButton.Size|Size` = `0.1, 0, 0.1, 0` (10% of screen height once aspect ratio is constrained)
  - `Class.ImageButton.Image|Image` = `rbxassetid://104919049969988` (asset ID of "gear" symbol)
4. Insert a `Class.UIAspectRatioConstraint` into the button with default properties (1:1 width to height).![Explorer window showing a new UIAspectRatioConstraint inserted into the SettingsButton button.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsButton-UIAspectRatioConstraint.png)
5. To limit the button's maximum pixel height, insert a `Class.UISizeConstraint` and set its `Class.UISizeConstraint.MaxSize|MaxSize` to`inf, 44`.![Explorer window showing a new UISizeConstraint inserted into the SettingsButton button.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsButton-UISizeConstraint.png)![Properties window showing expected values for the new UISizeConstraint.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsButton-UISizeConstraint-Values.png)![Final settings button in top-center of the screen.](../../../assets/tutorials/interactive-ui/Settings-Button-Design-Finalized.png)

## Create the settings menu

The new [settings button](#create-the-settings-button) will be scripted to toggle a settings menu open and closed, giving players on‑demand access to settings or other information. In this tutorial, the menu will contain interactive sliders to adjust the volume levels of background audio and sound effects independently.

![Basic components used for the settings menu.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Components.png) ### Create the parent frame

As noted in [Create HUD meters](/docs/en-us/tutorials/use-case-tutorials/ui/create-hud-meters.md), a `Class.Frame` serves as a container for other UI objects. The entire settings menu will be constructed with a single parent frame, making it simple to manage as a stateful object that reacts to input differently depending on the current state.

1. Insert a `Class.Frame` into **HUDContainer** and rename it **SettingsMenu**.![Explorer window showing new frame inserted and renamed to SettingsMenu.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu.png)
2. With **SettingsMenu** selected, set the following properties:
  - `Class.Frame.AnchorPoint|AnchorPoint` = `0.5` (center anchor)
  - `Class.Frame.BackgroundColor3|BackgroundColor3` = `30, 30, 60` (navy blue)
  - `Class.Frame.BackgroundTransparency|BackgroundTransparency` = `0.25` (75% opaque)
  - `Class.Frame.Position|Position` = `0.5, 0, 0.5, 0` (center of screen)
  - `Class.Frame.Size|Size` = `0.75, 0, 0.75, 0` (75% width/height of the inset screen area)![Frame repositioned, resized, and styled with transparent navy blue background.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Parent-Frame.png)
3. Insert a `Class.UIAspectRatioConstraint` into **SettingsMenu** and set its `Class.UIAspectRatioConstraint.AspectRatio|AspectRatio` property to `2.5`. (2.5:1 width to height).![Explorer window showing a new UISizeConstraint inserted into the SettingsMenu frame.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-UIAspectRatioConstraint.png)![Properties window showing expected values for the new UISizeConstraint.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-UIAspectRatioConstraint-Values.png)
4. Insert a `Class.UICorner` modifier into **SettingsMenu** and set its `Class.UICorner.CornerRadius|CornerRadius` to`0.1, 0`.![Explorer window showing a new UICorner inserted into the SettingsMenu frame.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-UICorner.png)![Properties window showing expected values for the new UICorner modifier.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-UICorner-Values.png)
5. To constrain the pixel width and height of **SettingsMenu**, insert a `Class.UISizeConstraint`. Set its `Class.UISizeConstraint.MaxSize|MaxSize` to`800, inf` and its `Class.UISizeConstraint.MinSize|MinSize` to`350, 0`.![Explorer window showing a new UISizeConstraint inserted into the SettingsMenu frame.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-UISizeConstraint.png)![Properties window showing expected values for the new UISizeConstraint.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-UISizeConstraint-Values.png)![Frame styled with rounded corners.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Parent-Frame-Finalized.png)

### Construct a slider

To allow players to adjust volume levels, the settings menu will contain two draggable **slider widgets** powered by `Class.UIDragDetector`, a convenient object that facilitates interaction with 2D user interface elements.

To create a parent container for the first slider:

1. Insert a new `Class.Frame` into the **SettingsMenu** container and rename it **EffectsVolumeSlider**.![Explorer window showing a new frame inserted into the SettingsMenu frame, renamed to EffectsVolumeSlider.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider.png)
2. With the **EffectsVolumeSlider** frame selected, set the following properties:
  - `Class.Frame.AnchorPoint|AnchorPoint` = `0.5` (center anchor)
  - `Class.Frame.BackgroundTransparency|BackgroundTransparency` = `1` (fully transparent)
  - `Class.Frame.Position|Position` = `0.5, 0, 0.35, 0` (horizontal center and 35% from container's top)
  - `Class.Frame.Size|Size` = `0.8, 0, 0.1, 0` (80% of container's width and 10% of its height)![Empty frame inserted to contain slider elements.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Slider-Frame-Measurements.png)
3. Insert a new `Class.UIListLayout` into **EffectsVolumeSlider**. This layout modifier is a powerful way to auto‑arrange sibling `Class.GuiObject|GuiObjects` into horizontal rows or vertical columns within their parent container, including the ability to apply [flex](/docs/en-us/ui/list-flex-layouts.md) concepts.![Explorer window showing a new UIListLayout inserted into the EffectsVolumeSlider frame.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-UIListLayout.png)
4. Set the following properties for the new `Class.UIListLayout`:
  - `Class.UIListLayout.Padding|Padding` = `0.06, 0` (6% padding between list elements)
  - `Class.UIListLayout.FillDirection|FillDirection` = `Enum.FillDirection.Horizontal|Horizontal` (left-to-right arrangement of elements)
  - `Class.UIListLayout.HorizontalFlex|HorizontalFlex` = `Enum.UIFlexAlignment.Fill|Fill` (resize elements horizontally to fill the entire parent container, overriding their defined width)
  - `Class.UIListLayout.VerticalAlignment|VerticalAlignment` = `Enum.VerticalAlignment.Center|Center` (align elements along their vertical center)

#### Slider icon

A simple icon including an audio note and "burst" symbol helps players identify the slider's purpose when they open the settings menu.

![Icon indicating purpose of slider in settings menu.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Slider-Icon.png)

1. Insert an `Class.ImageLabel` into the **EffectsVolumeSlider** frame and rename it to **Icon**. This icon will help players understand what in‑experience aspect the slider controls.![Explorer window showing an ImageLabel inserted into the EffectsVolumeSlider frame.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-Icon.png)
  > **Warning:** Importantly, note that the label must be a **sibling** of the `Class.UIListLayout`, not a child of it.
2. With **Icon** selected, set the following properties:
  - `Class.ImageLabel.BackgroundTransparency|BackgroundTransparency` = `1` (fully transparent)
  - `Class.ImageLabel.Size|Size` = `2.5, 0, 2.5, 0` (250% height of parent frame once aspect ratio is constrained)
  - `Class.ImageLabel.Image|Image` = `rbxassetid://90019827067389` (asset ID of audio note and "burst" symbol)
3. Insert a `Class.UIAspectRatioConstraint` into **Icon** and leave its properties as the defaults (1:1 width to height).![Explorer window showing a UIAspectRatioConstraint inserted into the ImageLabel.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-Icon-UIAspectRatioConstraint.png)![Finalized icon in the settings menu.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Slider-Icon-Finalized.png)

#### Range frame

Directly to the right of the [icon](#slider-icon), the interactive portion of the slider should be contained within another `Class.Frame`.

![Target size and position of the interactive portion of the slider.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Range-Frame-Measurements.png)

1. Insert a new `Class.Frame` into the **EffectsVolumeSlider** frame and rename it **SliderFrame**. Note that it must be a direct **sibling** of the `Class.UIListLayout` layout modifier.![Explorer window showing a child Frame inserted into the EffectsVolumeSlider frame.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-SliderFrame.png)
2. With **SliderFrame** selected, set the following properties:
  - `Class.Frame.BackgroundColor3|BackgroundColor3` = `0` (black)
  - `Class.Frame.BackgroundTransparency|BackgroundTransparency` = `0.75` (25% opaque)
  - `Class.Frame.LayoutOrder|LayoutOrder` = `1`
  - `Class.Frame.Size|Size` = `1, 0, 1, 0` (100% width/height of parent frame)
  > **Info:** Note that it's not necessary to assign **positional** changes such as `Class.Frame.AnchorPoint|AnchorPoint` or `Class.Frame.Position|Position`, as the `Class.UIListLayout` controls the positioning of its siblings, in this case ordering them horizontally from left to right and keeping them vertically centered with each other.
  > **Warning:** The `Class.Frame.LayoutOrder|LayoutOrder` property is important when working with layout modifiers such as `Class.UIListLayout`, as it determines the sequence in which siblings are placed respective to each other. Changing it to `1` for **SliderFrame** ensures it's placed to the right of **Icon** which has a default `Class.Frame.LayoutOrder|LayoutOrder` of `0`.
3. Insert the following modifiers into **SliderFrame**:
  - `Class.UICorner` with its `Class.UICorner.CornerRadius|CornerRadius` property set to`0.5, 0` ("pill" shape)
  - `Class.UISizeConstraint` with its `Class.UISizeConstraint.MaxSize|MaxSize` property set to`inf, 30` (maximum 30 pixels in height)
  - `Class.UIStroke` with its `Class.UIStroke.Color|Color` set to `0`, `Class.UIStroke.Thickness|Thickness` to `3`, and `Class.UIStroke.Transparency|Transparency` to `0.25` (75% opaque black outline)![Slider frame positioned to the right of the icon.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Range-Frame-Outline.png)

#### Interactive handle

With the [slider container](#range-frame) constructed, you can now create a **draggable handle** for players to interact with during gameplay.

![Interactive slider handle positioned within range frame.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Slider-Handle.png)

1. Insert a new `Class.Frame` into the **SliderFrame** container and rename it to **Handle**.![Explorer window showing a child Frame inserted into the SliderFrame frame and renamed to Handle.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-SliderFrame-Handle.png)
2. With **Handle** selected, set the following properties:
  - `Class.Frame.AnchorPoint|AnchorPoint` = `0.5` (center anchor)
  - `Class.Frame.Position|Position` = `0.5, 0, 0.5, 0` (horizontal and vertical center of parent frame)
  - `Class.Frame.Size|Size` = `1.2, 0, 1.2, 0` (120% height of parent frame once aspect ratio is constrained)
  - `Class.Frame.ZIndex|ZIndex` = `3` (layer handle visually in front of other slider elements)
3. Insert the following modifiers into **Handle**:
  - `Class.UIAspectRatioConstraint` with its default properties (1:1 width to height)
  - `Class.UICorner` with its `Class.UICorner.CornerRadius|CornerRadius` property set to`0.5, 0` (circular shape)
  - `Class.UIStroke` with its `Class.UIStroke.Color|Color` set to`[0, 150, 255]` and `Class.UIStroke.Thickness|Thickness` to `8` (thick blue outline)
4. Insert a `Class.UIDragDetector` object into **Handle**. This convenient object facilitates and encourages interaction with 2D user interface elements.![Explorer window showing a UIDragDetector inserted into the Handle frame.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-SliderFrame-Handle-UIDragDetector.png)
5. Set the following properties for the new `Class.UIDragDetector`:
  - `Class.UIDragDetector.DragStyle|DragStyle` = `Enum.UIDragDetectorDragStyle.TranslateLine|TranslateLine` (1D motion along the detector's `Class.UIDragDetector.DragAxis|DragAxis`.)
  - `Class.UIDragDetector.ResponseStyle|ResponseStyle` = `Enum.UIDragDetectorResponseStyle.Scale|Scale` (move by scale values of the detector's parent's position)
6. To ensure the handle's linear drag range is limited to its container, link its `Class.UIDragDetector.BoundingUI|BoundingUI` property to the **SliderFrame** container:
  1. Select the `Class.UIDragDetector`.
  2. Click its `Class.UIDragDetector.BoundingUI|BoundingUI` property in the **Properties** window.
  3. Back in the **Explorer** window, click the handle's parent **SliderFrame**.![Diagram showing process of linking the detector's BoundingUI property to the SliderFrame container.](../../../assets/tutorials/interactive-ui/Link-UIDragDetector-BoundingUI.png) The `Class.UIDragDetector.BoundingUI|BoundingUI` property link now reflects the **SliderFrame** container:![Properties window showing the detector's BoundingUI property linked to the SliderFrame container.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-SliderFrame-Handle-UIDragDetector-Values.png)

If you playtest the experience now, you'll be able to drag the handle left and right within its parent container:

#### Inner fill

To more clearly indicate that the slider controls a 0% to 100% range, you can add an **inner fill** to the left side of the container which will sync with the handle's variable position.

![Inner fill portion of slider inserted into SliderFrame.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Slider-Inner-Fill.png)

1. Insert a new `Class.Frame` into the **SliderFrame** container and rename it to **InnerFill**.![Explorer window showing a child Frame inserted into the SliderFrame frame and renamed to InnerFill.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-SliderFrame-InnerFill.png)
2. Set the following properties for the **InnerFill** frame:
  - `Class.Frame.AnchorPoint|AnchorPoint` = `0, 0.5` (left edge and vertical center)
  - `Class.Frame.BackgroundColor3|BackgroundColor3` = `[0, 150, 255]` (blue matching the slider's handle)
  - `Class.Frame.BackgroundTransparency|BackgroundTransparency` = `0.35` (65% opaque)
  - `Class.Frame.Position|Position` = `0, 0, 0.5, 0`
  - `Class.Frame.Size|Size` = `0.5, 0, 1, 0` (50% width and 100% height of parent frame)
  - `Class.Frame.ZIndex|ZIndex` = `2` (layer visually in front of parent frame's fill/outline)
3. To match the "pill" shape of the parent **SliderFrame** container, insert a `Class.UICorner` modifier and set its `Class.UICorner.CornerRadius|CornerRadius` property to`0.5, 0`.![Explorer window showing a UICorner modifier inserted into the InnerFill frame.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-SliderFrame-InnerFill-UICorner.png)![Properties window showing expected values for the new UICorner.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-SliderFrame-InnerFill-UICorner-Values.png)![InnerFill frame styled with blue background and rounded corners.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Slider-Inner-Fill-Finalized.png)

### Duplicate the slider

With the [first slider](#construct-a-slider) constructed, you can easily duplicate it and modify some visual aspects to indicate another purpose, in this case the volume level of background audio symbolized by an icon of musical notes.

![Target position of the background audio slider.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-BackgroundVolumeSlider-Measurements.png)

1. Select the completed **EffectsVolumeSlider** object.![Explorer window showing the completed EffectsVolumeSlider selected.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-EffectsVolumeSlider-Full.png)
2. Duplicate it (`Ctrl``D` or `⌘``D`) and then rename the duplicate to **BackgroundVolumeSlider**.![Explorer window showing the duplicated slider renamed to BackgroundVolumeSlider.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-BackgroundVolumeSlider.png)
3. Change the duplicate's `Class.Frame.Position|Position` to`0.5, 0, 0.7, 0` to move it below the first slider.![BackgroundVolumeSlider positioned below EffectsVolumeSlider.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-BackgroundVolumeSlider-Initial.png)
4. Expand the top-level branch of **BackgroundVolumeSlider**, select the **Icon** image label, and change its `Class.ImageLabel.Image|Image` property to `rbxassetid://101125859760167` (asset ID of symbol with musical notes).![Explorer window showing the Icon label within BackgroundVolumeSlider.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-BackgroundVolumeSlider-Icon.png)![Properties window showing expected values for the Icon label.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-BackgroundVolumeSlider-Icon-Values.png)![BackgroundVolumeSlider with modified icon image.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-BackgroundVolumeSlider-Icon.png)
5. Expand the **SliderFrame** ⟩ **Handle** branch, select the `Class.UIStroke` modifier within, and set its `Class.UIStroke.Color|Color` property to`[255, 0, 125]` (magenta).![Explorer window showing the UIStroke modifier within the handle of BackgroundVolumeSlider.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-BackgroundVolumeSlider-SliderFrame-Handle-UIStroke.png)![Properties window showing expected values for the UIStroke modifier.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-BackgroundVolumeSlider-SliderFrame-Handle-UIStroke-Values.png)![BackgroundVolumeSlider with modified icon image.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-BackgroundVolumeSlider-Handle.png)
6. Select the **InnerFill** frame within **SliderFrame** and change its `Class.Frame.BackgroundColor3|BackgroundColor3` property to the same magenta color (`[255, 0, 125]`).![Explorer window showing the InnerFill frame within the SliderFrame container of BackgroundVolumeSlider.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-BackgroundVolumeSlider-SliderFrame-InnerFill.png)![Properties window showing expected values for the InnerFill frame.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-BackgroundVolumeSlider-SliderFrame-InnerFill-Values.png)![BackgroundVolumeSlider with modified InnerFill color.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-BackgroundVolumeSlider-Inner-Fill.png)

### Create the close button

The final element of the settings menu is a **close button** which provides players an additional input to close the menu (the **SettingsButton** in the top‑center will serve the same purpose).

![Settings menu with close button indicated in upper-right corner.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Close-Button.png)

1. Insert a new `Class.ImageButton` into the **SettingsMenu** container and rename it **CloseButton**.![Explorer window showing a new ImageButton inserted into SettingsMenu and renamed to CloseButton.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-CloseButton.png)![Empty ImageButton positioned in upper-left corner of the settings menu.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Close-Button-Initial.png)
2. With **CloseButton** selected, set the following properties:
  - `Class.ImageButton.AnchorPoint|AnchorPoint` = `1, 0` (top-right corner)
  - `Class.ImageButton.BackgroundTransparency|BackgroundTransparency` = `1` (fully transparent)
  - `Class.ImageButton.Position|Position` = `1, -10, 0, 10` (10 pixel inset from top-right corner)
  - `Class.ImageButton.Size|Size` = `0.15, 0, 0.15, 0` (15% of frame height once aspect ratio is constrained)
  - `Class.ImageButton.Image|Image` = `rbxassetid://5577404210` (asset ID of close button symbol)
  - `Class.ImageButton.ImageTransparency|ImageTransparency` = `0.25` (75% opaque)
3. Insert a `Class.UIAspectRatioConstraint` into the button with default properties (1:1 width to height).![Explorer window showing a UIAspectRatioConstraint inserted into the CloseButton button.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsMenu-CloseButton-UIAspectRatioConstraint.png)![Finalized close button in upper-right corner of settings menu.](../../../assets/tutorials/interactive-ui/Settings-Menu-Design-Close-Button-Finalized.png)

## Create the control modules

An extensible **control module** setup makes interactive UI management more streamlined than individual scripts placed within each object. `Class.ModuleScript|ModuleScripts` facilitate this extensible functionality by letting you reuse code between scripts on different sides of the client‑server boundary or the same side of the boundary.

### Stateful object controller

The following stateful object controller module lets you attach behavior to UI objects such as **SettingsButton** and **SettingsMenu**, and easily toggle/tween between various states. To create the module:

1. Insert a `Class.ModuleScript` into the `Class.ReplicatedStorage` container and rename it to **StatefulObjectController**.![Explorer window showing the StatefulObjectController module inside the ReplicatedStorage container.](../../../assets/tutorials/interactive-ui/ReplicatedStorage-StatefulObjectController.png)
2. Paste the following code inside the module:```lua
local TweenService = game:GetService("TweenService")

local StatefulObjectController = {}
StatefulObjectController.__index = StatefulObjectController

export type StateName = string
export type State = {
	transition: TweenInfo,
	properties: { [string]: any },
}

function StatefulObjectController.hydrate(props: {
		object: Instance,
		states: { [StateName]: State },
		initialStateName: StateName
	})
	local object, states, initialStateName = props.object, props.states, props.initialStateName

	local self = setmetatable({
		states = states,
		currentStateName = initialStateName,
		tweens = {},
	}, StatefulObjectController)

	-- Create tweens for reuse to avoid making new tweens every time state is changed
	for stateName, state in states do
		self.tweens[stateName] = TweenService:Create(object, state.transition, state.properties)
	end

	self:setState(self.currentStateName)

	return self
end

function StatefulObjectController:setState(stateName: StateName)
	local stateTween: Tween = self.tweens[stateName]
	if not stateTween then
		warn(string.format("Attempted to set %s to unknown state '%s'", self.object:GetFullName(), stateName))
		return
	end

	self.currentStateName = stateName

	-- Make sure other tweens aren't conflicting
	for _, tween in self.tweens do
		tween:Cancel()
	end

	stateTween:Play()
end

return StatefulObjectController
```** Code Explanation**| Lines | Purpose |
| --- | --- | | `6`‑`10` | Defines and exports the Luau types to improve autocomplete and linting when using this module. | | `12`‑`33` | Function used to initialize and attach behavior to a stateful UI object, accepting a `Class.GuiObject` as `object`, a table of states and their respective `Datatype.TweenInfo` data, and an initial state name. Inside this function, lines `26`‑`28` construct `Class.Tween\|Tweens` for each state, and line `30` calls the module's `setState()` function to set the object to the initial state. | | `35`‑`50` | Function used to set/change the state of a stateful object. Line `42` sets the object's `currentStateName` to the state being set, lines `45`‑`47` cancel any running tweens to prevent conflicts, and line `49` executes the state's tween(s). |

### Slider controller

An additional module initializes and controls the two volume sliders. It also allows you to connect a callback function to each slider in order to detect player interaction with the slider and apply desired changes in the experience.

1. Insert a `Class.ModuleScript` into the `Class.ReplicatedStorage` container and rename it to **SliderController**.![Explorer window showing the SliderController module inside the ReplicatedStorage container.](../../../assets/tutorials/interactive-ui/ReplicatedStorage-SliderController.png)
2. Paste the following code inside the module:```lua
local SliderController = {}
SliderController.__index = SliderController

export type Value = number
export type OnChanged = (Value) -> ()

function SliderController.hydrate(props: {
		object: Instance,
		onChanged: OnChanged,
		initialValue: Value?
	})
	local object, onChanged, initialValue = props.object, props.onChanged, props.initialValue

	local handle = object:FindFirstChild("Handle", true)
	if not handle then
		warn(string.format("Attempted to hydrate slider %s but couldn't find Handle", object:GetFullName()))
	end

	local innerFill = object:FindFirstChild("InnerFill", true)
	if not innerFill then
		warn(string.format("Attempted to hydrate slider %s but couldn't find InnerFill", object:GetFullName()))
	end

	local dragDetector = handle:FindFirstChildWhichIsA("UIDragDetector")
	if not dragDetector then
		warn(string.format("Attempted to hydrate slider %s but couldn't find UIDragDetector", object:GetFullName()))
	end

	local self = setmetatable({
		handle = handle,
		innerFill = innerFill,
		dragDetector = dragDetector,
		value = initialValue or 0.5,
		onChanged = onChanged,
	}, SliderController)

	-- Set initial value
	self:setValue(self.value)

	-- Connect detector to player manipulation
	self.dragConnection = dragDetector.DragContinue:Connect(function()
		self:setValue(handle.Position.X.Scale)
	end)

	return self
end

function SliderController:setValue(value: Value)
	local clampedValue = math.clamp(value, 0, 1)
	self.value = clampedValue

	-- Update the handle position and inner frame size to match
	self.handle.Position = UDim2.fromScale(clampedValue, 0.5)
	self.innerFill.Size = UDim2.fromScale(clampedValue, 1)

	-- Run the user's callback with the latest value
	local changeSuccess, changeResult = pcall(self.onChanged, clampedValue)
	if not changeSuccess then
		warn("Error in slider callback:", changeResult)
	end
end

return SliderController
```** Code Explanation**| Lines | Purpose |
| --- | --- | | `7`‑`46` | Function used to initialize and attach behavior to a slider element, accepting the slider's parent `Class.Frame` as `object`, an `onChanged` callback function to process slider changes, and an initial value for the slider's handle position. Inside the function, lines `14`‑`27` confirm that the slider's [handle](#interactive-handle), [inner fill](#inner-fill), and `Class.UIDragDetector` elements exist. Line `38` calls the module's `setValue()` function and lines `41`‑`43` connect the drag detector's `Class.UIDragDetector.DragContinue\|DragContinue` event to the module's `setValue()` function (see next row for details). | | `48`‑`61` | Function used to set the value of the slider. Inside the function, lines `53`‑`54` ensure the handle's position and inner fill size are synced, and line `57` passes the changed value to the callback function so that you can utilize the value as needed. |

## Create the settings script

With the [settings button](#create-the-settings-button) and [settings menu](#create-the-settings-menu) finalized, you can hook everything together with a single script that utilizes the [control modules](#create-the-control-modules).

1. Insert a new `Class.LocalScript` into **HUDContainer** and rename it to **SettingsScript** to describe its purpose. Note that this script should be at the same level (sibling) as **SettingsMenu** and **SettingsButton**, the top‑level UI objects it will manage.![Explorer window showing the SettingsScript script inside the HUDContainer container.](../../../assets/tutorials/interactive-ui/StarterGui-HUDContainer-SettingsScript.png)
2. Paste the following code inside the script:```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SliderController = require(ReplicatedStorage.SliderController)
local StatefulObjectController = require(ReplicatedStorage.StatefulObjectController)

local HUDContainer = script.Parent

-- Initialize settings button
local settingsButton = StatefulObjectController.hydrate({
	object = HUDContainer:FindFirstChild("SettingsButton"),
	states = {
		menuOpen = {
			transition = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			properties = {
				Rotation = 45,
			},
		},
		menuClosed = {
			transition = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			properties = {
				Rotation = 0,
			},
		},
	},
	initialStateName = "menuClosed"
})

-- Initialize settings menu frame
local settingsMenu = StatefulObjectController.hydrate({
	object = HUDContainer:FindFirstChild("SettingsMenu"),
	states = {
		menuOpen = {
			transition = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
			properties = {
				Position = UDim2.fromScale(0.5, 0.5),
				Visible = true,
			},
		},
		menuClosed = {
			transition = TweenInfo.new(0),
			properties = {
				Position = UDim2.fromScale(0.5, 0.4),
				Visible = false,
			},
		},
	},
	initialStateName = "menuClosed"
})

-- Initialize effects volume slider
local effectsAudio = SoundService:FindFirstChild("Effects")
local effectsVolumeSlider = SliderController.hydrate({
	object = HUDContainer:FindFirstChild("EffectsVolumeSlider", true),
	initialValue = effectsAudio and effectsAudio.Volume or 0.5,
	onChanged = function(value: SliderController.Value)
		if effectsAudio then
			effectsAudio.Volume = value
		end
	end,
})

-- Initialize background volume slider
local backgroundAudio = SoundService:FindFirstChild("Background")
local backgroundVolumeSlider = SliderController.hydrate({
	object = HUDContainer:FindFirstChild("BackgroundVolumeSlider", true),
	initialValue = backgroundAudio and backgroundAudio.Volume or 0.5,
	onChanged = function(value: SliderController.Value)
		if backgroundAudio then
			backgroundAudio.Volume = value
		end
	end,
})

-- Connect buttons to player interaction
HUDContainer:FindFirstChild("SettingsButton").Activated:Connect(function()
	local targetState = if settingsButton.currentStateName == "menuClosed"
		then "menuOpen"
		else "menuClosed"
	settingsButton:setState(targetState)
	settingsMenu:setState(targetState)
end)
HUDContainer:FindFirstChild("CloseButton", true).Activated:Connect(function()
	settingsButton:setState("menuClosed")
	settingsMenu:setState("menuClosed")
end)
```
3. Reference the following sections to explore how the script utilizes the [control modules](#create-the-control-modules).** Settings Button** Lines `10`-`27` initialize and attach behavior to the [settings button](#create-the-settings-button) as follows: | Lines | Purpose |
| --- | --- | | `10`‑`11` | A local reference `settingsButton` is declared and hydrated with the `StatefulObjectController.hydrate()` function, and the **SettingsButton** button within **HUDContainer** is referenced as the object to hydrate. | | `12`‑`25` | A `states` table is passed with two unique states, `menuOpen` and `menuClosed`. Each state contains a transition to declare (through a `Datatype.TweenInfo`) how the particular state will reach its target properties defined in the `properties` table. In this case, `menuOpen` declares a state change to 45° for the button's `Class.ImageButton.Rotation\|Rotation` with an `Enum.EasingStyle.Exponential\|Exponential` tween of ½ second, while `menuClosed` effectively restores the button to its default rotation of `0`. | | `26` | The button's **initial** state is set to `menuClosed` (this could be set to any state name within the `states` table). | Further down in the script (lines `76`-`86`), buttons are connected to player interaction to trigger UI state changes: | Lines | Purpose |
| --- | --- | | `76`‑`82` | **SettingsButton** is connected to the `Class.GuiButton.Activated\|Activated` event of the `Class.GuiButton` class to call an anonymous function. Inside the anonymous function, lines `77`‑`79` toggle a `targetState` variable between `menuOpen` and `menuClosed`. Line `80` then calls `setState()` to set the button's state to `targetState` and line `81` does the same to **SettingsMenu** so that it toggles open or closed with activation of **SettingsButton**. | | `83`‑`86` | **CloseButton** is connected to the `Class.GuiButton.Activated\|Activated` event to call an anonymous function which sets the state of both **SettingsButton** and **SettingsMenu** to `menuClosed`. |** Settings Menu** Lines `30`-`49` initialize and attach behavior to the [settings menu](#create-the-settings-menu) as follows: | Lines | Purpose |
| --- | --- | | `30`‑`31` | A local reference `settingsMenu` is declared and hydrated with the `StatefulObjectController.hydrate()` function and the **SettingsMenu** frame within **HUDContainer** is referenced as the object to hydrate. | | `32`‑`46` | Similar to the settings button, a `states` table is passed with two unique states, `menuOpen` and `menuClosed`. Here, `menuOpen` declares a state change to`Datatype.UDim2.fromScale(0.5, 0.5)` for the frame's `Class.Frame.Position\|Position` with a `Enum.EasingStyle.Bounce\|Bounce` tween of ½ second, as well as a `Class.Frame.Visible\|Visible` state of `true`. In contrast, `menuClosed` declares a positional state change to`Datatype.UDim2.fromScale(0.5, 0.4)` and `Class.Frame.Visible\|Visible` to `false`, but the `Datatype.TweenInfo` with `0` duration on line `41` effectively makes the state change occur instantly. | | `48` | The frame's initial state is set to `menuClosed`. | Further down in the script (lines `76`-`86`), the settings menu is linked to player interaction: | Lines | Purpose |
| --- | --- | | `81` | Sets the same `targetState` for **SettingsMenu** to sync with activation of **SettingsButton**. | | `85` | Sets the state of **SettingsMenu** to `menuClosed` when **CloseButton** is activated. |** Volume Sliders** Lines `51`-`73` initialize and attach behavior to **EffectsVolumeSlider** and **BackgroundVolumeSlider** as follows: | Lines | Purpose |
| --- | --- | | `52` | Sets a local reference to the **Effects** `Class.SoundGroup` within `Class.SoundService`. A `Class.SoundGroup` lets you interrelate multiple `Class.Sound\|Sounds` and control the volume of every sound in the group through the group's `Class.SoundGroup.Volume\|Volume` property. | | `53`‑`54` | A local reference `effectsVolumeSlider` is declared and hydrated with the `SliderController.hydrate()` function and the **EffectsVolumeSlider** frame within **HUDContainer** ⟩ **SettingsMenu** is referenced as the object to hydrate. Note that the second parameter of `true` for `Class.Instance:FindFirstChild()\|FindFirstChild()` tells the method to look recursively down the **HUDContainer** branch to locate **EffectsVolumeSlider**. | | `55` | The slider's initial value is set to the current `Class.SoundGroup.Volume\|Volume` of the **Effects** sound group, or `0.5` as a fallback. | | `56`‑`60` | Establishes the callback function to apply slider value changes to the volume of the **Effects** sound group. | | `64`‑`73` | Essentially the same as lines `52`-`61`, except to hydrate the **BackgroundVolumeSlider** frame within **HUDContainer** ⟩ **SettingsMenu** and apply slider value changes to the volume of the **Background** sound group. |

With **SettingsScript** in place, the experience now offers a fully operational interactive UI example that links a related set of UI objects to player interaction.

> **Success:** If your interactive UI doesn't match the appearance or behavior displayed in this tutorial, remember that you can inspect [UI Fundamentals - Interactivity](https://www.roblox.com/games/138499606610292/UI-Fundamentals-Interactivity) as a completed reference template.