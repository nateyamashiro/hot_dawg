---
name: Humanoid
last_updated: 2026-07-02T02:14:37Z
inherits:
  - Instance
  - Object
type: class
memory_category: Instances
summary: "A special object that gives models the functionality of a character."
---

# Class: Humanoid

> A special object that gives models the functionality of a character.

## Description

The Humanoid is a special object that gives models the functionality of a
character. It grants the model with the ability to physically walk around and
interact with various components of a Roblox experience. Humanoids are always
parented inside of a [Model](/docs/reference/engine/classes/Model.md), and the model is expected to be an
assembly of [BasePart](/docs/reference/engine/classes/BasePart.md) and [Motor6D](/docs/reference/engine/classes/Motor6D.md); the root part of the
assembly is expected to be named `HumanoidRootPart`. It also expects a part
named `Head` to be connected to the character's torso part, either directly or
indirectly. By default, there are two official types of character rigs
supplied by Roblox, each with their own set of rules:

## R6

- A basic character rig that uses 6 parts for limbs.
- The `Head` part must be attached to a part named `Torso`, or the Humanoid
  will die immediately.
- BodyPart appearances are applied using [CharacterMesh](/docs/reference/engine/classes/CharacterMesh.md) objects.
- Certain properties, such as [Humanoid.LeftLeg](/docs/reference/engine/classes/Humanoid.md) and
  [Humanoid.RightLeg](/docs/reference/engine/classes/Humanoid.md), only work with R6.

## R15

- More complex than R6, but also far more flexible and robust.
- Uses 15 parts for limbs.
- The `Head` part must be attached to a part named `UpperTorso` or the
  Humanoid will die immediately.
- BodyPart appearances have to be assembled directly.
- Can be dynamically rescaled by using special [NumberValue](/docs/reference/engine/classes/NumberValue.md) objects
  parented inside of the Humanoid.
- The Humanoid will automatically create [Vector3Value](/docs/reference/engine/classes/Vector3Value.md) objects named
  `OriginalSize` inside of each limb.
- If a NumberValue is parented inside of the Humanoid and is named one of the
  following, it will be used to control the scaling functionality:
  - BodyDepthScale
  - BodyHeightScale
  - BodyWidthScale
  - HeadScale

## Code Samples

**Walking Camera Bobble Effect**

This LocalScript makes the camera bobble as the player's character walks
around, utilizing both the Humanoid's CameraOffset and MoveDirection. It
should be parented inside of the StarterCharacterScripts so that it is
distributed into a player's character as expected.

```lua
local RunService = game:GetService("RunService")

local playerModel = script.Parent
local humanoid = playerModel:WaitForChild("Humanoid")

local function updateBobbleEffect()
	local now = tick()
	if humanoid.MoveDirection.Magnitude > 0 then -- Is the character walking?
		local velocity = humanoid.RootPart.Velocity
		local bobble_X = math.cos(now * 9) / 5
		local bobble_Y = math.abs(math.sin(now * 12)) / 5

		local bobble = Vector3.new(bobble_X, bobble_Y, 0) * math.min(1, velocity.Magnitude / humanoid.WalkSpeed)
		humanoid.CameraOffset = humanoid.CameraOffset:lerp(bobble, 0.25)
	else
		-- Scale down the CameraOffset so that it shifts back to its regular position.
		humanoid.CameraOffset = humanoid.CameraOffset * 0.75
	end
end

RunService.RenderStepped:Connect(updateBobbleEffect)
```

## Properties

### Property: Humanoid.AutoJumpEnabled

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
  "category": "Jump Settings",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

AutoJumpEnabled sets whether or not the [Humanoid](/docs/reference/engine/classes/Humanoid.md) will attempt to
automatically jump over an obstacle it is walking towards.

Currently, this property only works when the following conditions are
true:

- The Humanoid's character model is the [Player.Character](/docs/reference/engine/classes/Player.md) of a
  [Player](/docs/reference/engine/classes/Player.md).
- The Player in question is using touch controls.

When a player's character spawns, the property's value matches the
player's [Player.AutoJumpEnabled](/docs/reference/engine/classes/Player.md) property - which in turn matches
the [StarterPlayer.AutoJumpEnabled](/docs/reference/engine/classes/StarterPlayer.md) property.

**Auto-Jump Toggle**

This code sample is meant for a TextButton. It allows the player to toggle the
auto-jumping behavior while on a mobile device.

```lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local button = script.Parent

local function update()
	-- Update button text
	if player.AutoJumpEnabled then
		button.Text = "Auto-Jump is ON"
	else
		button.Text = "Auto-Jump is OFF"
	end
	-- Reflect the property in the player's character, if they have one
	if player.Character then
		local human = player.Character:FindFirstChild("Humanoid")
		if human then
			human.AutoJumpEnabled = player.AutoJumpEnabled
		end
	end
end

local function onActivated()
	-- Toggle auto-jump
	player.AutoJumpEnabled = not player.AutoJumpEnabled
	-- Update everything else
	update()
end

button.Activated:Connect(onActivated)
update()
```

### Property: Humanoid.AutomaticScalingEnabled

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
  "category": "Game",
  "capabilities": [
    "AvatarAppearance"
  ]
}
```

The Humanoid has six child scale values including `BodyDepthScale`,
`BodyHeightScale`, `BodyProportionScale`, `BodyTypeScale`,
`BodyWidthScale`, `HeadScale`. Changing the value of any of these causes
the character's body parts and accessories to change size, but only if
`AutomaticScalingEnabled` is true.

### Property: Humanoid.AutoRotate

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
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

The AutoRotate property describes whether or not the Humanoid will
automatically rotate to face in the direction they are moving. When set to
true, the character model will gradually turn to face their movement
direction as the Humanoid walks around. When set to false, the character
model will remain fixated in its current rotation, unless a rotating force
is applied to the _HumanoidRootPart_.

If the character model happens to be the character of a player, then the
behavior of the Humanoid's rotation is influenced by the UserGameSetting's
RotateType property.

When the AutoRotate property is set to true, the RotateType property has
the following effects on the Humanoid's rotation:

| RotationType | Behavior | Context |
| --- | --- | --- |
| MovementRelative |  | |
| CameraRelative | Character will rotate to face in the direction of the camera. | Player has their camera zoomed into first-person, or they are in shift-lock mode. |

**AutoRotate Button**

This script adds the functionality of a button to a part, which switches the
AutoRotate property of whoever touches it.

```lua
local button = script.Parent
local enabled = true

local ON_COLOR = BrickColor.Green()
local OFF_COLOR = BrickColor.Red()

local function touchButton(humanoid)
	if enabled then
		enabled = false
		button.BrickColor = OFF_COLOR

		if humanoid.AutoRotate then
			print(humanoid:GetFullName() .. " can no longer auto-rotate!")
			humanoid.AutoRotate = false
		else
			print(humanoid:GetFullName() .. " can now auto-rotate!")
			humanoid.AutoRotate = true
		end

		task.wait(1)
		button.BrickColor = ON_COLOR
		enabled = true
	end
end

local function onTouched(hit)
	local char = hit:FindFirstAncestorWhichIsA("Model")
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			touchButton(humanoid)
		end
	end
end

button.Touched:Connect(onTouched)
button.BrickColor = ON_COLOR
```

### Property: Humanoid.BreakJointsOnDeath

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
  "category": "Behavior",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

Determines whether the humanoid's joints break when in the
[HumanoidStateType.Dead](/docs/reference/engine/enums/HumanoidStateType.md) state. Defaults to true.

### Property: Humanoid.CameraOffset

```json
{
  "type": "Vector3",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

The CameraOffset property specifies an offset to the camera's subject
position when its [Camera.CameraSubject](/docs/reference/engine/classes/Camera.md) is set to this
[Humanoid](/docs/reference/engine/classes/Humanoid.md).

The offset is applied in object-space, relative to the orientation of the
Humanoid's _HumanoidRootPart_. For example, an offset [Vector3](/docs/reference/engine/datatypes/Vector3.md)
value of _(0, 10, 0)_ offsets the player's camera to 10 studs above the
player's humanoid.

**Walking Camera Bobble Effect**

This LocalScript makes the camera bobble as the player's character walks
around, utilizing both the Humanoid's CameraOffset and MoveDirection. It
should be parented inside of the StarterCharacterScripts so that it is
distributed into a player's character as expected.

```lua
local RunService = game:GetService("RunService")

local playerModel = script.Parent
local humanoid = playerModel:WaitForChild("Humanoid")

local function updateBobbleEffect()
	local now = tick()
	if humanoid.MoveDirection.Magnitude > 0 then -- Is the character walking?
		local velocity = humanoid.RootPart.Velocity
		local bobble_X = math.cos(now * 9) / 5
		local bobble_Y = math.abs(math.sin(now * 12)) / 5

		local bobble = Vector3.new(bobble_X, bobble_Y, 0) * math.min(1, velocity.Magnitude / humanoid.WalkSpeed)
		humanoid.CameraOffset = humanoid.CameraOffset:lerp(bobble, 0.25)
	else
		-- Scale down the CameraOffset so that it shifts back to its regular position.
		humanoid.CameraOffset = humanoid.CameraOffset * 0.75
	end
end

RunService.RenderStepped:Connect(updateBobbleEffect)
```

### Property: Humanoid.DisplayDistanceType

```json
{
  "type": "HumanoidDisplayDistanceType",
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
    "AvatarAppearance"
  ]
}
```

The **DisplayDistanceType** property controls the distance behavior of the
humanoid's name and health display. This property is set using the
[HumanoidDisplayDistanceType](/docs/reference/engine/enums/HumanoidDisplayDistanceType.md) enum with three available values, each
with their own set of rules:

- When set to [Viewer](/docs/reference/engine/enums/HumanoidDisplayDistanceType.md), the humanoid sees
  the name/health of other humanoids within range of its own
  `NameDisplayDistance` and `HealthDisplayDistance`.
- When set to [Subject](/docs/reference/engine/enums/HumanoidDisplayDistanceType.md), the humanoid
  takes **full control** over its own name and health display through its
  `NameDisplayDistance` and `HealthDisplayDistance` values.
- When set to [None](/docs/reference/engine/enums/HumanoidDisplayDistanceType.md), the humanoid's name
  and health bar do not appear under any circumstances.

See
[Character Name/Health Display](/docs/en-us/characters/name-health-display.md)
for an in-depth guide on controlling the appearance of character names and
health bars.

**Displaying a Humanoid's Health and Name**

This example demonstrates how to set a `Humanoid`'s
[Humanoid.DisplayerDistanceType](/docs/reference/engine/classes/Humanoid.md),
[Humanoid.HealthDisplayDistance](/docs/reference/engine/classes/Humanoid.md), and
[Humanoid.NameDisplayDistance](/docs/reference/engine/classes/Humanoid.md) properties. These properties determine
how a humanoid's healthbar and name are rendered for a player.

First, we change the DisplayDistanceType to Viewer using
[HumanoidDisplayDistanceType](/docs/reference/engine/enums/HumanoidDisplayDistanceType.md). When set to viewer, the humanoid's Name
and healthbar will be displayed based on the distance settings of the humanoid
viewing them.

Then, the humanoid's HealthDisplayDistance is set to 0. Setting the property
to 0 hides the healthbar completely. It is not displayed at any distance.

Finally, the humanoid's NameDisplayDistance is set to 100. This means that the
humanoid's name will be visible to other humanoid's within 100 studs.

This example should work as expected when placed inside a `Script` that is a
child of the humanoid.

```lua
local humanoid = script.Parent

humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
humanoid.HealthDisplayDistance = 0
humanoid.NameDisplayDistance = 100
```

### Property: Humanoid.DisplayName

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
    "AvatarAppearance"
  ]
}
```

`DisplayName` is a property that determines the Humanoid's name display
when visible. By default, a new Humanoid will have the value of an empty
string. If `DisplayName` is an empty string, the humanoid's name display
will default to the humanoid's parent's name property.

#### Player Character Loading

When players load their character, either automatically or through the use
of [LoadCharacterAsync()](/docs/reference/engine/classes/Player.md), the Humanoid
that is created by the engine will have its `DisplayName` property set to
the player's `DisplayName` property.

#### StarterCharacter and StarterHumanoid

When a [Humanoid](/docs/reference/engine/classes/Humanoid.md) named `StarterHumanoid` is parented to
[StarterPlayer](/docs/reference/engine/classes/StarterPlayer.md), or when a Humanoid is present in a Model named
`StarterCharacter`, the DisplayName property will be respected when
Characters are loaded by Players in the game. The engine will only
override the `DisplayName` property of the Humanoid with the `DisplayName`
property of the player if the [Humanoid.DisplayName](/docs/reference/engine/classes/Humanoid.md) of
`StarterHumanoid` is an empty string.

### Property: Humanoid.EvaluateStateMachine

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
  "category": "Behavior",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

Used to disable the internal physics and state machine of the `Humanoid`.

#### What does turning this off do?

- **No forces** - The humanoid will not apply forces to any of its parts.
  The humanoid will not move the character in any way.
- **No sensors** - The humanoid will not run any spatial queries to detect
  floors, ladders, or other obstacles (such as auto-jump).
- **No collision changes** - The humanoid will not alter the collision
  state of any of the character parts. By default, only the torso and head
  have [Part.CanCollide](/docs/reference/engine/classes/Part.md) enabled.
- **No state transitions or replication** - The humanoid will not
  automatically update its state. You can still set humanoid state with a
  script, but it will not automatically replicate.

#### What does turning this off **not** do?

- **State events** - If manually setting humanoid states, the events for
  each of the humanoid's states and
  [StateChanged](/docs/reference/engine/classes/Humanoid.md) will still fire, which means
  the Animate script will still receive them and animate the character
  based on its current humanoid state.
- **Appearance** - [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md), clothes, accessories and
  other humanoid rendering behavior.
- **Camera and player scripts** - The humanoid is still linked to
  [Players](/docs/reference/engine/classes/Players.md) and camera scripts, which ensures the camera will
  continue to follow the [Humanoid.RootPart](/docs/reference/engine/classes/Humanoid.md).
- **Player input handling** - The [Humanoid.MoveDirection](/docs/reference/engine/classes/Humanoid.md) property
  will still be updated via the [Humanoid:Move()](/docs/reference/engine/classes/Humanoid.md) function and
  [PlayerScripts](/docs/reference/engine/classes/PlayerScripts.md) for input.

### Property: Humanoid.FloorMaterial

```json
{
  "type": "Material",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

This is a read-only property that describes the [Material](/docs/reference/engine/enums/Material.md) the
[Humanoid](/docs/reference/engine/classes/Humanoid.md) is currently standing on. It works with both regular
[Parts](/docs/reference/engine/classes/BasePart.md) and [Terrain](/docs/reference/engine/classes/Terrain.md) voxels.

The code sample below demonstrates how to listen to when this property
changes using [Object:GetPropertyChangedSignal()](/docs/reference/engine/classes/Object.md). When the material
the humanoid is standing on changes, it will print a message indicating
the new material being stood on.

```lua
local Humanoid = route.to.humanoid

Humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
	print("New value for FloorMaterial: " .. tostring(Humanoid.FloorMaterial))
end)
```

#### Caveats

- When the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is not standing on a floor, the value of this
  property will be set to _Air_.
  - This occurs because Enum properties cannot have an empty value.
  - This can cause some confusion if a part has its material is set to
    Air, though in practice, parts are not supposed to use that material
    in the first place.
- The character model of the [Humanoid](/docs/reference/engine/classes/Humanoid.md) must be able to collide with
  the floor, or else it will not be detected.
  - You cannot test if the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is swimming with this
    property. You should instead use its [Humanoid:GetState()](/docs/reference/engine/classes/Humanoid.md)
    function.

### Property: Humanoid.Health

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
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Game",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

This property represents the current health of the [Humanoid](/docs/reference/engine/classes/Humanoid.md). The
value is restricted to the range between 0 and
[MaxHealth](/docs/reference/engine/classes/Humanoid.md). If the humanoid is dead, this
property is continually set to 0.

Note that the [TakeDamage()](/docs/reference/engine/classes/Humanoid.md) function may be
used to subtract from [Health](/docs/reference/engine/classes/Humanoid.md) instead of setting
the property directly.

#### Health Regeneration

By default, a passive health regeneration script is automatically inserted
into humanoids. This causes non-dead player characters to regenerate 1% of
[MaxHealth](/docs/reference/engine/classes/Humanoid.md) each second. To disable this
regeneration behavior, add an empty [Script](/docs/reference/engine/classes/Script.md) named **Health** to
[StarterCharacterScripts](/docs/reference/engine/classes/StarterCharacterScripts.md).

#### Health Bar Display

When [Health](/docs/reference/engine/classes/Humanoid.md) is less than
[MaxHealth](/docs/reference/engine/classes/Humanoid.md), a health bar is displayed
in-experience. The display behavior of the health bar is dependent on the
[HealthDisplayDistance](/docs/reference/engine/classes/Humanoid.md) and
[HealthDisplayType](/docs/reference/engine/classes/Humanoid.md).

See
[Character Name/Health Display](/docs/en-us/characters/name-health-display.md)
for an in-depth guide on controlling the appearance of character names and
health bars.

#### Death

When the value of the character's health reaches 0, the [Humanoid](/docs/reference/engine/classes/Humanoid.md)
automatically transitions to the [HumanoidStateType.Dead](/docs/reference/engine/enums/HumanoidStateType.md) state. In
this state, [Health](/docs/reference/engine/classes/Humanoid.md) is locked to 0; however, there
is no error or warning for setting the [Health](/docs/reference/engine/classes/Humanoid.md) of a
dead humanoid to a positive nonzero value.

### Property: Humanoid.HealthDisplayDistance

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
    "AvatarAppearance"
  ]
}
```

This property is a number used in conjunction with the
[DisplayDistanceType](/docs/reference/engine/classes/Humanoid.md) property to
control the distance from which a humanoid's health bar can be seen.

See
[Character Name/Health Display](/docs/en-us/characters/name-health-display.md)
for an in-depth guide on controlling the appearance of character names and
health bars.

### Property: Humanoid.HealthDisplayType

```json
{
  "type": "HumanoidHealthDisplayType",
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
    "AvatarAppearance"
  ]
}
```

This property controls when a humanoid's health bar is allowed to be
displayed. By default, this property is set to
[DisplayWhenDamaged](/docs/reference/engine/enums/HumanoidHealthDisplayType.md), which makes the
health bar only display when a humanoid's [Health](/docs/reference/engine/classes/Humanoid.md)
is less than its [MaxHealth](/docs/reference/engine/classes/Humanoid.md). It can also be set
to [AlwaysOn](/docs/reference/engine/enums/HumanoidHealthDisplayType.md), which makes the health bar
always display, or [AlwaysOff](/docs/reference/engine/enums/HumanoidHealthDisplayType.md), which
prevents it from ever displaying.

Note that this property functions independently of the humanoid's
[HealthDisplayDistance](/docs/reference/engine/classes/Humanoid.md) property
which is responsible for making the health bar fade out at certain
distances. If `Humanoid.HealthDisplayType|HealthDisplayType` is set to
[AlwaysOn](/docs/reference/engine/enums/HumanoidHealthDisplayType.md), it will still fade out
depending the how
[HealthDisplayDistance](/docs/reference/engine/classes/Humanoid.md) is
configured.

See
[Character Name/Health Display](/docs/en-us/characters/name-health-display.md)
for an in-depth guide on controlling the appearance of character names and
health bars.

### Property: Humanoid.HipHeight

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
  "category": "Game",
  "capabilities": [
    "AvatarAppearance"
  ],
  "simulationAccess": true
}
```

