---
name: CollectionService
last_updated: 2026-07-02T02:14:36Z
inherits:
  - Instance
  - Object
type: class
memory_category: Instances
tags:
  - NotCreatable
  - Service
summary: "A service which manages instance collections using assigned tags."
---

# Class: CollectionService

> A service which manages instance collections using assigned tags.

## Description

`CollectionService` manages groups (collections) of instances with **tags**.
Tags are sets of strings applied to instances that replicate from the server
to the client. They are also serialized when places are saved.

The primary use of `CollectionService` is to register instances with specific
tags that you can use to extend their behavior. If you find yourself adding
the same script to many different instances, a script that uses
`CollectionService` may be better.

Tags can be added or removed through this class' methods such as
[AddTag()](/docs/reference/engine/classes/CollectionService.md) or
[RemoveTag()](/docs/reference/engine/classes/CollectionService.md). They can also be managed
directly in Studio through the
[Tags](/docs/en-us/studio/properties.md#instance-tags) section of an instance's
properties.

##### Replication

When tags replicate, **all tags on an instance replicate at the same time**.
Therefore, if you set a tag on an instance from the client then add/remove a
**different** tag on the same instance from the server, the client's local
tags on the instance are overwritten. In
[StreamingEnabled](/docs/reference/engine/classes/Workspace.md) places, instances can be
unloaded as they leave the client's streamed area. If such an instance
re-enters the streamed area, properties and tags will be re-synchronized from
the server. This can cause changes made by [LocalScripts](/docs/reference/engine/classes/LocalScript.md) to
be overwritten/removed.

## Methods

### Method: CollectionService:AddTag

**Signature:** `CollectionService:AddTag(instance: Instance, tag: string): ()`

This method applies a tag to an [Instance](/docs/reference/engine/classes/Instance.md), doing nothing if the tag
is already applied to that instance. Successfully adding a tag will fire a
signal created by
[GetInstanceAddedSignal()](/docs/reference/engine/classes/CollectionService.md)
with the given tag.

##### Warnings

- An instance's tags that were added client-side will be dropped if the
  server later adds or removes a tag on that instance because the server
  replicates all tags together and overwrites previous tags.

- When tagging an instance, it is common that some resources are used to
  give the tag its functionality, for example event connections or tables.
  To prevent memory leaks, it's a good idea to clean these up (disconnect,
  set to `nil`, etc.) when no longer needed for a tag. Do this when
  calling [RemoveTag()](/docs/reference/engine/classes/CollectionService.md), calling
  [Instance:Destroy()](/docs/reference/engine/classes/Instance.md) or in a function connected to a signal
  returned by
  [GetInstanceRemovedSignal()](/docs/reference/engine/classes/CollectionService.md).

*Security: None · Thread Safety: Unsafe · Capabilities: Basic*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `instance` | `Instance` |  |  |
| `tag` | `string` |  |  |

**Returns:** `()`

### Method: CollectionService:GetAllTags

**Signature:** `CollectionService:GetAllTags(): Array`

Returns an array of all tags in the experience.

*Security: None · Thread Safety: Safe · Capabilities: Basic*

**Returns:** `Array`

### Method: CollectionService:GetInstanceAddedSignal

**Signature:** `CollectionService:GetInstanceAddedSignal(tag: string): RBXScriptSignal`

Given a tag (string), this method returns a signal which fires under two
conditions:

- The tag is assigned to an instance within the [DataModel](/docs/reference/engine/classes/DataModel.md) using
  [CollectionService:AddTag()](/docs/reference/engine/classes/CollectionService.md) or [Instance:AddTag()](/docs/reference/engine/classes/Instance.md).

- An instance with the given tag is added as a descendant of the
  [DataModel](/docs/reference/engine/classes/DataModel.md), for example by setting [Instance.Parent](/docs/reference/engine/classes/Instance.md) or
  similar.

Subsequent calls to this method with the same tag return the same signal
object. Consider also calling
[GetTagged()](/docs/reference/engine/classes/CollectionService.md) to get a list of
instances that already have a tag (and thus won't fire the event if they
already are in the [DataModel](/docs/reference/engine/classes/DataModel.md)).

