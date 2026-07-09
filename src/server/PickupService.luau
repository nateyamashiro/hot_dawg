--!strict
-- Pick up & hold your own glizzies (owner-only; genre staple — you can carry your
-- own units around your base). Server-authoritative COSMETIC hold: inventory and
-- income never change; the held unit just vacates its display slot (PlotManager
-- excludes one count of the held key from the fill) and rides in the player's hand
-- as a Tool. Click the Tool to put it back on the stand; dying, respawning, or
-- leaving also puts it back. ONE held dog at a time — a held dog can't be stolen,
-- so the cap keeps "hide it in my hand" from sheltering a collection.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GlizzyModel = require(ReplicatedStorage.Shared.GlizzyModel)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local Variants = require(ReplicatedStorage.Shared.Variants)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local PickupService = {}

local remFeedback: RemoteEvent

local held: { [number]: { tool: Tool, key: string } } = {}

-- Return the held glizzy to the stand. Idempotent — every exit path funnels here,
-- and `held` clears BEFORE the tool is destroyed so the Destroying hook no-ops.
local function putBack(player: Player)
	local h = held[player.UserId]
	if not h then
		return
	end
	held[player.UserId] = nil
	PlotManager.setHeldKey(player, nil) -- refills the vacated slot
	if h.tool.Parent then
		h.tool:Destroy()
	end
end

-- Build the hand prop: the glizzy re-rooted into a Tool (sausage becomes Handle;
-- GlizzyModel's anchored=false mode already welds every part to the sausage).
local function buildTool(key: string): Tool?
	local baseName, variant = Variants.decode(key)
	local dog = HotDogDex.getByKey(key)
	if not dog then
		return nil
	end
	local model = GlizzyModel.build(baseName, {
		rarity = dog.rarity,
		variant = variant,
		scale = if variant == "Giant" then 1.28 else 0.85, -- carry-rig sizing
		anchored = false,
		fx = false,
	})
	local primary = model.PrimaryPart :: BasePart
	local tool = Instance.new("Tool")
	tool.Name = Variants.displayName(key)
	tool.RequiresHandle = true
	tool.CanBeDropped = false -- putBack is the only way it leaves your hand
	tool.ToolTip = "Click to put it back on your stand"
	primary.Name = "Handle"
	for _, child in model:GetChildren() do
		child.Parent = tool
	end
	model:Destroy()
	return tool
end

local function onPickup(player: Player, key: string)
	if not RateLimit.check(player, "PickupGlizzy", 5) then
		return
	end
	if held[player.UserId] then
		putBack(player) -- swapping: return the current one first
	end
	local data = DataManager.get(player)
	if not data or (data.hotDogs[key] or 0) <= 0 then
		return -- must actually own one of that key (prompt could be stale)
	end
	local character = player.Character
	if not (character and character:FindFirstChildOfClass("Humanoid")) then
		return
	end
	local tool = buildTool(key)
	if not tool then
		return
	end
	held[player.UserId] = { tool = tool, key = key }
	PlotManager.setHeldKey(player, key) -- vacates one display slot
	tool.Parent = character -- parenting to the character equips it into the hand

	-- Clicking the held glizzy puts it back on the stand.
	tool.Activated:Connect(function()
		putBack(player)
	end)
	-- Any way the tool leaves the world (death, respawn wiping the backpack,
	-- something destroying the character) returns the dog to the display.
	tool.Destroying:Connect(function()
		local h = held[player.UserId]
		if h and h.tool == tool then
			held[player.UserId] = nil
			PlotManager.setHeldKey(player, nil)
		end
	end)
	remFeedback:FireClient(
		player,
		true,
		"🌭 Holding " .. tool.Name .. " — click to put it back!"
	)
end

function PickupService.init(deps: { remotes: Folder })
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	PlotManager.setPickupHandler(onPickup)
	Players.PlayerRemoving:Connect(putBack)
end

return PickupService