Determines the distance (in studs) off the ground the
[RootPart](/docs/reference/engine/classes/Humanoid.md) should be when the humanoid is
standing. The [RigType](/docs/reference/engine/classes/Humanoid.md) influences the way this
property behaves.

For R15 rigs, a suitable hip height is preset to ensure the height of the
[RootPart](/docs/reference/engine/classes/Humanoid.md) is correct. The height of the legs is
not used. The overall height of the humanoid can be described in the
following formula:

```lua
Height = (0.5 * RootPart.Size.Y) + HipHeight
```

For R6 rigs, [HipHeight](/docs/reference/engine/classes/Humanoid.md) instead describes a
relative offset. The overall height of the humanoid can be described in
the following formula:

```lua
Height = LeftLeg.Size.Y + (0.5 * RootPart.Size.Y) + HipHeight
```

### Property: Humanoid.Jump

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
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

If `true`, the [Humanoid](/docs/reference/engine/classes/Humanoid.md) jumps with an upwards force equal to the
value of [Humanoid.JumpPower](/docs/reference/engine/classes/Humanoid.md) or the height of
[Humanoid.JumpHeight](/docs/reference/engine/classes/Humanoid.md), depending on the value of
[Humanoid.UseJumpPower](/docs/reference/engine/classes/Humanoid.md).

### Property: Humanoid.JumpHeight

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
  "category": "Jump Settings",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

Provides control over the height a [Humanoid](/docs/reference/engine/classes/Humanoid.md) jumps, in studs. The
starting value of this property is determined by the value of
[StarterPlayer.CharacterJumpHeight](/docs/reference/engine/classes/StarterPlayer.md) which defaults to 7.2.

Although setting this property to 0 will effectively prevent the humanoid
from jumping, it's recommended to disable jumping by disabling the
[HumanoidStateType.Jumping](/docs/reference/engine/enums/HumanoidStateType.md) state through
[Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md).

This property is only visible in the
[Properties](/docs/en-us/studio/properties.md) window if
[Humanoid.UseJumpPower](/docs/reference/engine/classes/Humanoid.md) is set to **false**, as it is not relevant
otherwise (instead, [Humanoid.JumpPower](/docs/reference/engine/classes/Humanoid.md) is used).

### Property: Humanoid.JumpPower

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
  "category": "Jump Settings",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

Determines how much upwards force is applied to the [Humanoid](/docs/reference/engine/classes/Humanoid.md) when
jumping. The starting value of this property is determined by the value of
[StarterPlayer.CharacterJumpPower](/docs/reference/engine/classes/StarterPlayer.md) which defaults to 50 and is
constrained between 0 and 1000. Note that jumps are also influenced by the
[Workspace.Gravity](/docs/reference/engine/classes/Workspace.md) property which determines the acceleration due
to gravity.

Although setting this property to 0 will effectively prevent the humanoid
from jumping, it's recommended to disable jumping by disabling the
[HumanoidStateType.Jumping](/docs/reference/engine/enums/HumanoidStateType.md) state through
[Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md).

This property is only visible in the
[Properties](/docs/en-us/studio/properties.md) window if
[Humanoid.UseJumpPower](/docs/reference/engine/classes/Humanoid.md) is set to **true**, as it is not relevant
otherwise (instead, [Humanoid.JumpHeight](/docs/reference/engine/classes/Humanoid.md) is used).

### Property: Humanoid.MaxHealth

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
  "category": "Game",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

The maximum value of a humanoid's [Health](/docs/reference/engine/classes/Humanoid.md).

The value of this property is used alongside the
[Health](/docs/reference/engine/classes/Humanoid.md) property to size the default health bar
display. When a humanoid's [Health](/docs/reference/engine/classes/Humanoid.md) reaches
[MaxHealth](/docs/reference/engine/classes/Humanoid.md), its health bar may not be displayed,
depending on its [HealthDisplayType](/docs/reference/engine/classes/Humanoid.md)
property.

### Property: Humanoid.MaxSlopeAngle

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
  "category": "Game",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

This property determines the maximum slope angle that a humanoid can
climb. If the angle of a slope is greater than a humanoid's MaxSlopeAngle,
they will slide down the slope.

When a character spawns, this property is set according to the value of
[StarterPlayer.CharacterMaxSlopeAngle](/docs/reference/engine/classes/StarterPlayer.md).

The value of this property is constrained to values between 0° and 89°. It
defaults to 89°, so humanoids can climb pretty much any slope they want by
default.

**Limiting The Slope a Humanoid Can Walk Up**

The example below demonstrates the effect of the MaxSlopAngle property by
limiting the maximum slope the [Players.LocalPlayer](/docs/reference/engine/classes/Players.md) can walk up to 30°.
The local player will slide down any slope greater than 30°.

This code below works as expected when placed in a `LocalScript`.

```lua
local player = game.Players.LocalPlayer
local char = player.CharacterAdded:wait()
local h = char:FindFirstChild("Humanoid")

h.MaxSlopeAngle = 30
```

### Property: Humanoid.MoveDirection

```json
{
  "type": "Vector3",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

**MoveDirection** is a read-only property that describes the direction a
[Humanoid](/docs/reference/engine/classes/Humanoid.md) is walking in, as a unit vector or zero length vector.
The direction is described in world space.

Because this property is read-only, it cannot be set by a [Script](/docs/reference/engine/classes/Script.md)
or [LocalScript](/docs/reference/engine/classes/LocalScript.md).

**Walking Camera Bobble Effect**

This LocalScript makes the camera bobble as the player's character walks
around, utilizing both the Humanoid's CameraOffset and MoveDirection. It
should be parented inside of the StarterCharacterScripts so that it is
distributed into a player's character as expected.

```lua
local RunService = game:GetService("RunService")

local playerModel = script.Parent
local humanoid = playerModel:WaitForChild("Humanoid")

local function updateBobbleEffect()
	local now = tick()
	if humanoid.MoveDirection.Magnitude > 0 then -- Is the character walking?
		local velocity = humanoid.RootPart.Velocity
		local bobble_X = math.cos(now * 9) / 5
		local bobble_Y = math.abs(math.sin(now * 12)) / 5

		local bobble = Vector3.new(bobble_X, bobble_Y, 0) * math.min(1, velocity.Magnitude / humanoid.WalkSpeed)
		humanoid.CameraOffset = humanoid.CameraOffset:lerp(bobble, 0.25)
	else
		-- Scale down the CameraOffset so that it shifts back to its regular position.
		humanoid.CameraOffset = humanoid.CameraOffset * 0.75
	end
end

RunService.RenderStepped:Connect(updateBobbleEffect)
```

### Property: Humanoid.NameDisplayDistance

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
    "AvatarAppearance"
  ]
}
```

The **NameDisplayDistance** property is a number used in conjunction with
the [Humanoid.DisplayDistanceType](/docs/reference/engine/classes/Humanoid.md) property to control the distance
from which a humanoid's name can be seen.

See
[Character Name/Health Display](/docs/en-us/characters/name-health-display.md)
for an in-depth guide on controlling the appearance of character names and
health bars.

### Property: Humanoid.NameOcclusion

```json
{
  "type": "NameOcclusion",
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
    "AvatarAppearance"
  ]
}
```

Controls whether a humanoid's name and health bar can be seen behind walls
or other objects. This property is a [NameOcclusion](/docs/reference/engine/enums/NameOcclusion.md) value and can be
configured to occlude all names, enemy names, or disable occlusion
entirely.

In cases where the [LocalPlayer](/docs/reference/engine/classes/Players.md) has no
[Humanoid](/docs/reference/engine/classes/Humanoid.md) associated with it, this property instead applies to the
subject [Humanoid](/docs/reference/engine/classes/Humanoid.md).

See
[Character Name/Health Display](/docs/en-us/characters/name-health-display.md)
for an in-depth guide on controlling the appearance of character names and
health bars.

**Occlude Player Names**

In the below example, `Player|Players` will not be able to see each other's
[Player.Character](/docs/reference/engine/classes/Player.md) names when they are obscured behind
`BasePart|BaseParts`.

```lua
local Players = game:GetService("Players")

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.NamOcclusion = Enum.NameOcclusion.OccludeAll
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(onPlayerAdded)
```

### Property: Humanoid.PlatformStand

```json
{
  "type": "boolean",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

Determines whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is currently in the
[HumanoidStateType.PlatformStanding](/docs/reference/engine/enums/HumanoidStateType.md) state. When true, the Humanoid
is in a state where it is free-falling and cannot move. This state behaves
similar to sitting, except that jumping does not free the humanoid from
the state.

### Property: Humanoid.RequiresNeck

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
  "category": "Behavior",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

Allows developers to disable the behavior where a player
`Character|character` dies if the Neck [Motor6D](/docs/reference/engine/classes/Motor6D.md) is removed or
disconnected even momentarily. This property defaults to true.

### Property: Humanoid.RigType

```json
{
  "type": "HumanoidRigType",
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
    "AvatarAppearance"
  ]
}
```

**RigType** describes whether a [Humanoid](/docs/reference/engine/classes/Humanoid.md) is utilizing the legacy
R6 character rig, or the newer R15 character rig.

The R6 rig uses 6 visible [Parts](/docs/reference/engine/classes/Part.md) while the R15 rig uses 15
visible [Parts](/docs/reference/engine/classes/Part.md). R15 rigs have more joints than R6 rigs, making
them much more versatile when being animated.

Note that if this property is set incorrectly, the [Humanoid](/docs/reference/engine/classes/Humanoid.md) will
not function correctly. For example, if a R15 humanoid's **RigType** is
set to R6, the [Humanoid](/docs/reference/engine/classes/Humanoid.md) will die as there is no [BasePart](/docs/reference/engine/classes/BasePart.md)
called **Torso** connected to a [BasePart](/docs/reference/engine/classes/BasePart.md) called **Head**.

### Property: Humanoid.RootPart

```json
{
  "type": "BasePart",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": true
  },
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