See also
[GetInstanceRemovedSignal()](/docs/reference/engine/classes/CollectionService.md)
which returns an event that fires under similar conditions.

*Security: None · Thread Safety: Unsafe · Capabilities: Basic*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tag` | `string` |  | The tag to watch for. |

**Returns:** `RBXScriptSignal` — An event that fires when you add the tag to an instance.

**Deadly Bricks using CollectionService**

This code sample causes any [BasePart](/docs/reference/engine/classes/BasePart.md) with the tag `Deadly` to kill any
[Humanoid](/docs/reference/engine/classes/Humanoid.md) that touches it. It does this using a common pattern with
[CollectionService](/docs/reference/engine/classes/CollectionService.md) to listen for all parts with the tag and make a
connection, then disconnect the connection when the tag is removed.

```lua
local CollectionService = game:GetService("CollectionService")

local tag = "Deadly"

local function onDeadlyPartTouched(otherPart)
	if not otherPart.Parent then
		return
	end
	local humanoid = otherPart.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

-- Save the connections so they can be disconnected when the tag is removed
local connections = {}

local function onInstanceAdded(object)
	-- Confirm that the object with this tag is a BasePart
	if object:IsA("BasePart") then
		connections[object] = object.Touched:Connect(onDeadlyPartTouched)
	end
end

local function onInstanceRemoved(object)
	-- If there is a stored connection on this object, disconnect/remove it
	if connections[object] then
		connections[object]:Disconnect()
		connections[object] = nil
	end
end

-- Listen for this tag being applied to objects
CollectionService:GetInstanceAddedSignal(tag):Connect(onInstanceAdded)
CollectionService:GetInstanceRemovedSignal(tag):Connect(onInstanceRemoved)

-- Also detect any objects that already have the tag
for _, object in pairs(CollectionService:GetTagged(tag)) do
	onInstanceAdded(object)
end
```

**Expected output:** Try tagging a part using `CollectionService` by pasting this into the Command bar:
`game:GetService("CollectionService"):AddTag(workspace.Part, "Deadly")`
Then, when you press Play and touch the brick with your character they should die.

### Method: CollectionService:GetInstanceRemovedSignal

**Signature:** `CollectionService:GetInstanceRemovedSignal(tag: string): RBXScriptSignal`

Given a tag (string), this method returns a signal which fires under two
conditions:

- The tag is removed from an instance within the [DataModel](/docs/reference/engine/classes/DataModel.md) using
  [CollectionService:RemoveTag()](/docs/reference/engine/classes/CollectionService.md) or [Instance:RemoveTag()](/docs/reference/engine/classes/Instance.md).

- An instance with the given tag is removed as a descendant of the
  [DataModel](/docs/reference/engine/classes/DataModel.md), for example by un‑setting [Instance.Parent](/docs/reference/engine/classes/Instance.md) or
  similar.

Subsequent calls to this method with the same tag return the same signal
object. The signal is useful for cleaning up resources used by instances
that once had tags, such as disconnecting connections.

See also
[GetInstanceAddedSignal()](/docs/reference/engine/classes/CollectionService.md)
which returns an event that fires under similar conditions.

*Security: None · Thread Safety: Unsafe · Capabilities: Basic*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tag` | `string` |  | The tag to watch for. |

**Returns:** `RBXScriptSignal` — An event that fires when you remove the tag from an instance.

**Deadly Bricks using CollectionService**

This code sample causes any [BasePart](/docs/reference/engine/classes/BasePart.md) with the tag `Deadly` to kill any
[Humanoid](/docs/reference/engine/classes/Humanoid.md) that touches it. It does this using a common pattern with
[CollectionService](/docs/reference/engine/classes/CollectionService.md) to listen for all parts with the tag and make a
connection, then disconnect the connection when the tag is removed.

