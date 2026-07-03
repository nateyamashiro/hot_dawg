---
title: "Client-server runtime"
url: /docs/en-us/projects/client-server
last_updated: 2026-07-02T02:14:36Z
description: "An overview of the client-server model in Roblox."
---

# Client-server runtime

## Server

Roblox experiences are multiplayer by default and run in a client-server model. The Roblox **server** is the ultimate authority for maintaining the experience's state, and is responsible for keeping all connected clients in sync with the server.

![A server grouping with connections to three client devices.](../assets/scripting/client-server/Client-Server-Model.png)_Server with connections to three client devices_

## Client

When an experience runs, Roblox copies a version of the "edit" data model that you built and published from Studio and runs it on Roblox servers as the "runtime" data model.

Connected clients also receive a copy of the runtime data model and any initialization of the player occurs, such as initializing a player's backpack (inventory) or local user interface. When an experience has `Class.Workspace.StreamingEnabled` set to true, the server initially only sends a subset of content under `Class.Workspace` that is closest to the client. The client then renders the 3D world and begins running any applicable scripts.

![A diagram that maps objects between 'edit' and 'runtime' data models.](../assets/scripting/client-server/Data-Model-Mapping.png)__

## Replication

The server constantly updates connected clients, keeping everything in sync across the server and clients through a process called **replication**, which synchronizes the data model, physics simulation, and chat messages. Replication logic exists on both the client and server to ensure synchronization.

#### Data

Data model changes can occur in a variety of cases, such as when something in the 3D world is created or a property of the 3D world changes. This typically occurs when a script on the server or client makes a change that needs to be reflected on the other side of the client-server boundary. The following diagrams show common scenarios for data replication.

**Client → Server**![A diagram of one client communicating with the server.](../assets/scripting/client-server/Remote-Flow-Client-Server.png)_Communication from any client to the server. For example, a client presses the `P` key to drink an invisibility potion, and tells the server to make that player's character invisible to all other players._

**Server → Client**![A diagram of the server communicating with one client.](../assets/scripting/client-server/Remote-Flow-Server-Client.png)_Communication from the server to one specific client. For example, a player joins the experience and the server populates that player's inventory with a set of items._

**Server → All Clients**![A diagram of the server communicating with all connected clients.](../assets/scripting/client-server/Remote-Flow-Server-All-Clients.png)_Communication between the server and all connected clients. For example, displaying a countdown timer to all participants in a race._

#### Physics

Roblox uses a rigid body physics engine, which is responsible for calculating the movement and interactions of parts in the 3D world. By default, all parts in Roblox are rigid bodies and participate in simulated physics, unless otherwise specified. You can also group multiple parts together into assemblies, which the physics engine treats as a single rigid body.

![A single block part in the shape of a cube that represents a single assembly.](../assets/physics/assemblies/Assembly-Example-Block.png)_1 assembly; 1 part_

![A player character that represents a single assembly of 18 individual parts.](../assets/physics/assemblies/Assembly-Example-Avatar.png)_1 assembly; 18 parts_

![A pirate ship mesh that represents a single assembly of 179 individual parts.](../assets/physics/assemblies/Assembly-Example-Ship.png)_1 assembly; 179 parts_

Roblox replicates physics simulation data between the server and clients when necessary. To assist with simulation performance, Roblox can assign ownership of assemblies to a specific client or server. This means that the client or server can be responsible for simulating the physics of that assembly. Other clients receive updates about the assembly's position and movement from the owning client or server. Ownership typically happens automatically, but you can assign it directly for fine-tuned responsiveness.

_Part ownership indicated through colored outlines_

#### Chat

Roblox replicates chat messages between the server and client. The server is responsible for filtering chat messages and deciding which messages to replicate to other clients. For example, the server may filter out messages that contain profanity or are too long.

> **Success:** Most players on Roblox experience between 100–300 milliseconds of network latency. Roblox Studio playtesting runs with a default of no latency, but you can change **Network Simulation** settings in the **Network** section of [Studio Settings](/docs/en-us/studio/setup.md#customization) (`Alt``S` on Windows; `⌥``S` on Mac). Use a minimum delay of 50–150 milliseconds in both the inbound and outbound directions to better simulate how network latency will affect your experience.