A reference to the humanoid's `HumanoidRootPart` object. The
`HumanoidRootPart` is required for all assemblies that include a
[Humanoid](/docs/reference/engine/classes/Humanoid.md) and is the primary driving part of the [Humanoid](/docs/reference/engine/classes/Humanoid.md)
that controls a humanoid's movement through the 3D world. This part is
normally invisible and typically resides in the local origin center of the
character model.

The `HumanoidRootPart` is included in all platform-wide avatar characters,
and automatically created when a character model is imported into Studio.
It's possible to manually add a `HumanoidRootPart` to a model by adding a
[Part](/docs/reference/engine/classes/Part.md) named `HumanoidRootPart` and ensuring it's the root part of
the assembly.

Use this property to reference the specific `HumanoidRootPart` without
searching the model hierarchy. You can get or set the [CFrame](/docs/reference/engine/classes/CFrame.md) of
this part to change position or reorient the entire character model.

For R15 or higher-fidelity characters, the [Model.PrimaryPart](/docs/reference/engine/classes/Model.md) of
the [Player.Character](/docs/reference/engine/classes/Player.md) model is also set to `HumanoidRootPart`.

While R6 characters also include a `HumanoidRootPart`, the R6 characters,
[Model.PrimaryPart](/docs/reference/engine/classes/Model.md) is set to the `Head` part.

### Property: Humanoid.SeatPart

```json
{
  "type": "BasePart",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

SeatPart is a reference to the seat that a [Humanoid](/docs/reference/engine/classes/Humanoid.md) is currently
sitting in, if any. The value of this property can be either a
[Seat](/docs/reference/engine/classes/Seat.md), or a [VehicleSeat](/docs/reference/engine/classes/VehicleSeat.md). It will be _nil_ if the Humanoid
is not currently sitting in a seat.

Note:

- For a bool describing if the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is currently sitting or
  not, see [Humanoid.Sit](/docs/reference/engine/classes/Humanoid.md)

### Property: Humanoid.Sit

```json
{
  "type": "boolean",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

The Sit property is a boolean that indicates whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md)
is currently sitting. [Humanoids](/docs/reference/engine/classes/Humanoid.md) can be forced into a
sitting state by setting this property's value to true. If the
[Humanoid](/docs/reference/engine/classes/Humanoid.md) isn't attached to a seat while in its sitting state, it
will trip over with no collision in its legs. A [Humanoid](/docs/reference/engine/classes/Humanoid.md) can
escape from the sitting state by jumping.

Note:

- The [Seat](/docs/reference/engine/classes/Seat.md) or [VehicleSeat](/docs/reference/engine/classes/VehicleSeat.md) the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is sitting
  on can be obtained using the [Humanoid.SeatPart](/docs/reference/engine/classes/Humanoid.md) property
- It is possible to detect when a Humanoid sits by connecting to the
  [Humanoid.Seated](/docs/reference/engine/classes/Humanoid.md) event.

### Property: Humanoid.TargetPoint

```json
{
  "type": "Vector3",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

**Do not use** This property only works with Experimental Mode enabled,
which has been entirely discontinued.

This property describes a 3D position in space where the [Player](/docs/reference/engine/classes/Player.md)
controlling this [Humanoid](/docs/reference/engine/classes/Humanoid.md) last clicked with a [Tool](/docs/reference/engine/classes/Tool.md)
equipped.

This property is primarily used by classic tools to determine what a
humanoid is targeting when they activate a tool. If you give an NPC a
classic rocket launcher, set their **TargetPoint**, and then call the
tool's [Tool:Activate()](/docs/reference/engine/classes/Tool.md) function, you can make the NPC fire a
rocket at the target point.

### Property: Humanoid.UseJumpPower

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
  "category": "Jump Settings",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

When a character spawns, this property is set according to the value of
[StarterPlayer.CharacterUseJumpPower](/docs/reference/engine/classes/StarterPlayer.md), which defaults to true.

When jumping, with this set to false, the [Humanoid.JumpHeight](/docs/reference/engine/classes/Humanoid.md)
value is used to ensure the humanoid jumps to that height. With this set
to true, the [Humanoid.JumpPower](/docs/reference/engine/classes/Humanoid.md) value is used to apply an upward
force.

### Property: Humanoid.WalkSpeed

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
  "category": "Game",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

This property describes how quickly the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is able to walk,
in studs per second. It defaults to the value of
[StarterPlayer.CharacterWalkSpeed](/docs/reference/engine/classes/StarterPlayer.md) (`16`), meaning a player
character can move 16 studs in any direction each second.

#### Notes

- When controlled on a mobile device or a gamepad, a humanoid can walk
  slower than its [WalkSpeed](/docs/reference/engine/classes/Humanoid.md) if the controlling
  thumbstick is moved just a gradual degree from center.
- You can freeze a humanoid in place by setting
  [WalkSpeed](/docs/reference/engine/classes/Humanoid.md) to `0`, effectively preventing the
  controlling player from moving it through the default movement
  mechanisms. Note, however, that [WalkSpeed](/docs/reference/engine/classes/Humanoid.md) is
  a client‑replicated property which can be modified locally, so it should
  **not** be used as a security mechanism or as the sole method for
  preventing humanoid movement.
- The default animation script scales a humanoid's movement animations
  based on how fast it is moving relative to the default speed of 16
  studs/second.
- The speed at which the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is currently walking can be
  obtained using the [Running](/docs/reference/engine/classes/Humanoid.md) event.

### Property: Humanoid.WalkToPart

```json
{
  "type": "BasePart",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

`WalkToPart` is a reference to a [BasePart](/docs/reference/engine/classes/BasePart.md) that the humanoid is
trying to reach, after having been prompted to do so via the
[MoveTo()](/docs/reference/engine/classes/Humanoid.md) method.

When `WalkToPart` is set and a humanoid is actively trying to reach the
part, it will keep updating its [Vector3](/docs/reference/engine/datatypes/Vector3.md) goal to be the position
of the part, plus the [WalkToPoint](/docs/reference/engine/classes/Humanoid.md) translated
in object space relative to the rotation of the part. This can be
described in Luau as:

```lua
goal = humanoid.WalkToPart.CFrame:PointToObjectSpace(humanoid.WalkToPoint)
```

Note that simply setting the value of `WalkToPart` is not sufficient to
make a humanoid start "following" a part. Call
[MoveTo()](/docs/reference/engine/classes/Humanoid.md) to initiate movement.

### Property: Humanoid.WalkToPoint

```json
{
  "type": "Vector3",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": false,
    "can_save": false
  },
  "thread_safety": "ReadSafe",
  "category": "Control",
  "capabilities": [
    "AvatarBehavior"
  ],
  "simulationAccess": true
}
```

`WalkToPoint` describes the 3D position in space that a humanoid is trying
to reach, after having been prompted to do so via the
[MoveTo()](/docs/reference/engine/classes/Humanoid.md) method.

If a humanoid's [WalkToPart](/docs/reference/engine/classes/Humanoid.md) is set, the goal is
set by transforming `WalkToPoint` relative to the part's position and
rotation. Otherwise, the humanoid will try to reach the 3D position
specified by `WalkToPoint` directly.

Note that simply setting the value of `WalkToPoint` is not sufficient to
make a humanoid start moving toward a point. Call
[MoveTo()](/docs/reference/engine/classes/Humanoid.md) to initiate movement.

### Property: Humanoid.CollisionType

```json
{
  "type": "HumanoidCollisionType",
  "access": "ReadOnly",
  "security": {
    "read": "None",
    "write": "PluginSecurity"
  },
  "serialization": {
    "can_load": true,
    "can_save": true
  },
  "deprecated": true,
  "thread_safety": "ReadSafe",
  "category": "Behavior"
}
```

This property selects the [HumanoidCollisionType](/docs/reference/engine/enums/HumanoidCollisionType.md) for R15 and Rthro
non-player characters.

### Property: Humanoid.maxHealth

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
    "can_save": false
  },
  "deprecated": true,
  "thread_safety": "ReadSafe",
  "category": "Game",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

> **Deprecated:** This deprecated property is a variant of [Humanoid.MaxHealth](/docs/reference/engine/classes/Humanoid.md) which should be used instead.

### Property: Humanoid.LeftLeg *(hidden)*

```json
{
  "type": "BasePart",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": false
  },
  "deprecated": true,
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

> **Deprecated:** This instance only works with the old R6 rig. It will not work with the R15 rig and should not be used in new work not using the R6 rig.

A reference to the humanoid's _Left Leg_ part. The value of this property
will always be `nil` if the humanoid's [RigType](/docs/reference/engine/enums/RigType.md) is set to R15.

### Property: Humanoid.RightLeg *(hidden)*

```json
{
  "type": "BasePart",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": false
  },
  "deprecated": true,
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

> **Deprecated:** This instance only works with the old R6 rig. It will not work with the R15 rig and should not be used in new work not using the R6 rig.

A reference to the humanoid's _Right Leg_ part. The value of this property
will always be `nil` if the humanoid's RigType is set to R15.

### Property: Humanoid.Torso *(hidden)*

```json
{
  "type": "BasePart",
  "access": "ReadWrite",
  "security": {
    "read": "None",
    "write": "None"
  },
  "serialization": {
    "can_load": true,
    "can_save": false
  },
  "deprecated": true,
  "thread_safety": "ReadSafe",
  "category": "Data",
  "capabilities": [
    "AvatarBehavior"
  ]
}
```

> **Deprecated:** This instance only works with the old R6 rig. It will not work with the R15 rig and should not be used in new work not using the R6 rig.

A reference to a humanoid's root driving part. Contrary to the name of
this property, it will only point to the Torso part if a humanoid doesn't
have a HumanoidRootPart.

## Methods

### Method: Humanoid:AddAccessory

**Signature:** `Humanoid:AddAccessory(accessory: Instance): ()`

This method attaches the specified [Accessory](/docs/reference/engine/classes/Accessory.md) to the humanoid's
parent.

When this method is called, an [Accessory](/docs/reference/engine/classes/Accessory.md) is attached to the
character by searching for an [Attachment](/docs/reference/engine/classes/Attachment.md) in the humanoid's parent
that shares the same name as an [Attachment](/docs/reference/engine/classes/Attachment.md) in the accessory's
**Handle** [Part](/docs/reference/engine/classes/Part.md). If one is found, the **Handle** part will be
connected to the parent of the [Attachment](/docs/reference/engine/classes/Attachment.md) using a [Weld](/docs/reference/engine/classes/Weld.md),
and the weld will be configured so the [Attachments](/docs/reference/engine/classes/Attachment.md)
occupy the same space.

If the required [Attachment](/docs/reference/engine/classes/Attachment.md) can not be found, then the
[Accessory](/docs/reference/engine/classes/Accessory.md) will remain parented to the humanoid's parent but it
will be unattached.

Typically, accessory welds are created on the server, but they can be
created on the client under certain circumstances. In these situations,
client-sided calls to [AddAccessory()](/docs/reference/engine/classes/Humanoid.md) may
not always produce the desired behavior and you can use
[BuildRigFromAttachments()](/docs/reference/engine/classes/Humanoid.md) to
force the expected weld creation.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarAppearance*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `accessory` | `Instance` |  | The [Accessory](/docs/reference/engine/classes/Accessory.md) to be attached. |

**Returns:** `()`

**[Humanoid] AddAccessory Example**

This script generates the "Clockwork's Shades" Accessory from scratch, and
then attaches it to the player's character using `Humanoid.AddAccessory` You
should paste this code into a regular script, and then parent it inside of the
`StarterPlayer`'s `StarterCharacterScripts` folder.

```lua
local playerModel = script.Parent
local humanoid = playerModel:WaitForChild("Humanoid")

local clockworksShades = Instance.new("Accessory")
clockworksShades.Name = "ClockworksShades"

local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(1, 1.6, 1)
handle.Parent = clockworksShades

local faceFrontAttachment = Instance.new("Attachment")
faceFrontAttachment.Name = "FaceFrontAttachment"
faceFrontAttachment.Position = Vector3.new(0, -0.24, -0.45)
faceFrontAttachment.Parent = handle

local mesh = Instance.new("SpecialMesh")
mesh.Name = "Mesh"
mesh.Scale = Vector3.new(1, 1.3, 1)
mesh.MeshId = "rbxassetid://1577360"
mesh.TextureId = "rbxassetid://1577349"
mesh.Parent = handle

humanoid:AddAccessory(clockworksShades)
```

### Method: Humanoid:ApplyDescriptionAsync

**Signature:** `Humanoid:ApplyDescriptionAsync(humanoidDescription: HumanoidDescription, assetTypeVerification?: AssetTypeVerification): ()`

This yielding method makes the character's look match that of the passed
in [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md). A copy of the passed
[HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) is cached as the [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md)
for the [Humanoid](/docs/reference/engine/classes/Humanoid.md).

This method is optimized through making the assumption that only this
method is used to change the appearance of the character, and no changes
are made through other means between calls. If changes are made to the
character between calls, then this method may not make the character
reflect the passed in [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) accurately. If you want
to use this method in conjunction with other means of updating the
character, [Humanoid:ApplyDescriptionResetAsync()](/docs/reference/engine/classes/Humanoid.md) will always
ensure the character reflects the passed in [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md).

#### See Also

- [Humanoid:GetAppliedDescription()](/docs/reference/engine/classes/Humanoid.md) which returns the
  [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) currently applied to the humanoid.
- [Players:GetHumanoidDescriptionFromUserIdAsync()](/docs/reference/engine/classes/Players.md) which returns a
  [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) describing the avatar for the passed in
  user.
- [Players:GetHumanoidDescriptionFromOutfitIdAsync()](/docs/reference/engine/classes/Players.md) which returns
  a [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) whose parameters are initialized to match
  that of the passed in server-side outfit asset.
- [Player:LoadCharacterWithHumanoidDescriptionAsync()](/docs/reference/engine/classes/Player.md) which spawns
  a player with the look from the passed in [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md).

*Yields · Security: None · Thread Safety: Unsafe · Capabilities: AvatarAppearance*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `humanoidDescription` | `HumanoidDescription` |  | The [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) instance which you want to set the character to match. |
| `assetTypeVerification` | `AssetTypeVerification` | `Default` | The asset type verification mode. |