```lua
local CollectionService = game:GetService("CollectionService")

local tag = "Deadly"

local function onDeadlyPartTouched(otherPart)
	if not otherPart.Parent then
		return
	end
	local humanoid = otherPart.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

-- Save the connections so they can be disconnected when the tag is removed
local connections = {}

local function onInstanceAdded(object)
	-- Confirm that the object with this tag is a BasePart
	if object:IsA("BasePart") then
		connections[object] = object.Touched:Connect(onDeadlyPartTouched)
	end
end

local function onInstanceRemoved(object)
	-- If there is a stored connection on this object, disconnect/remove it
	if connections[object] then
		connections[object]:Disconnect()
		connections[object] = nil
	end
end

-- Listen for this tag being applied to objects
CollectionService:GetInstanceAddedSignal(tag):Connect(onInstanceAdded)
CollectionService:GetInstanceRemovedSignal(tag):Connect(onInstanceRemoved)

-- Also detect any objects that already have the tag
for _, object in pairs(CollectionService:GetTagged(tag)) do
	onInstanceAdded(object)
end
```

**Expected output:** Try tagging a part using `CollectionService` by pasting this into the Command bar:
`game:GetService("CollectionService"):AddTag(workspace.Part, "Deadly")`
Then, when you press Play and touch the brick with your character they should die.

### Method: CollectionService:GetTagged

**Signature:** `CollectionService:GetTagged(tag: string): Instances`

This method returns an array of instances with a given tag which are
descendants of the [DataModel](/docs/reference/engine/classes/DataModel.md). Removing a tag using
[CollectionService:RemoveTag()](/docs/reference/engine/classes/CollectionService.md) or [Instance:RemoveTag()](/docs/reference/engine/classes/Instance.md)
ensures this method does not return them.

If you want to detect all instances with a tag, both present **and**
future, use this method to iterate over instances while also making a
connection to a signal returned by
[GetInstanceAddedSignal()](/docs/reference/engine/classes/CollectionService.md).

This method does not guarantee any ordering of the returned instances.
Additionally, it's possible that instances can have the given tag assigned
to them but not be a descendant of the [DataModel](/docs/reference/engine/classes/DataModel.md), for example its
parent is `nil`; this method will not return such instances.

*Security: None · Thread Safety: Safe · Capabilities: Basic*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tag` | `string` |  | The tag to search for. |

**Returns:** `Instances` — An array of all instances with the tag.

**Deadly Bricks using CollectionService**

This code sample causes any [BasePart](/docs/reference/engine/classes/BasePart.md) with the tag `Deadly` to kill any
[Humanoid](/docs/reference/engine/classes/Humanoid.md) that touches it. It does this using a common pattern with
[CollectionService](/docs/reference/engine/classes/CollectionService.md) to listen for all parts with the tag and make a
connection, then disconnect the connection when the tag is removed.

```lua
local CollectionService = game:GetService("CollectionService")

local tag = "Deadly"

local function onDeadlyPartTouched(otherPart)
	if not otherPart.Parent then
		return
	end
	local humanoid = otherPart.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

-- Save the connections so they can be disconnected when the tag is removed
local connections = {}

local function onInstanceAdded(object)
	-- Confirm that the object with this tag is a BasePart
	if object:IsA("BasePart") then
		connections[object] = object.Touched:Connect(onDeadlyPartTouched)
	end
end

local function onInstanceRemoved(object)
	-- If there is a stored connection on this object, disconnect/remove it
	if connections[object] then
		connections[object]:Disconnect()
		connections[object] = nil
	end
end

-- Listen for this tag being applied to objects
CollectionService:GetInstanceAddedSignal(tag):Connect(onInstanceAdded)
CollectionService:GetInstanceRemovedSignal(tag):Connect(onInstanceRemoved)

-- Also detect any objects that already have the tag
for _, object in pairs(CollectionService:GetTagged(tag)) do
	onInstanceAdded(object)
end
```

**Expected output:** Try tagging a part using `CollectionService` by pasting this into the Command bar:
`game:GetService("CollectionService"):AddTag(workspace.Part, "Deadly")`
Then, when you press Play and touch the brick with your character they should die.

### Method: CollectionService:GetTags

**Signature:** `CollectionService:GetTags(instance: Instance): Array`

Given an [Instance](/docs/reference/engine/classes/Instance.md), this method returns an array of strings which
are the tags applied to the instance.

This method is useful when you want to do something with multiple instance
tags at once, but it's inefficient to check for the existence of a single
tag. For this, use [HasTag()](/docs/reference/engine/classes/CollectionService.md) to check
for a single tag.

*Security: None · Thread Safety: Safe · Capabilities: Basic*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `instance` | `Instance` |  | The instance whose tags should be returned. |

**Returns:** `Array` — An array of strings which are the tags applied to the given instance.

**Using Tags and CollectionService**

This code sample demonstrates adding, removing and querying a tag from an
object using [CollectionService](/docs/reference/engine/classes/CollectionService.md).

```lua
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local object = Workspace.Part