**Returns:** `()`

### Method: Humanoid:ApplyDescriptionResetAsync

**Signature:** `Humanoid:ApplyDescriptionResetAsync(humanoidDescription: HumanoidDescription, assetTypeVerification?: AssetTypeVerification): ()`

This yielding method makes the character's look match that of the passed
in [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md), even after external changes. A copy of the
passed [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) is cached as the
[HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) for the [Humanoid](/docs/reference/engine/classes/Humanoid.md).

This method will always ensure the character reflects the passed in
[HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md), even if changes have been made to the
character not using the [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) system (for example
not using
[ApplyDescriptionResetAsync()](/docs/reference/engine/classes/Humanoid.md)
or [ApplyDescriptionAsync()](/docs/reference/engine/classes/Humanoid.md)). This
is in contrast to
[ApplyDescriptionAsync()](/docs/reference/engine/classes/Humanoid.md) which is
optimized and may incorrectly apply a [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) if the
character has been changed by means other than through the
[HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) system.

*Yields · Security: None · Thread Safety: Unsafe · Capabilities: AvatarAppearance*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `humanoidDescription` | `HumanoidDescription` |  | The [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) instance which you want to set the character to match. |
| `assetTypeVerification` | `AssetTypeVerification` | `Default` | The asset type verification mode. |

**Returns:** `()`

### Method: Humanoid:BuildRigFromAttachments

**Signature:** `Humanoid:BuildRigFromAttachments(): ()`

This method assembles a tree of [Motor6D](/docs/reference/engine/classes/Motor6D.md) joints for the
[Humanoid](/docs/reference/engine/classes/Humanoid.md). [Motor6D](/docs/reference/engine/classes/Motor6D.md) joints are required for the playback of
[Animations](/docs/reference/engine/classes/Animation.md).

Starting from the humanoid's [RootPart](/docs/reference/engine/classes/Humanoid.md), this
method collects all [Attachments](/docs/reference/engine/classes/Attachment.md) parented in the current
part whose name ends with **RigAttachment**. It then searches for a
matching attachment in the character that shares the same name as the
attachment. Using those two attachments, a [Motor6D](/docs/reference/engine/classes/Motor6D.md) joint is
generated based on the parts associated with the two attachments and the
[CFrame](/docs/reference/engine/classes/Attachment.md) of the attachments.

[Humanoid:BuildRigFromAttachments()](/docs/reference/engine/classes/Humanoid.md) also scales the character and
sets body colors.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Returns:** `()`

**Lua Port of BuildRigFromAttachments**

A Lua port of the Humanoid's BuildRigFromAttachments function
(AvatarJointUpgrade path).

```lua
local function createJoint(jointName, att0, att1)
	local partForJoint = att1.Parent
	while partForJoint and not partForJoint:IsA("BasePart") do
		partForJoint = partForJoint.Parent
	end

	local oldJoint = partForJoint:FindFirstChild(jointName)
	if oldJoint and oldJoint:IsA("AnimationConstraint") then
		oldJoint.Attachment0 = att0
		oldJoint.Attachment1 = att1
		oldJoint.Parent = partForJoint
	else
		local ac = Instance.new("AnimationConstraint")
		ac.Name = jointName
		ac.IsKinematic = true
		ac.Attachment0 = att0
		ac.Attachment1 = att1
		ac.Parent = partForJoint
	end
end

local function collectRigAttachments(part)
	local rigAttachments = {}

	for _, child in pairs(part:GetChildren()) do
		if child:IsA("Attachment") and child.Name:find("RigAttachment$") then
			rigAttachments[child.Name] = child
		end
	end

	-- Bones may contain deeper RigAttachments that override the part-level
	-- ones (R15+ extended skeleton).
	for _, child in pairs(part:GetChildren()) do
		if child:IsA("Bone") then
			for _, descendant in pairs(child:GetDescendants()) do
				if descendant:IsA("Attachment") and descendant.Name:find("RigAttachment$") then
					rigAttachments[descendant.Name] = descendant
				end
			end
		end
	end

	return rigAttachments
end

local function buildJointsFromAttachments(part, characterParts, visitedParts)
	if not part or visitedParts[part] then
		return
	end

	visitedParts[part] = true

	local rigAttachments = collectRigAttachments(part)

	for attachmentName, attachment in pairs(rigAttachments) do
		local jointName = attachmentName:sub(1, #attachmentName - #"RigAttachment")
		if not part:FindFirstChild(jointName) then
			for _, characterPart in pairs(characterParts) do
				if not visitedParts[characterPart] then
					local matchingAttachment = characterPart:FindFirstChild(attachmentName)
					if matchingAttachment and matchingAttachment:IsA("Attachment") then
						createJoint(jointName, attachment, matchingAttachment)
						buildJointsFromAttachments(characterPart, characterParts, visitedParts)
						break
					end
				end
			end
		end
	end
end

local function buildRigFromAttachments(humanoid)
	local rootPart = humanoid.RootPart
	assert(rootPart, "Humanoid has no HumanoidRootPart.")

	local characterParts = {}
	for _, descendant in ipairs(humanoid.Parent:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(characterParts, descendant)
		end
	end

	local visitedParts = {}
	buildJointsFromAttachments(rootPart, characterParts, visitedParts)
end

local humanoid = script.Parent:WaitForChild("Humanoid")

buildRigFromAttachments(humanoid)
```

**R15 Package Importer**

A script that generates an R15 character from scratch using a package's
assetId.

```lua
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")

local PACKAGE_ASSET_ID = 193700907 -- Circuit Breaker

local function addAttachment(part, name, position, orientation)
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Parent = part
	if position then
		attachment.Position = position
	end
	if orientation then
		attachment.Orientation = orientation
	end
	return attachment
end

local function createBaseCharacter()
	local character = Instance.new("Model")

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.Parent = character
	addAttachment(rootPart, "RootRigAttachment")

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Parent = character

	local headMesh = Instance.new("SpecialMesh")
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Parent = head

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Parent = head

	addAttachment(head, "FaceCenterAttachment")
	addAttachment(head, "FaceFrontAttachment", Vector3.new(0, 0, -0.6))
	addAttachment(head, "HairAttachment", Vector3.new(0, 0.6, 0))
	addAttachment(head, "HatAttachment", Vector3.new(0, 0.6, 0))
	addAttachment(head, "NeckRigAttachment", Vector3.new(0, -0.5, 0))

	return character, humanoid
end

local function createR15Package(packageAssetId)
	local packageAssetInfo = MarketplaceService:GetProductInfoAsync(packageAssetId)

	local character, humanoid = createBaseCharacter()
	character.Name = packageAssetInfo.Name

	local assetIds = AssetService:GetAssetIdsForPackageAsync(packageAssetId)
	for _, assetId in pairs(assetIds) do
		local limb = InsertService:LoadAsset(assetId)
		local r15 = limb:FindFirstChild("R15")
		if r15 then
			for _, part in pairs(r15:GetChildren()) do
				part.Parent = character
			end
		else
			for _, child in pairs(limb:GetChildren()) do
				child.Parent = character
			end
		end
	end

	humanoid:BuildRigFromAttachments()
	return character
end

local r15Package = createR15Package(PACKAGE_ASSET_ID)
r15Package.Parent = workspace
```

### Method: Humanoid:ChangeState

**Signature:** `Humanoid:ChangeState(state?: HumanoidStateType): ()`

This method causes the [Humanoid](/docs/reference/engine/classes/Humanoid.md) to enter the given
[HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md), describing the activity the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is
currently doing.

Please review the [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) page for more information on
the particular states, as some have unintuitive names. For example,
[HumanoidStateType.Running](/docs/reference/engine/enums/HumanoidStateType.md) describes a state where the humanoid's
legs are on the ground, including when stationary.

Due to the default behavior of the [Humanoid](/docs/reference/engine/classes/Humanoid.md), some states will
automatically be changed when set. For example:

- Setting the state to [HumanoidStateType.Swimming](/docs/reference/engine/enums/HumanoidStateType.md) when the humanoid
  is not in the water will cause it to be automatically set to
  [HumanoidStateType.GettingUp](/docs/reference/engine/enums/HumanoidStateType.md).
- As it is unused, setting the state to
  [HumanoidStateType.PlatformStanding](/docs/reference/engine/enums/HumanoidStateType.md) will cause the humanoid state
  to be automatically set to [HumanoidStateType.Running](/docs/reference/engine/enums/HumanoidStateType.md).

Note that in order to set the [Humanoid](/docs/reference/engine/classes/Humanoid.md) state using this method,
you must do so from a [LocalScript](/docs/reference/engine/classes/LocalScript.md) and the client must have
[network ownership](/docs/en-us/physics/network-ownership.md) of the
[Player.Character](/docs/reference/engine/classes/Player.md). Alternatively, you can call this method from a
server-side [Script](/docs/reference/engine/classes/Script.md), but the server must have network ownership of
the player character.

See also [Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md) to enable or disable a
particular state, and [Humanoid:GetState()](/docs/reference/engine/classes/Humanoid.md) to get the current
humanoid state.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior · Simulation Access: true*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `state` | `HumanoidStateType` | `None` | The [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) that the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is to perform. |

**Returns:** `()`

**Double Jump**

This code, when placed inside a [LocalScript](/docs/reference/engine/classes/LocalScript.md) in
[StarterPlayer.StarterCharacterScripts](/docs/reference/engine/classes/StarterPlayer.md), will allow the player's
character to perform a double jump.

```lua
local UserInputService = game:GetService("UserInputService")
local character = script.Parent

local humanoid = character:WaitForChild("Humanoid")

local doubleJumpEnabled = false

humanoid.StateChanged:Connect(function(_oldState, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		if not doubleJumpEnabled then
			task.wait(0.2)
			if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				doubleJumpEnabled = true
			end
		end
	elseif newState == Enum.HumanoidStateType.Landed then
		doubleJumpEnabled = false
	end
end)

UserInputService.InputBegan:Connect(function(inputObject)
	if inputObject.KeyCode == Enum.KeyCode.Space then
		if doubleJumpEnabled then
			if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				task.spawn(function()
					doubleJumpEnabled = false
				end)
			end
		end
	end
end)
```

### Method: Humanoid:EquipTool

**Signature:** `Humanoid:EquipTool(tool: Instance): ()`

This method makes the [Humanoid](/docs/reference/engine/classes/Humanoid.md) equip the given [Tool](/docs/reference/engine/classes/Tool.md).

When this method is called, the [Humanoid](/docs/reference/engine/classes/Humanoid.md) will first automatically
unequip all [Tools](/docs/reference/engine/classes/Tool.md) that it currently has equipped.

Although they will be equipped, [Tools](/docs/reference/engine/classes/Tool.md) for which
[Tool.RequiresHandle](/docs/reference/engine/classes/Tool.md) is `true` will not function if they have no
handle, regardless if this method is used to equip them or not.

See also [Humanoid:UnequipTools()](/docs/reference/engine/classes/Humanoid.md).

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tool` | `Instance` |  | The [Tool](/docs/reference/engine/classes/Tool.md) to equip. |

**Returns:** `()`

### Method: Humanoid:GetAccessories

**Signature:** `Humanoid:GetAccessories(): Array`

This method returns an array of [Accessory](/docs/reference/engine/classes/Accessory.md) objects that the
humanoid's parent is currently wearing. All such [Accessory](/docs/reference/engine/classes/Accessory.md) objects
will be included, regardless of whether they're attached or not.

If the [Humanoid](/docs/reference/engine/classes/Humanoid.md) has no [Accessory](/docs/reference/engine/classes/Accessory.md) objects, an empty array
will be returned.

See also [Humanoid:AddAccessory()](/docs/reference/engine/classes/Humanoid.md) to attach an [Accessory](/docs/reference/engine/classes/Accessory.md) to
a humanoid's parent.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarAppearance*

**Returns:** `Array` — An array of [Accessory](/docs/reference/engine/classes/Accessory.md) objects that are parented to the
humanoid's parent.

**Remove Accessories After Loading**

This code sample will wait for accessories to fully load, print out how many
there are, and then destroy them all.

```lua
local Players = game:GetService("Players")

local function onPlayerAddedAsync(player)
	local connection = player.CharacterAppearanceLoaded:Connect(function(character)
		-- All accessories have loaded at this point
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local numAccessories = #humanoid:GetAccessories()
		print(("Destroying %d accessories for %s"):format(numAccessories, player.Name))
		humanoid:RemoveAccessories()
	end)

	-- Make sure we disconnect our connection to the player after they leave
	-- to allow the player to get garbage collected
	player.AncestryChanged:Wait()
	connection:Disconnect()
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAddedAsync, player)
end
Players.PlayerAdded:Connect(onPlayerAddedAsync)
```

### Method: Humanoid:GetAppliedDescription

**Signature:** `Humanoid:GetAppliedDescription(): HumanoidDescription`

This method returns a copy of the humanoid's cached
[HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) which describes its current look. This can be
used to quickly determine a character's look and to assign their look to
other characters using the [Humanoid:ApplyDescriptionAsync()](/docs/reference/engine/classes/Humanoid.md)
method.

#### See Also

- [Players:GetHumanoidDescriptionFromUserIdAsync()](/docs/reference/engine/classes/Players.md) which returns a
  [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) describing the avatar for the passed in
  user.
- [Players:GetHumanoidDescriptionFromOutfitIdAsync()](/docs/reference/engine/classes/Players.md) which returns
  a [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) whose parameters are initialized to match
  that of the passed in server-side outfit asset.
- [Player:LoadCharacterWithHumanoidDescriptionAsync()](/docs/reference/engine/classes/Player.md) which spawns
  a player with the look from the passed in [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md).

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarAppearance*

**Returns:** `HumanoidDescription`

### Method: Humanoid:GetBodyPartR15

**Signature:** `Humanoid:GetBodyPartR15(part: Instance): BodyPartR15`

This method returns what [BodyPartR15](/docs/reference/engine/enums/BodyPartR15.md) a [Part](/docs/reference/engine/classes/Part.md) is, or
[BodyPartR15.Unknown](/docs/reference/engine/enums/BodyPartR15.md) if the part is not an R15 body part. This
method allows developers to retrieve player body parts independent of what
the actual body part names are, instead returning an enum.

It can be used in conjunction with [Humanoid:ReplaceBodyPartR15()](/docs/reference/engine/classes/Humanoid.md).
For example, if a player's body part touches something, this function will
return get a part instance. Developers can then look up what part of the
body that was, like head or arm. Then depending on what that part was,
developers can either perform some gameplay action or replace that part
with some other part - perhaps showing damage.

This method can be useful for games where hit location is important. For
example, it can be used to determine if a player is hit in the leg and
then slow them down based on the injury.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `part` | `Instance` |  | The specified part being checked to see if it is an R15 body part. |

**Returns:** `BodyPartR15` — The specified part's R15 body part type or unknown if the part is not
a body part.

### Method: Humanoid:GetLimb

**Signature:** `Humanoid:GetLimb(part: Instance): Limb`

This method returns the [Limb](/docs/reference/engine/enums/Limb.md) enum that is associated with the given
[Part](/docs/reference/engine/classes/Part.md). It works for both R15 and R6 rigs, for example:

```lua
-- For R15
print(humanoid:GetLimb(character.LeftUpperLeg))  -- Enum.Limb.LeftLeg
print(humanoid:GetLimb(character.LeftLowerLeg))  -- Enum.Limb.LeftLeg
print(humanoid:GetLimb(character.LeftFoot))  -- Enum.Limb.LeftLeg

-- For R6
print(humanoid:GetLimb(character:FindFirstChild("Left Leg")))  -- Enum.Limb.LeftLeg
```

Note that [Humanoid:GetLimb()](/docs/reference/engine/classes/Humanoid.md) will throw an error if the part's
parent is not set to the humanoid's parent.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `part` | `Instance` |  | The [Part](/docs/reference/engine/classes/Part.md) for which the [Enum.Limb](/docs/reference/engine/enums/Limb.md) is to be retrieved. |

**Returns:** `Limb` — The [Limb](/docs/reference/engine/enums/Limb.md) the part corresponds with.

**Getting a Humanoid's Limbs**

Put this in a LocalScript. The output will vary based on if the humanoid is R6
or R15.

```lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

for _, child in pairs(character:GetChildren()) do
	local limb = humanoid:GetLimb(child)
	if limb ~= Enum.Limb.Unknown then
		print(child.Name .. " is part of limb " .. limb.Name)
	end
end
```

### Method: Humanoid:GetMoveVelocity

**Signature:** `Humanoid:GetMoveVelocity(): Vector3`

Returns the Humanoid's intended movement velocity as a [Vector3](/docs/reference/engine/datatypes/Vector3.md).
The result is the product of [WalkSpeed](/docs/reference/engine/classes/Humanoid.md), the
intended movement direction, and the current percent walk speed. If the
Humanoid is not moving, this returns `(0, 0, 0)`.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Returns:** `Vector3` — A [Vector3](/docs/reference/engine/datatypes/Vector3.md) representing the Humanoid's intended movement
velocity in world space.

### Method: Humanoid:GetRelativeVelocityAtFloor

**Signature:** `Humanoid:GetRelativeVelocityAtFloor(): Vector3`

Returns the humanoid's actual physical velocity relative to the surface it
is standing on as a [Vector3](/docs/reference/engine/datatypes/Vector3.md) in world-space orientation. This
accounts for moving platforms by subtracting floor velocity from the
humanoid's body velocity.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior · Simulation Access: true*

**Returns:** `Vector3`

### Method: Humanoid:GetState

**Signature:** `Humanoid:GetState(): HumanoidStateType`

This method returns the humanoid's current [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md),
describing the activity the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is currently doing, such as
jumping or swimming.

See also [Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md) to enable or disable a
particular state, and [Humanoid:ChangeState()](/docs/reference/engine/classes/Humanoid.md) to change the current
humanoid state.

*Security: None · Thread Safety: Safe · Capabilities: AvatarBehavior · Simulation Access: true*

**Returns:** `HumanoidStateType` — The current [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) of the [Humanoid](/docs/reference/engine/classes/Humanoid.md).

**Double Jump**

This code, when placed inside a [LocalScript](/docs/reference/engine/classes/LocalScript.md) in
[StarterPlayer.StarterCharacterScripts](/docs/reference/engine/classes/StarterPlayer.md), will allow the player's
character to perform a double jump.

```lua
local UserInputService = game:GetService("UserInputService")
local character = script.Parent

local humanoid = character:WaitForChild("Humanoid")

local doubleJumpEnabled = false

humanoid.StateChanged:Connect(function(_oldState, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		if not doubleJumpEnabled then
			task.wait(0.2)
			if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				doubleJumpEnabled = true
			end
		end
	elseif newState == Enum.HumanoidStateType.Landed then
		doubleJumpEnabled = false
	end
end)

UserInputService.InputBegan:Connect(function(inputObject)
	if inputObject.KeyCode == Enum.KeyCode.Space then
		if doubleJumpEnabled then
			if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				task.spawn(function()
					doubleJumpEnabled = false
				end)
			end
		end
	end
end)
```

### Method: Humanoid:GetStateEnabled

**Signature:** `Humanoid:GetStateEnabled(state: HumanoidStateType): boolean`

The GetStateEnabled method returns whether a [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) is
enabled for the [Humanoid](/docs/reference/engine/classes/Humanoid.md).

The humanoid state describes the activity the humanoid is currently doing.

When a particular [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) is disabled, the humanoid can
never enter that state. This is true regardless if the attempt to change
state is made using [Humanoid:ChangeState()](/docs/reference/engine/classes/Humanoid.md) or Roblox internal
humanoid code.

See also:

- For an event that fires when a humanoid state is enabled or disabled see
  [Humanoid.StateEnabledChanged](/docs/reference/engine/classes/Humanoid.md)
- To enable or disable a [Humanoid](/docs/reference/engine/classes/Humanoid.md) state use
  [Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md)

*Security: None · Thread Safety: Safe · Capabilities: AvatarBehavior · Simulation Access: true*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `state` | `HumanoidStateType` |  | The given [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md). |

**Returns:** `boolean` — Whether the given [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) is enabled.

**Setting and Getting Humanoid States**

The code below sets the value of the
[humanoid jumping state](/docs/reference/engine/enums/HumanoidStateType.md) to _false_ using
[Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md) and then retrieves and prints the value of
this state (_false_) using [Humanoid:GetStateEnabled()](/docs/reference/engine/classes/Humanoid.md).

```lua
local humanoid = script.Parent:WaitForChild("Humanoid")

-- Set state
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

-- Get state
print(humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)) -- false
```

### Method: Humanoid:Move

**Signature:** `Humanoid:Move(moveDirection: Vector3, relativeToCamera?: boolean): ()`

This method causes the [Humanoid](/docs/reference/engine/classes/Humanoid.md) to walk in the given
[Vector3](/docs/reference/engine/datatypes/Vector3.md) direction.

By default, the direction is in world terms, but if the `relativeToCamera`
parameter is `true`, the direction is relative to the [CFrame](/docs/reference/engine/datatypes/CFrame.md) of
the [CurrentCamera](/docs/reference/engine/classes/Workspace.md). As the negative **Z**
direction is considered "forwards" in Roblox, the following code will make
the humanoid walk in the direction of the
[CurrentCamera](/docs/reference/engine/classes/Workspace.md).

```lua
humanoid:Move(Vector3.new(0, 0, -1), true)
```

When this method is called, the [Humanoid](/docs/reference/engine/classes/Humanoid.md) will move until the
method is called again. However, this method will be overwritten in the
next frame by Roblox's default character control script. This can be
avoided by either calling this function every frame using
[RunService:BindToRenderStep()](/docs/reference/engine/classes/RunService.md) (see example), or overwriting the
control scripts in [StarterPlayerScripts](/docs/reference/engine/classes/StarterPlayerScripts.md).

This method can be called on the server, but this should only be done when
the server has [network ownership](/docs/en-us/physics/network-ownership.md)
of the humanoid's assembly.

See also [Humanoid:MoveTo()](/docs/reference/engine/classes/Humanoid.md) which makes a[Humanoid](/docs/reference/engine/classes/Humanoid.md) walk to a
point, and [Player:Move()](/docs/reference/engine/classes/Player.md) which effectively calls this function.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior · Simulation Access: true*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `moveDirection` | `Vector3` |  | The direction to walk in. |
| `relativeToCamera` | `boolean` | `false` | Set to `true` if the `moveDirection` parameter should be taken as relative to the [CurrentCamera](/docs/reference/engine/classes/Workspace.md). |

**Returns:** `()`

**Moving a Humanoid Forwards**

This code sample uses the [Humanoid:Move()](/docs/reference/engine/classes/Humanoid.md) function to make the
player's [Character](/docs/reference/engine/classes/Player.md) walk in the direction of the
[Camera](/docs/reference/engine/classes/Camera.md). [RunService:BindToRenderStep()](/docs/reference/engine/classes/RunService.md) is required here as the
default control scripts will overwrite the player's movement every frame.

To run this sample, place it inside a [LocalScript](/docs/reference/engine/classes/LocalScript.md) parented to
[StarterCharacterScripts](/docs/reference/engine/classes/StarterCharacterScripts.md).

```lua
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

RunService:BindToRenderStep("move", Enum.RenderPriority.Character.Value + 1, function()
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:Move(Vector3.new(0, 0, -1), true)
		end
	end
end)
```

### Method: Humanoid:MoveTo

**Signature:** `Humanoid:MoveTo(location: Vector3, part?: Instance): ()`

This method causes the [Humanoid](/docs/reference/engine/classes/Humanoid.md) to attempt to walk to a given
location by setting the [WalkToPoint](/docs/reference/engine/classes/Humanoid.md) and
[WalkToPart](/docs/reference/engine/classes/Humanoid.md) properties, corresponding to the
`location` and `part` parameters.

If the `part` parameter is specified, the [Humanoid](/docs/reference/engine/classes/Humanoid.md) will still
attempt to walk to the `location` parameter's point. However, if the
`part` moves, the point will move to be at the same position **relative to
the part**.

Note that the movement operation will time out after 8 seconds if the
humanoid doesn't reach its goal (this timeout exists so that humanoids do
not get stuck waiting for [MoveToFinished](/docs/reference/engine/classes/Humanoid.md)
to fire). If you don't want this to happen, call `MoveTo()` at a repeated
interval so that the timeout keeps resetting.

[MoveTo()](/docs/reference/engine/classes/Humanoid.md) ends if any of the following conditions
apply:

- The character arrives at its destination, assuming a ~1 stud threshold
  to account for various humanoid speeds and framerates.

- The character gets stuck and the timer expires.

- The value of either [WalkToPoint](/docs/reference/engine/classes/Humanoid.md) or
  [WalkToPart](/docs/reference/engine/classes/Humanoid.md) changes.

- A script calls [Move()](/docs/reference/engine/classes/Humanoid.md) with a new `moveDirection`
  parameter.

- A script changes the [CFrame](/docs/reference/engine/classes/BasePart.md) property of the
  humanoid's [RootPart](/docs/reference/engine/classes/Humanoid.md).

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior · Simulation Access: true*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `Vector3` |  | The position to set [Humanoid.WalkToPoint](/docs/reference/engine/classes/Humanoid.md) to. |
| `part` | `Instance` | `nil` | The [BasePart](/docs/reference/engine/classes/BasePart.md) to set [Humanoid.WalkToPart](/docs/reference/engine/classes/Humanoid.md) to. |

**Returns:** `()`

**Humanoid MoveTo Without Time out**

This code sample includes a function that avoids the timeout on
[Humanoid:MoveTo()](/docs/reference/engine/classes/Humanoid.md) by calling [Humanoid:MoveTo()](/docs/reference/engine/classes/Humanoid.md) again before
the timeout elapses. It also includes an optional `andThen` parameter for
which you can pass a function to be called when the humanoid reaches its
destination.

```lua
local function moveTo(humanoid, targetPoint, andThen)
	local targetReached = false

	-- listen for the humanoid reaching its target
	local connection
	connection = humanoid.MoveToFinished:Connect(function(reached)
		targetReached = true
		connection:Disconnect()
		connection = nil
		if andThen then
			andThen(reached)
		end
	end)

	-- start walking
	humanoid:MoveTo(targetPoint)

	-- execute on a new thread so as to not yield function
	task.spawn(function()
		while not targetReached do
			-- does the humanoid still exist?
			if not (humanoid and humanoid.Parent) then
				break
			end
			-- has the target changed?
			if humanoid.WalkToPoint ~= targetPoint then
				break
			end
			-- refresh the timeout
			humanoid:MoveTo(targetPoint)
			task.wait(6)
		end

		-- disconnect the connection if it is still connected
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function andThen(reached)
	print((reached and "Destination reached!") or "Failed to reach destination!")
end

moveTo(script.Parent:WaitForChild("Humanoid"), Vector3.new(50, 0, 50), andThen)
```

### Method: Humanoid:PlayEmoteAsync

**Signature:** `Humanoid:PlayEmoteAsync(emoteName: string): boolean`

If the emote could not be played because the emoteName is not found in the
HumanoidDescription, this method will give an error. The method will
return true to indicate that the emote was played successfully.

*Yields · Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `emoteName` | `string` |  | name of the emote to play. |

**Returns:** `boolean` — successfully played.

### Method: Humanoid:RemoveAccessories

**Signature:** `Humanoid:RemoveAccessories(): ()`

This method removes all [Accessory](/docs/reference/engine/classes/Accessory.md) objects worn by the humanoid's
parent. For player [Characters](/docs/reference/engine/classes/Player.md), this will remove
all hats and other accessories.

This method removes [Accessory](/docs/reference/engine/classes/Accessory.md) object by calling
[Instance:Destroy()](/docs/reference/engine/classes/Instance.md) on them, meaning the
[Parent](/docs/reference/engine/classes/Instance.md) of the accessories are set to `nil` and
locked.

See also [Humanoid:AddAccessory()](/docs/reference/engine/classes/Humanoid.md) to attach an [Accessory](/docs/reference/engine/classes/Accessory.md),
and [Humanoid:GetAccessories()](/docs/reference/engine/classes/Humanoid.md) to get all [Accessory](/docs/reference/engine/classes/Accessory.md) objects
belonging to a [Humanoid](/docs/reference/engine/classes/Humanoid.md).

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarAppearance*

**Returns:** `()`

**Remove Accessories After Loading**

This code sample will wait for accessories to fully load, print out how many
there are, and then destroy them all.

```lua
local Players = game:GetService("Players")

local function onPlayerAddedAsync(player)
	local connection = player.CharacterAppearanceLoaded:Connect(function(character)
		-- All accessories have loaded at this point
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local numAccessories = #humanoid:GetAccessories()
		print(("Destroying %d accessories for %s"):format(numAccessories, player.Name))
		humanoid:RemoveAccessories()
	end)

	-- Make sure we disconnect our connection to the player after they leave
	-- to allow the player to get garbage collected
	player.AncestryChanged:Wait()
	connection:Disconnect()
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAddedAsync, player)
end
Players.PlayerAdded:Connect(onPlayerAddedAsync)
```

### Method: Humanoid:ReplaceBodyPartR15

**Signature:** `Humanoid:ReplaceBodyPartR15(bodyPart: BodyPartR15, part: BasePart): boolean`

Dynamically replaces a R15/Rthro limb part in a Humanoid with a different
part. The part is automatically scaled as normal.

This method is useful for modifying characters during gameplay or building
characters from a base rig. The related method
[GetBodyPartR15](/docs/reference/engine/classes/Humanoid.md) can come in handy when
using this method.

The name of the part passed in should match with the name of the
BodyPartR15 Enum passed in.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarAppearance*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `bodyPart` | `BodyPartR15` |  | The body part to replace. [BodyPartR15.Unknown](/docs/reference/engine/enums/BodyPartR15.md) will fail. |
| `part` | `BasePart` |  | The [Part](/docs/reference/engine/classes/Part.md) [Instance](/docs/reference/engine/classes/Instance.md) which will be parented to the character. |

**Returns:** `boolean`

### Method: Humanoid:SetStateEnabled

**Signature:** `Humanoid:SetStateEnabled(state: HumanoidStateType, enabled: boolean): ()`

This method sets whether a given [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) is enabled for
the [Humanoid](/docs/reference/engine/classes/Humanoid.md). When a particular [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) is
disabled, the [Humanoid](/docs/reference/engine/classes/Humanoid.md) can never enter that state. This is true
regardless if the attempt to change state is made using
[Humanoid:ChangeState()](/docs/reference/engine/classes/Humanoid.md) or Roblox internal [Humanoid](/docs/reference/engine/classes/Humanoid.md) code.

Note that using `SetStateEnabled()` on the server does not replicate the
change to the client, nor vice-versa.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior · Simulation Access: true*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `state` | `HumanoidStateType` |  | The [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) to be enabled or disabled. |
| `enabled` | `boolean` |  | `true` if `state` is to be enabled, `false` if `state` is to be disabled. |

**Returns:** `()`

**Jump Cooldown**

The following sample will require a one second cooldown after a `Humanoid` has
landed before it is able to jump again.

To try this sample, place it inside a `LocalScript` in
`StarterCharacterScripts|StarterPlayer.StarterCharacterScripts`.

```lua
local character = script.Parent