-- Add a tag
CollectionService:AddTag(object, "Deadly")

-- Query for a tag
if CollectionService:HasTag(object, "Deadly") then
	print(object:GetFullName() .. " is deadly")
end

-- List tags on an object
local tags = CollectionService:GetTags(object)
print("The object " .. object:GetFullName() .. " has tags: " .. table.concat(tags, ", "))

-- Remove a tag
CollectionService:RemoveTag(object, "Deadly")
```

**Expected output:** When run, you should see "Workspace.Part is deadly" followed by "The object Workspace.Part has tags: Deadly" in the Output.

### Method: CollectionService:HasTag

**Signature:** `CollectionService:HasTag(instance: Instance, tag: string): boolean`

This method returns whether a given [Instance](/docs/reference/engine/classes/Instance.md) has a tag.

By extension, any tags returned by a call to
[GetTags()](/docs/reference/engine/classes/CollectionService.md) on an instance will return
`true` when used with this method.

*Security: None · Thread Safety: Safe · Capabilities: Basic*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `instance` | `Instance` |  | The instance to check for the presence of a tag. |
| `tag` | `string` |  | The tag to check for. |

**Returns:** `boolean` — Whether the instance has the tag.

**Using Tags and CollectionService**

This code sample demonstrates adding, removing and querying a tag from an
object using [CollectionService](/docs/reference/engine/classes/CollectionService.md).

```lua
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local object = Workspace.Part

-- Add a tag
CollectionService:AddTag(object, "Deadly")

-- Query for a tag
if CollectionService:HasTag(object, "Deadly") then
	print(object:GetFullName() .. " is deadly")
end

-- List tags on an object
local tags = CollectionService:GetTags(object)
print("The object " .. object:GetFullName() .. " has tags: " .. table.concat(tags, ", "))

-- Remove a tag
CollectionService:RemoveTag(object, "Deadly")
```

**Expected output:** When run, you should see "Workspace.Part is deadly" followed by "The object Workspace.Part has tags: Deadly" in the Output.

### Method: CollectionService:RemoveTag

**Signature:** `CollectionService:RemoveTag(instance: Instance, tag: string): ()`

This method removes a tag from an instance. Successfully removing a tag
will fire a signal created by
[GetInstanceRemovedSignal()](/docs/reference/engine/classes/CollectionService.md)
with the given tag.

When removing a tag, it's common that some resources are used to give the
tag its functionality, for example event connections or tables. To prevent
memory leaks, it's a good idea to clean these up (disconnect, set to
`nil`, etc.) when no longer needed for a tag.

*Security: None · Thread Safety: Unsafe · Capabilities: Basic*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `instance` | `Instance` |  | The instance to remove the tag from. |
| `tag` | `string` |  | The tag to remove from the instance. |

**Returns:** `()`

**Using Tags and CollectionService**

This code sample demonstrates adding, removing and querying a tag from an
object using [CollectionService](/docs/reference/engine/classes/CollectionService.md).

```lua
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local object = Workspace.Part

-- Add a tag
CollectionService:AddTag(object, "Deadly")

-- Query for a tag
if CollectionService:HasTag(object, "Deadly") then
	print(object:GetFullName() .. " is deadly")
end

-- List tags on an object
local tags = CollectionService:GetTags(object)
print("The object " .. object:GetFullName() .. " has tags: " .. table.concat(tags, ", "))