local JUMP_DEBOUNCE = 1

local humanoid = character:WaitForChild("Humanoid")

local isJumping = false
humanoid.StateChanged:Connect(function(_oldState, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		if not isJumping then
			isJumping = true
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		end
	elseif newState == Enum.HumanoidStateType.Landed then
		if isJumping then
			isJumping = false
			task.wait(JUMP_DEBOUNCE)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end
end)
```

### Method: Humanoid:TakeDamage

**Signature:** `Humanoid:TakeDamage(amount: float): ()`

This method lowers the [Humanoid.Health](/docs/reference/engine/classes/Humanoid.md) of the [Humanoid](/docs/reference/engine/classes/Humanoid.md) by
the given _amount_ if it is not protected by a [ForceField](/docs/reference/engine/classes/ForceField.md)

This method accepts negative values for the _amount_ parameter. This will
increase the humanoid's [Humanoid.Health](/docs/reference/engine/classes/Humanoid.md). However this will only
have an effect if no [ForceField](/docs/reference/engine/classes/ForceField.md) is present.

#### How do ForceFields protect against TakeDamage

A [Humanoid](/docs/reference/engine/classes/Humanoid.md) is considered protected by a [ForceField](/docs/reference/engine/classes/ForceField.md) if a
[ForceField](/docs/reference/engine/classes/ForceField.md) meets one of the following criteria:

- The [ForceField](/docs/reference/engine/classes/ForceField.md) shares the same [Instance.Parent](/docs/reference/engine/classes/Instance.md) as the
  [Humanoid](/docs/reference/engine/classes/Humanoid.md)
- The [ForceField](/docs/reference/engine/classes/ForceField.md) is parented to the [Humanoid.RootPart](/docs/reference/engine/classes/Humanoid.md) of
  the [Humanoid](/docs/reference/engine/classes/Humanoid.md)
- The [ForceField](/docs/reference/engine/classes/ForceField.md) is parented to an ancestor of the
  [Humanoid](/docs/reference/engine/classes/Humanoid.md) other than the [Workspace](/docs/reference/engine/classes/Workspace.md)

To do damage to a [Humanoid](/docs/reference/engine/classes/Humanoid.md) irrespective of any
[ForceFields](/docs/reference/engine/classes/ForceField.md) present, set [Humanoid.Health](/docs/reference/engine/classes/Humanoid.md)
directly.

For more information on how [ForceFields](/docs/reference/engine/classes/ForceField.md) protect
[Humanoids](/docs/reference/engine/classes/Humanoid.md) see the [ForceField](/docs/reference/engine/classes/ForceField.md) page.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `amount` | `float` |  | The damage, or amount to be deduced from the [Humanoid.Health](/docs/reference/engine/classes/Humanoid.md). |

**Returns:** `()`

**Damaging a Humanoid**

This code, put in a `LocalScript`, would make the local player take 99 damage
_only_ if a ForceField wasn't present.

```lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

humanoid:TakeDamage(99)
```

### Method: Humanoid:UnequipTools

**Signature:** `Humanoid:UnequipTools(): ()`

This method unequips any [Tool](/docs/reference/engine/classes/Tool.md) currently equipped by the
[Humanoid](/docs/reference/engine/classes/Humanoid.md). The unequipped [Tool](/docs/reference/engine/classes/Tool.md) will be parented to the
[Backpack](/docs/reference/engine/classes/Backpack.md) of the [Player](/docs/reference/engine/classes/Player.md) associated with the
[Humanoid](/docs/reference/engine/classes/Humanoid.md).

If no [Tool](/docs/reference/engine/classes/Tool.md) is equipped, this method will do nothing.

Although [Tools](/docs/reference/engine/classes/Tool.md) can be equipped by NPCs, this method only
works on [Humanoids](/docs/reference/engine/classes/Humanoid.md) with a corresponding [Player](/docs/reference/engine/classes/Player.md),
as a [Backpack](/docs/reference/engine/classes/Backpack.md) object is required to parent the unequipped
[Tool](/docs/reference/engine/classes/Tool.md) to.

See also [Humanoid:EquipTool()](/docs/reference/engine/classes/Humanoid.md).

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Returns:** `()`

### Method: Humanoid:AddCustomStatus

**Signature:** `Humanoid:AddCustomStatus(status: string): boolean`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

Adds a BoolValue to the Humanoid's _Status_ object, whose name is equal to
the string passed as the _status_ argument. If the status already exists,
a new BoolValue will not be created.

*Security: None · Thread Safety: Unsafe*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `status` | `string` |  |  |

**Returns:** `boolean`

### Method: Humanoid:AddStatus

**Signature:** `Humanoid:AddStatus(status?: Status): boolean`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

Adds a BoolValue to the Humanoid's _Status_ object, whose name is equal to
the name of the _Status_ enum passed as the _status_ argument. If the
status already exists, a new BoolValue will not be created.

*Security: None · Thread Safety: Unsafe*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `status` | `Status` | `Poison` |  |

**Returns:** `boolean`

### Method: Humanoid:ApplyDescription

**Signature:** `Humanoid:ApplyDescription(humanoidDescription: HumanoidDescription, assetTypeVerification?: AssetTypeVerification): ()`

> **Deprecated:** This method has been superseded by [ApplyDescriptionAsync()](/docs/reference/engine/classes/Humanoid.md).

Makes the character's look match that of the passed in
[HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md).

*Yields · Security: None · Thread Safety: Unsafe · Capabilities: AvatarAppearance*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `humanoidDescription` | `HumanoidDescription` |  | The [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) instance which you want to set the character to match. |
| `assetTypeVerification` | `AssetTypeVerification` | `Default` | The asset type verification mode. |

**Returns:** `()`

### Method: Humanoid:ApplyDescriptionReset

**Signature:** `Humanoid:ApplyDescriptionReset(humanoidDescription: HumanoidDescription, assetTypeVerification?: AssetTypeVerification): ()`

> **Deprecated:** This method has been superseded by [ApplyDescriptionResetAsync()](/docs/reference/engine/classes/Humanoid.md).

Makes the character's look match that of the passed in
[HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md), even after external changes.

*Yields · Security: None · Thread Safety: Unsafe · Capabilities: AvatarAppearance*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `humanoidDescription` | `HumanoidDescription` |  | The [HumanoidDescription](/docs/reference/engine/classes/HumanoidDescription.md) instance which you want to set the character to match. |
| `assetTypeVerification` | `AssetTypeVerification` | `Default` | The asset type verification mode. |

**Returns:** `()`

### Method: Humanoid:GetPlayingAnimationTracks

**Signature:** `Humanoid:GetPlayingAnimationTracks(): Array`

This method returns an array of all [AnimationTracks](/docs/reference/engine/classes/AnimationTrack.md)
that are currently being played on the [Humanoid](/docs/reference/engine/classes/Humanoid.md). A typical use for
this method is stopping currently playing tracks using
[AnimationTrack:Stop()](/docs/reference/engine/classes/AnimationTrack.md).

Beware that this method will not return
[AnimationTracks](/docs/reference/engine/classes/AnimationTrack.md) that have loaded but are **not
playing**. If you want to track these you will need to index them
manually.

*Security: None · Thread Safety: Unsafe · Capabilities: Animation*

**Returns:** `Array` — An array of currently playing [AnimationTracks](/docs/reference/engine/classes/AnimationTrack.md).

### Method: Humanoid:GetStatuses

**Signature:** `Humanoid:GetStatuses(): Array`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

The GetStatuses method returns a table of the Humanoid's statuses, and
custom statuses.

*Security: None · Thread Safety: Unsafe*

**Returns:** `Array`

### Method: Humanoid:HasCustomStatus

**Signature:** `Humanoid:HasCustomStatus(status: string): boolean`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

The HasCustomStatus method returns boolean based on if custom statuses
exist.

*Security: None · Thread Safety: Unsafe*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `status` | `string` |  |  |

**Returns:** `boolean`

### Method: Humanoid:HasStatus

**Signature:** `Humanoid:HasStatus(status?: Status): boolean`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

The HasStatus method returns a boolean based on if a status exists.

*Security: None · Thread Safety: Unsafe*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `status` | `Status` | `Poison` |  |

**Returns:** `boolean`

### Method: Humanoid:LoadAnimation

**Signature:** `Humanoid:LoadAnimation(animation: Animation): AnimationTrack`

> **Deprecated:** This function is deprecated in favor of using [Animator:LoadAnimation()](/docs/reference/engine/classes/Animator.md) directly (the [Animator](/docs/reference/engine/classes/Animator.md) may be created while editing or at runtime).

This method loads an [Animation](/docs/reference/engine/classes/Animation.md) onto a [Humanoid](/docs/reference/engine/classes/Humanoid.md), returning
an [AnimationTrack](/docs/reference/engine/classes/AnimationTrack.md) that can be used for playback.

*Security: None · Thread Safety: Unsafe · Capabilities: Animation · Simulation Access: true*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `animation` | `Animation` |  | The [Animation](/docs/reference/engine/classes/Animation.md) to load. |

**Returns:** `AnimationTrack`

### Method: Humanoid:loadAnimation

**Signature:** `Humanoid:loadAnimation(animation: Animation): AnimationTrack`

> **Deprecated:** This deprecated method is a variant of [Humanoid:LoadAnimation()](/docs/reference/engine/classes/Humanoid.md). [Animator:LoadAnimation()](/docs/reference/engine/classes/Animator.md) should be used instead.

*Security: None · Thread Safety: Unsafe · Capabilities: Animation · Simulation Access: true*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `animation` | `Animation` |  |  |

**Returns:** `AnimationTrack`

### Method: Humanoid:PlayEmote

**Signature:** `Humanoid:PlayEmote(emoteName: string): boolean`

> **Deprecated:** This method has been superseded by [PlayEmoteAsync()](/docs/reference/engine/classes/Humanoid.md).

Plays emotes and returns if was successfully ran.

*Yields · Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `emoteName` | `string` |  | name of the emote to play. |

**Returns:** `boolean` — successfully played.

### Method: Humanoid:RemoveCustomStatus

**Signature:** `Humanoid:RemoveCustomStatus(status: string): boolean`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

The RemoveCustomStatus method removes the defined custom status from the
Status model in the Humanoid..

*Security: None · Thread Safety: Unsafe*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `status` | `string` |  |  |

**Returns:** `boolean`

### Method: Humanoid:RemoveStatus

**Signature:** `Humanoid:RemoveStatus(status?: Status): boolean`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

The RemoveStatus method removes the defined status from the Status model
in the Humanoid.

*Security: None · Thread Safety: Unsafe*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `status` | `Status` | `Poison` |  |

**Returns:** `boolean`

### Method: Humanoid:takeDamage

**Signature:** `Humanoid:takeDamage(amount: float): ()`

> **Deprecated:** This deprecated method is a variant of [Humanoid:TakeDamage()](/docs/reference/engine/classes/Humanoid.md), which should be used instead.

*Security: None · Thread Safety: Unsafe · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `amount` | `float` |  |  |

**Returns:** `()`

## Events

### Event: Humanoid.ApplyDescriptionFinished

**Signature:** `Humanoid.ApplyDescriptionFinished(description: HumanoidDescription)`

*Security: None · Capabilities: AvatarAppearance*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `description` | `HumanoidDescription` |  |

### Event: Humanoid.Climbing

**Signature:** `Humanoid.Climbing(speed: float)`

Fires when the speed at which a [Humanoid](/docs/reference/engine/classes/Humanoid.md) is climbing changes.

[Humanoids](/docs/reference/engine/classes/Humanoid.md) can climb up ladders made out of
[Parts](/docs/reference/engine/classes/BasePart.md) or [TrussParts](/docs/reference/engine/classes/TrussPart.md).

[Humanoids](/docs/reference/engine/classes/Humanoid.md) climb at 70% of their
[Humanoid.WalkSpeed](/docs/reference/engine/classes/Humanoid.md).

This event will not always fire with a speed of 0 when the
[Humanoid](/docs/reference/engine/classes/Humanoid.md) stops climbing.

See also:

- For swimming and running see the [Humanoid.Swimming](/docs/reference/engine/classes/Humanoid.md) and
  [Humanoid.Running](/docs/reference/engine/classes/Humanoid.md) events
- You can also detect when a [Humanoid](/docs/reference/engine/classes/Humanoid.md) is climbing using the
  [Humanoid.StateChanged](/docs/reference/engine/classes/Humanoid.md) event
- You can disable climbing using the [Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md)
  function

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `speed` | `float` | The speed at which the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is currently climbing. |

**Humanoid.Climbing**

```lua
local Players = game:GetService("Players")

local function onCharacterClimbing(character, speed)
	print(character.Name, "is climbing at a speed of", speed, "studs / second.")
end

local function onCharacterAdded(character)
	character.Humanoid.Climbing:Connect(function(speed)
		onCharacterClimbing(character, speed)
	end)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(onPlayerAdded)
```

### Event: Humanoid.Died

**Signature:** `Humanoid.Died()`

This event fires when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) dies, usually when
[Humanoid.Health](/docs/reference/engine/classes/Humanoid.md) reaches 0. This could be caused either by
disconnecting their head from their [Humanoid.Torso](/docs/reference/engine/classes/Humanoid.md), or directly
setting the health property.

This event only fires if the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is a descendant of the
[Workspace](/docs/reference/engine/classes/Workspace.md). If the `Dead` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) is disabled it
will not fire.

*Security: None · Capabilities: AvatarBehavior*

**Humanoid.Died**

The code below would print the player's name, followed by "has died!",
whenever a player dies. For example, if the player was named "Shedletsky",
"Shedletsky has died!" would be printed to the output when they died.

```lua
local Players = game:GetService("Players")

local function onPlayerAdded(player)
	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid")

		local function onDied()
			print(player.Name, "has died!")
		end

		humanoid.Died:Connect(onDied)
	end

	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(onPlayerAdded)
```

### Event: Humanoid.FallingDown

**Signature:** `Humanoid.FallingDown(active: boolean)`

The FallingDown event fires when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) enters and leaves
the `FallingDown` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md).

The [Humanoid](/docs/reference/engine/classes/Humanoid.md) will enter the `GettingUp` state 3 seconds after the
`FallingDown` state is enabled. When this happens this event will fire
with an _active_ value of _false_, and [Humanoid.GettingUp](/docs/reference/engine/classes/Humanoid.md) will
fire with an _active_ value of _true_.

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `active` | `boolean` | Describes whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is entering or leaving the `FallingDown` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md). |

### Event: Humanoid.FreeFalling

**Signature:** `Humanoid.FreeFalling(active: boolean)`

This event fires when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) enters or leaves the `Freefall`
[HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md).

The _active_ parameter represents whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is entering
or leaving the `Freefall` state.

Although the `Freefall` state generally ends when the [Humanoid](/docs/reference/engine/classes/Humanoid.md)
reaches the ground, this event may fire with _active_ equal to _false_ if
the state is changed while the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is falling. For this
reason, you should use [Humanoid.StateChanged](/docs/reference/engine/classes/Humanoid.md) and listen for the
`Landed` state to work out when a [Humanoid](/docs/reference/engine/classes/Humanoid.md) has landed.

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `active` | `boolean` | Whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is entering or leaving the `Freefall` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md). |

### Event: Humanoid.GettingUp

**Signature:** `Humanoid.GettingUp(active: boolean)`

This event fires when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) enters or leaves the
[HumanoidStateType.GettingUp](/docs/reference/engine/enums/HumanoidStateType.md) state, a transition state that is
activated shortly after the [Humanoid](/docs/reference/engine/classes/Humanoid.md) enters the
[FallingDown](/docs/reference/engine/enums/HumanoidStateType.md) (3 seconds) or
[Ragdoll](/docs/reference/engine/enums/HumanoidStateType.md) (1 second) states.

When a [Humanoid](/docs/reference/engine/classes/Humanoid.md) attempts to get back up, this event will first
fire with an `active` parameter of `true` before shortly after firing
again with an `active` parameter of `false`.

To force a [Humanoid](/docs/reference/engine/classes/Humanoid.md) to fall over, use the
[Humanoid:ChangeState()](/docs/reference/engine/classes/Humanoid.md) function with
[HumanoidStateType.FallingDown](/docs/reference/engine/enums/HumanoidStateType.md).

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `active` | `boolean` | Whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is entering or leaving the `GettingUp` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md). |

### Event: Humanoid.HealthChanged

**Signature:** `Humanoid.HealthChanged(health: float)`

This event fires when the [Humanoid.Health](/docs/reference/engine/classes/Humanoid.md) changes. However, it
will not fire if the health is increasing from a value equal to or greater
than the [Humanoid.MaxHealth](/docs/reference/engine/classes/Humanoid.md).

When [Humanoid.Health](/docs/reference/engine/classes/Humanoid.md) reaches zero, the [Humanoid](/docs/reference/engine/classes/Humanoid.md) will die
and the [Humanoid.Died](/docs/reference/engine/classes/Humanoid.md) event will fire. This event will fire with a
value of zero.

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `health` | `float` | The new value of [Humanoid.Health](/docs/reference/engine/classes/Humanoid.md). |

**Humanoid.HealthChanged**

The following example determines the change in health, printing it to the
output. It will only work in a LocalScript.

```lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	local currentHealth = humanoid.Health

	local function onHealthChanged(health)
		local change = math.abs(currentHealth - health)
		print("The humanoid's health", (currentHealth > health and "decreased by" or "increased by"), change)
		currentHealth = health
	end

	humanoid.HealthChanged:Connect(onHealthChanged)
end

player.CharacterAdded:Connect(onCharacterAdded)
```

**Health Bar**

This code sample allows you to create a simple color-changing health bar using
two nested Frames. Paste this into a LocalScript on the inner frame.

```lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Paste script into a LocalScript that is
-- parented to a Frame within a Frame
local frame = script.Parent
local container = frame.Parent
container.BackgroundColor3 = Color3.new(0, 0, 0) -- black

-- This function is called when the humanoid's health changes
local function onHealthChanged()
	local human = player.Character.Humanoid
	local percent = human.Health / human.MaxHealth
	-- Change the size of the inner bar
	frame.Size = UDim2.new(percent, 0, 1, 0)
	-- Change the color of the health bar
	if percent < 0.1 then
		frame.BackgroundColor3 = Color3.new(1, 0, 0) -- black
	elseif percent < 0.4 then
		frame.BackgroundColor3 = Color3.new(1, 1, 0) -- yellow
	else
		frame.BackgroundColor3 = Color3.new(0, 1, 0) -- green
	end
end

-- This function runs is called the player spawns in
local function onCharacterAdded(character)
	local human = character:WaitForChild("Humanoid")
	-- Pattern: update once now, then any time the health changes
	human.HealthChanged:Connect(onHealthChanged)
	onHealthChanged()
end

-- Connect our spawn listener; call it if already spawned
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
```

### Event: Humanoid.Jumping

**Signature:** `Humanoid.Jumping(active: boolean)`

This event fires when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) enters and leaves the `Jumping`
[HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md).

When a [Humanoid](/docs/reference/engine/classes/Humanoid.md) jumps, this event fires with an `active` parameter
of `true` before shortly afterwards firing again with an `active`
parameter of `false`. This second firing does not correspond with a
[Humanoid](/docs/reference/engine/classes/Humanoid.md) landing; for that, listen for the `Landed`
[HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) using [Humanoid.StateChanged](/docs/reference/engine/classes/Humanoid.md).

You can disable jumping using the [Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md)
function.

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `active` | `boolean` | Whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is entering or leaving the `Jumping` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md). |

### Event: Humanoid.MoveToFinished

**Signature:** `Humanoid.MoveToFinished(reached: boolean)`

This event fires when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) finishes walking to a goal
declared by the [Humanoid.WalkToPoint](/docs/reference/engine/classes/Humanoid.md) and
[Humanoid.WalkToPart](/docs/reference/engine/classes/Humanoid.md) properties.

The [Humanoid.WalkToPoint](/docs/reference/engine/classes/Humanoid.md) and [Humanoid.WalkToPart](/docs/reference/engine/classes/Humanoid.md)
properties can be set individually, or using the [Humanoid:MoveTo()](/docs/reference/engine/classes/Humanoid.md)
function.

If the [Humanoid](/docs/reference/engine/classes/Humanoid.md) reaches its goal within 8 seconds, this event will
return with _reached_ as true. If the goal is not reached within 8 seconds
the [Humanoid](/docs/reference/engine/classes/Humanoid.md) will stop walking and _reached_ will be false. This
timeout can be reset be calling [Humanoid:MoveTo()](/docs/reference/engine/classes/Humanoid.md) again within the
timeout period.

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `reached` | `boolean` | A boolean indicating whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) reached is goal. _True_ if the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is reached its goal, _false_ if the walk timed out before the goal could be reached. |

**Humanoid MoveTo Without Time out**

This code sample includes a function that avoids the timeout on
[Humanoid:MoveTo()](/docs/reference/engine/classes/Humanoid.md) by calling [Humanoid:MoveTo()](/docs/reference/engine/classes/Humanoid.md) again before
the timeout elapses. It also includes an optional `andThen` parameter for
which you can pass a function to be called when the humanoid reaches its
destination.

```lua
local function moveTo(humanoid, targetPoint, andThen)
	local targetReached = false

	-- listen for the humanoid reaching its target
	local connection
	connection = humanoid.MoveToFinished:Connect(function(reached)
		targetReached = true
		connection:Disconnect()
		connection = nil
		if andThen then
			andThen(reached)
		end
	end)

	-- start walking
	humanoid:MoveTo(targetPoint)

	-- execute on a new thread so as to not yield function
	task.spawn(function()
		while not targetReached do
			-- does the humanoid still exist?
			if not (humanoid and humanoid.Parent) then
				break
			end
			-- has the target changed?
			if humanoid.WalkToPoint ~= targetPoint then
				break
			end
			-- refresh the timeout
			humanoid:MoveTo(targetPoint)
			task.wait(6)
		end

		-- disconnect the connection if it is still connected
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function andThen(reached)
	print((reached and "Destination reached!") or "Failed to reach destination!")
end

moveTo(script.Parent:WaitForChild("Humanoid"), Vector3.new(50, 0, 50), andThen)
```

### Event: Humanoid.PlatformStanding

**Signature:** `Humanoid.PlatformStanding(active: boolean)`

This event fires when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) enters or leaves the
`PlatformStanding` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md).

Whilst the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is in the `PlatformStanding` state, the
[Humanoid.PlatformStand](/docs/reference/engine/classes/Humanoid.md) property will be _true_.

Whilst [Humanoid.PlatformStand](/docs/reference/engine/classes/Humanoid.md) is set to _true_, the
[Humanoid](/docs/reference/engine/classes/Humanoid.md) will be unable to move. For more information please see
the page for [Humanoid.PlatformStand](/docs/reference/engine/classes/Humanoid.md).

The PlatformStand [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) was associated with the now
disabled [Platform](/docs/reference/engine/classes/Platform.md) part. Despite this, it can still be used by
developers.

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `active` | `boolean` | Whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is entering or leaving the `PlatformStanding` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md). |

### Event: Humanoid.Ragdoll

**Signature:** `Humanoid.Ragdoll(active: boolean)`

This event fires when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) enters or leaves the `Ragdoll`
[HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md).

The `active` parameter will have the value `true` or `false` to indicate
entering or leaving.

Use [Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md) to disable the GettingUp state to
stay in the Ragdoll state.

See also:

- [Humanoid.FallingDown](/docs/reference/engine/classes/Humanoid.md) for the [Humanoid](/docs/reference/engine/classes/Humanoid.md) event connected
  with the `FallingDown` state, which behaves similarly to `Ragdoll`

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `active` | `boolean` | Whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is entering or leaving the `Ragdoll` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md). |

### Event: Humanoid.Running

**Signature:** `Humanoid.Running(speed: float)`

This event fires when the speed at which a [Humanoid](/docs/reference/engine/classes/Humanoid.md) is running
changes.

While running [Humanoids](/docs/reference/engine/classes/Humanoid.md) cover, on average, their
[Humanoid.WalkSpeed](/docs/reference/engine/classes/Humanoid.md) in studs per second.

When the [Humanoid](/docs/reference/engine/classes/Humanoid.md) stops running this event will fire with a speed
of 0.

See also:

- For swimming and climbing see the [Humanoid.Swimming](/docs/reference/engine/classes/Humanoid.md) and
  [Humanoid.Climbing](/docs/reference/engine/classes/Humanoid.md) events
- You can also detect when a [Humanoid](/docs/reference/engine/classes/Humanoid.md) is running using the
  [Humanoid.StateChanged](/docs/reference/engine/classes/Humanoid.md) event

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `speed` | `float` | The speed at which the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is running. |

**Humanoid Running**

Demonstrates connecting to the [Humanoid.Running](/docs/reference/engine/classes/Humanoid.md) event. The event is
connected to every player's humanoid that joins.

The function connected will print whether or not the humanoid is running based
on the speed.

```lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local function onRunning(speed: number)
	if speed > 0 then
		print(`{localPlayer.Name} is running`)
	else
		print(`{localPlayer.Name} has stopped`)
	end
end

humanoid.Running:Connect(function(speed: number)
	onRunning(speed)
end)
```

### Event: Humanoid.Seated

**Signature:** `Humanoid.Seated(active: boolean, currentSeatPart: BasePart)`

This event fires when a [Humanoid](/docs/reference/engine/classes/Humanoid.md) either sits in or gets up from a
[Seat](/docs/reference/engine/classes/Seat.md) or [VehicleSeat](/docs/reference/engine/classes/VehicleSeat.md).

When a character comes into contact with a seat, they are attached to the
seat and a sitting animation plays. For more information on this, see the
[Seat](/docs/reference/engine/classes/Seat.md) page.

- If the character is sitting down, the `active` parameter will be
  **true** and `currentSeatPart` will be the seat they are currently
  sitting in.
- If the character got up from a seat, the `active` parameter will be
  **false** and `currentSeatPart` will be `nil`.

See also:

- [Humanoid.Sit](/docs/reference/engine/classes/Humanoid.md), which indicates if a Humanoid is currently sitting
- [Humanoid.SeatPart](/docs/reference/engine/classes/Humanoid.md), which indicates the seat a Humanoid is
  currently sitting in, if any.

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `active` | `boolean` | True if the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is sitting down. |
| `currentSeatPart` | `BasePart` | The seat the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is sat in if it is sitting down. |

**Finding a Player's Seat**

This code sample demonstrates when the local player's
[Character](/docs/reference/engine/classes/Player.md) sits down or stands up. It should be placed
inside a [LocalScript](/docs/reference/engine/classes/LocalScript.md) within [StarterCharacterScripts](/docs/reference/engine/classes/StarterCharacterScripts.md) in order
to run when the player's character spawns in.

```lua
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local function onSeated(isSeated, seat)
	if isSeated then
		print("I'm now sitting on: " .. seat.Name .. "!")
	else
		print("I'm not sitting on anything")
	end
end

humanoid.Seated:Connect(onSeated)
```

### Event: Humanoid.StateChanged

**Signature:** `Humanoid.StateChanged(old: HumanoidStateType, new: HumanoidStateType)`

This event fires when the state of the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is changed.

As there is no "idle" humanoid state, you should instead use the
[Humanoid.Running](/docs/reference/engine/classes/Humanoid.md) event or listen to the
[RootPart](/docs/reference/engine/classes/Humanoid.md) part's
[Velocity](/docs/reference/engine/classes/BasePart.md) to work out when the [Humanoid](/docs/reference/engine/classes/Humanoid.md)
is standing still.

#### See Also

- [Humanoid:GetState()](/docs/reference/engine/classes/Humanoid.md) and [Humanoid:ChangeState()](/docs/reference/engine/classes/Humanoid.md) to get
  and set the state.
- [Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md) to enable and disable specific
  states.

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `old` | `HumanoidStateType` | The humanoid's previous state type. |
| `new` | `HumanoidStateType` | The humanoid's current state type. |

**Jumping Particles**

Emits particles from the local player's [Player.Character](/docs/reference/engine/classes/Player.md) when they
jump. To try this code sample, place it inside a [LocalScript](/docs/reference/engine/classes/LocalScript.md) parented
to [StarterCharacterScripts](/docs/reference/engine/classes/StarterCharacterScripts.md).

```lua
local character = script.Parent

local primaryPart = character.PrimaryPart

-- create particles
local particles = Instance.new("ParticleEmitter")
particles.Size = NumberSequence.new(1)
particles.Transparency = NumberSequence.new(0, 1)
particles.Acceleration = Vector3.new(0, -10, 0)
particles.Lifetime = NumberRange.new(1)
particles.Rate = 20
particles.EmissionDirection = Enum.NormalId.Back
particles.Enabled = false
particles.Parent = primaryPart

local humanoid = character:WaitForChild("Humanoid")

local isJumping = false

-- listen to humanoid state
local function onStateChanged(_oldState, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		if not isJumping then
			isJumping = true
			particles.Enabled = true
		end
	elseif newState == Enum.HumanoidStateType.Landed then
		if isJumping then
			isJumping = false
			particles.Enabled = false
		end
	end
end

humanoid.StateChanged:Connect(onStateChanged)
```

**Jump Cooldown**

The following sample will require a one second cooldown after a `Humanoid` has
landed before it is able to jump again.

To try this sample, place it inside a `LocalScript` in
`StarterCharacterScripts|StarterPlayer.StarterCharacterScripts`.

```lua
local character = script.Parent

local JUMP_DEBOUNCE = 1

local humanoid = character:WaitForChild("Humanoid")

local isJumping = false
humanoid.StateChanged:Connect(function(_oldState, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		if not isJumping then
			isJumping = true
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		end
	elseif newState == Enum.HumanoidStateType.Landed then
		if isJumping then
			isJumping = false
			task.wait(JUMP_DEBOUNCE)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end
end)
```

### Event: Humanoid.StateEnabledChanged

**Signature:** `Humanoid.StateEnabledChanged(state: HumanoidStateType, isEnabled: boolean)`

The StateEnableChanged event fires when [Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md)
is called on the [Humanoid](/docs/reference/engine/classes/Humanoid.md).

Parameters include the [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) in question along with a
bool indicating if this state is now enabled.

See also:

- To find if a state is currently enabled, use
  [Humanoid:GetStateEnabled()](/docs/reference/engine/classes/Humanoid.md)
- To listen to [Humanoid](/docs/reference/engine/classes/Humanoid.md) state changes use
  [Humanoid.StateChanged](/docs/reference/engine/classes/Humanoid.md)

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `state` | `HumanoidStateType` | The [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md) for which the enabled state has been changed. |
| `isEnabled` | `boolean` | True if the state is now enabled. |

**Humanoid State Change Detector**

When a humanoid state changes for the [Players.LocalPlayer](/docs/reference/engine/classes/Players.md), the code
below prints whether the state has been enabled or disabled.

This code should work as expected when placed in a `LocalScript`.

```lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local function onStateEnabledChanged(state, enabled)
	if enabled then
		print(state.Name .. " has been enabled")
	else
		print(state.Name .. " has been disabled")
	end
end

humanoid.StateEnabledChanged:Connect(onStateEnabledChanged)
```

### Event: Humanoid.Strafing

**Signature:** `Humanoid.Strafing(active: boolean)`

This event does not fire when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is strafing and should
not be used by developers

This event is fired when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) enters or leaves the
`StrafingNoPhysics` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md).

When the [Humanoid](/docs/reference/engine/classes/Humanoid.md) enters the `StrafingNoPhysics` state this event
will fire with an _active_ parameter of _true_. The event will fire again
with _active_ equal to _false_ when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) leaves the
`StrafingNoPhysics` state.

This event is associated with the `StrafingNoPhysics` [Humanoid](/docs/reference/engine/classes/Humanoid.md)
state and does **not** fire when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is moving
perpendicular to the direction it is facing. This state is currently
unused, if it is set using [Humanoid:ChangeState()](/docs/reference/engine/classes/Humanoid.md) the state will
revert to `RunningNoPhysics`.

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `active` | `boolean` | Whether the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is entering or leaving the `StrafingNoPhysics` [HumanoidStateType](/docs/reference/engine/enums/HumanoidStateType.md). |

### Event: Humanoid.Swimming

**Signature:** `Humanoid.Swimming(speed: float)`

This event fires when the speed at which a [Humanoid](/docs/reference/engine/classes/Humanoid.md) is swimming in
[Terrain](/docs/reference/engine/classes/Terrain.md) water changes.

[Humanoids](/docs/reference/engine/classes/Humanoid.md) swim at 87.5% of their
[Humanoid.WalkSpeed](/docs/reference/engine/classes/Humanoid.md).

This event will not always fire with a speed of 0 when the
[Humanoid](/docs/reference/engine/classes/Humanoid.md) stops swimming.

See also:

- For running and climbing see the [Humanoid.Running](/docs/reference/engine/classes/Humanoid.md) and
  [Humanoid.Climbing](/docs/reference/engine/classes/Humanoid.md) events
- You can also detect when a [Humanoid](/docs/reference/engine/classes/Humanoid.md) is swimming using the
  [Humanoid.StateChanged](/docs/reference/engine/classes/Humanoid.md) event
- You can disable swimming using the [Humanoid:SetStateEnabled()](/docs/reference/engine/classes/Humanoid.md)
  function

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `speed` | `float` | The speed the [Humanoid](/docs/reference/engine/classes/Humanoid.md) is currently swimming at. |

### Event: Humanoid.Touched

**Signature:** `Humanoid.Touched(touchingPart: BasePart, humanoidPart: BasePart)`

This event fires when one of the humanoid's limbs comes in contact with
another [BasePart](/docs/reference/engine/classes/BasePart.md). The [BasePart](/docs/reference/engine/classes/BasePart.md) which the limb is touching,
along with the limb itself, is given.

This event will not fire when limbs belonging to the [Humanoid](/docs/reference/engine/classes/Humanoid.md) come
into contact with themselves.

#### Alternatives

Although the [Humanoid.Touched](/docs/reference/engine/classes/Humanoid.md) event is useful, you should consider
if there are alternatives that better suit your needs.

- In most cases, it's advised to connect a [BasePart.Touched](/docs/reference/engine/classes/BasePart.md) event
  for [BaseParts](/docs/reference/engine/classes/BasePart.md) of interest instead, as the
  [Humanoid.Touched](/docs/reference/engine/classes/Humanoid.md) event will constantly fire when the humanoid is
  moving. For example, in a dodgeball game, it would be more practical to
  connect a [Touched](/docs/reference/engine/classes/BasePart.md) event for the balls rather
  than use [Humanoid.Touched](/docs/reference/engine/classes/Humanoid.md).
- When trying to work out when the [Humanoid](/docs/reference/engine/classes/Humanoid.md) has landed on the
  ground, the [Humanoid.StateChanged](/docs/reference/engine/classes/Humanoid.md) event is more suitable.
  Alternatively, you can check [Humanoid.FloorMaterial](/docs/reference/engine/classes/Humanoid.md) to see if
  the humanoid is standing on any non-air material.

#### Notes

- Connecting to this event will cause a [TouchTransmitter](/docs/reference/engine/classes/TouchTransmitter.md) to be
  created in every limb.
- There is currently no equivalent of [BasePart.TouchEnded](/docs/reference/engine/classes/BasePart.md) for
  [Humanoids](/docs/reference/engine/classes/Humanoid.md).

*Security: None · Capabilities: AvatarBehavior*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `touchingPart` | `BasePart` | The [BasePart](/docs/reference/engine/classes/BasePart.md) the [Humanoid](/docs/reference/engine/classes/Humanoid.md) has come in contact with. |
| `humanoidPart` | `BasePart` | The limb of the [Humanoid](/docs/reference/engine/classes/Humanoid.md) that has been touched. |

**Midas Touch**

When placed inside a [Player.Character](/docs/reference/engine/classes/Player.md) model this code will give a
player the 'Midas touch'. Everything their character touches will change to
gold.

When the `Humanoid` dies, this change is undone and the golden
`BasePart|BaseParts` are returned to their original state.

To test this out, place this code inside a `Script` and place it in
`StarterCharacterScripts|StarterPlayer.StarterCharacterScripts`.

```lua
local character = script.Parent

local humanoid = character:WaitForChild("Humanoid")

local partInfo = {}

local debounce = false

local function onHumanoidTouched(hit, _limb)
	if debounce then
		return
	end

	if not hit.CanCollide or hit.Transparency ~= 0 then
		return
	end

	if not partInfo[hit] then
		partInfo[hit] = {
			BrickColor = hit.BrickColor,
			Material = hit.Material,
		}

		hit.BrickColor = BrickColor.new("Gold")
		hit.Material = Enum.Material.Ice

		debounce = true
		task.wait(0.2)
		debounce = false
	end
end

local touchedConnection = humanoid.Touched:Connect(onHumanoidTouched)

local function onHumanoidDied()
	if touchedConnection then
		touchedConnection:Disconnect()
	end

	-- undo all of the gold
	for part, info in pairs(partInfo) do
		if part and part.Parent then
			part.BrickColor = info.BrickColor
			part.Material = info.Material
		end
	end
end

humanoid.Died:Connect(onHumanoidDied)
```

### Event: Humanoid.AnimationPlayed

**Signature:** `Humanoid.AnimationPlayed(animationTrack: AnimationTrack)`

The AnimationPlayed event fires when an [AnimationTrack](/docs/reference/engine/classes/AnimationTrack.md) begins
playing on the [Humanoid](/docs/reference/engine/classes/Humanoid.md).

A common use for this function is to connect the
[AnimationTrack.KeyframeReached](/docs/reference/engine/classes/AnimationTrack.md) event for the playing
AnimationTrack, so additional effects can be added to the animation (for
example [Sounds](/docs/reference/engine/classes/Sound.md) and
[ParticleEmitters](/docs/reference/engine/classes/ParticleEmitter.md)).

This event can be used for any [Humanoid](/docs/reference/engine/classes/Humanoid.md) regardless if it belongs
to the local player's client or not.

See also:

- For the [AnimationController](/docs/reference/engine/classes/AnimationController.md) equivalent of this event, please see
  [AnimationController.AnimationPlayed](/docs/reference/engine/classes/AnimationController.md)

*Security: None · Capabilities: Animation*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `animationTrack` | `AnimationTrack` | The [AnimationTrack](/docs/reference/engine/classes/AnimationTrack.md) that has begun playing. |

**Pausing An Animation When a Keyframe is Reached**

The example below pauses any AnimationTrack playing on the humanoid when a
keyframe named 'PausePlayback' is reached.

```lua
local humanoid = script.Parent:WaitForChild("Humanoid")

humanoid.AnimationPlayed:Connect(function(animationTrack)
	if not animationTrack then
		return
	end

	local connection = animationTrack.KeyframeReached:Connect(function(keyframeName)
		if keyframeName == "PausePlayback" then
			-- adjust speed to 0, pausing the animation
			animationTrack:AdjustSpeed(0)
		end
	end)

	animationTrack.Stopped:Wait()
	connection:Disconnect()
end)
```

### Event: Humanoid.CustomStatusAdded

**Signature:** `Humanoid.CustomStatusAdded(status: string)`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

The CustomStatusAdded event fires when a status is added to the Humanoid
via the [Humanoid:AddCustomStatus()](/docs/reference/engine/classes/Humanoid.md) method.

*Security: None*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `status` | `string` |  |

### Event: Humanoid.CustomStatusRemoved

**Signature:** `Humanoid.CustomStatusRemoved(status: string)`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

The CustomStatusRemoved event fires when a status is removed from the
Humanoid via the [Humanoid:RemoveCustomStatus()](/docs/reference/engine/classes/Humanoid.md) method.

*Security: None*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `status` | `string` |  |

### Event: Humanoid.StatusAdded

**Signature:** `Humanoid.StatusAdded(status: Status)`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

The StatusAdded event fires when a status is added to the Humanoid.

*Security: None*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `status` | `Status` |  |

**Humanoid.StatusAdded**

```lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local function onStatusAdded(status)
	if status == Enum.Status.Poison then
		print("The humanoid is now poisoned!")
	elseif status == Enum.Status.Confusion then
		print("The humanoid is now confused!")
	end
end

humanoid.StatusAdded:Connect(onStatusAdded)

humanoid:AddStatus(Enum.Status.Poison) --> The humanoid is now poisoned!
```

### Event: Humanoid.StatusRemoved

**Signature:** `Humanoid.StatusRemoved(status: Status)`

> **Deprecated:** This item is deprecated, as it was a part of the unfinished RbxStatus library which would have allowed you to add conditions to a Humanoid. Do not use it for new work.

The StatusRemoved event fires when a status is removed from the Humanoid.

*Security: None*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `status` | `Status` |  |

**Humanoid.StatusRemoved**

```lua
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local function onStatusRemoved(status)
	if status == Enum.Status.Poison then
		print("The humanoid has been cured of poison!")
	elseif status == Enum.Status.Confusion then
		print("The humanoid has been reoriented!")
	end
end

humanoid.StatusRemoved:Connect(onStatusRemoved)

humanoid:RemoveStatus(Enum.Status.Poison) --> The humanoid has been cured of poison!
```

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