-- Remove a tag
CollectionService:RemoveTag(object, "Deadly")
```

**Expected output:** When run, you should see "Workspace.Part is deadly" followed by "The object Workspace.Part has tags: Deadly" in the Output.

### Method: CollectionService:GetCollection

**Signature:** `CollectionService:GetCollection(class: string): Instances`

> **Deprecated:** This item has been superseded by a [CollectionService](/docs/reference/engine/classes/CollectionService.md) tagging method. The equivalent function using the new method is [CollectionService:GetTagged()](/docs/reference/engine/classes/CollectionService.md) which should be used in new work.

This function returns all instances of a given class which are in the
[DataModel](/docs/reference/engine/classes/DataModel.md). Only works for [Configuration](/docs/reference/engine/classes/Configuration.md),
[CustomEvent](/docs/reference/engine/classes/CustomEvent.md), [CustomEventReceiver](/docs/reference/engine/classes/CustomEventReceiver.md), [Dialog](/docs/reference/engine/classes/Dialog.md), and
[VehicleSeat](/docs/reference/engine/classes/VehicleSeat.md).

*Security: None · Thread Safety: Unsafe · Capabilities: Basic*

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `class` | `string` |  |  |

**Returns:** `Instances`

**CollectionService:GetCollection1**

```lua
local CollectionService = game:GetService("CollectionService")

for _index = 1, 10 do
	local configuration = Instance.new("Configuration")
	configuration.Parent = workspace
end

local objects = CollectionService:GetCollection("Configuration")
print(#objects)
```

## Events

### Event: CollectionService.TagAdded

**Signature:** `CollectionService.TagAdded(tag: string)`

This event fires when a tag is added to an instance and the added tag is
the only occurrence of that tag in the place.

*Security: None · Capabilities: Basic*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `tag` | `string` |  |

### Event: CollectionService.TagRemoved

**Signature:** `CollectionService.TagRemoved(tag: string)`

This event fires when a tag is removed from an instance and the removed
tag is no longer used anywhere in the place.

*Security: None · Capabilities: Basic*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `tag` | `string` |  |

### Event: CollectionService.ItemAdded

**Signature:** `CollectionService.ItemAdded(instance: Instance)`

> **Deprecated:** This item has been superseded by a [CollectionService](/docs/reference/engine/classes/CollectionService.md) tagging method. There is currently no means of checking when a tag is added.

This function fires when a [Configuration](/docs/reference/engine/classes/Configuration.md), [CustomEvent](/docs/reference/engine/classes/CustomEvent.md),
[CustomEventReceiver](/docs/reference/engine/classes/CustomEventReceiver.md), [Dialog](/docs/reference/engine/classes/Dialog.md), or [VehicleSeat](/docs/reference/engine/classes/VehicleSeat.md) is
added to the [DataModel](/docs/reference/engine/classes/DataModel.md).

*Security: None · Capabilities: Basic*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `instance` | `Instance` |  |

**CollectionService.ItemAdded1**

```lua
local CollectionService = game:GetService("CollectionService")

CollectionService.ItemAdded:Connect(function(instance)
	print(instance.ClassName .. " added to DataModel")
end)

local part = Instance.new("Part")
part.Parent = workspace --// Doesn't fire because CollectionService doesn't watch Parts

local dialog = Instance.new("Dialog")
dialog.Parent = workspace --> Dialog added to DataModel
```

### Event: CollectionService.ItemRemoved

**Signature:** `CollectionService.ItemRemoved(instance: Instance)`

> **Deprecated:** This item has been superseded by a [CollectionService](/docs/reference/engine/classes/CollectionService.md) tagging method. There is currently no means of checking when a tag is removed.

This function fires when a [Configuration](/docs/reference/engine/classes/Configuration.md), [CustomEvent](/docs/reference/engine/classes/CustomEvent.md),
[CustomEventReceiver](/docs/reference/engine/classes/CustomEventReceiver.md), [Dialog](/docs/reference/engine/classes/Dialog.md), or [VehicleSeat](/docs/reference/engine/classes/VehicleSeat.md) is
removed from the [DataModel](/docs/reference/engine/classes/DataModel.md).

*Security: None · Capabilities: Basic*

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `instance` | `Instance` |  |

**CollectionService.ItemRemoved1**

```lua
local CollectionService = game:GetService("CollectionService")

CollectionService.ItemRemoved:Connect(function(instance)
	print(instance.ClassName .. " removed from the DataModel")
end)

local part = Instance.new("Part")
part.Parent = workspace
part:Destroy() --// Doesn't fire because CollectionService ignores Parts

local dialog = Instance.new("Dialog")
dialog.Parent = workspace
dialog:Destroy() --> Dialog removed from the DataModel
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