--!strict
-- Defense side of the loop. Three pieces (GDD §4.1):
--   * Net tool  — everyone gets one; activate near a carrying thief to stun + drop.
--   * NPC guard — buyable; auto-nets carrying thieves on your plot even while away.
--   * Trap      — buyable; stuns a carrier who lingers on the plot.
-- Purchases mutate coins server-side; StealService owns the actual carry/drop.
-- (The old buyable wall moved to the BuildCatalog perimeter wall — BuildService owns
-- it now; old wall owners are grandfathered `built.wall` in DataManager.load.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local StealService = require(ServerScriptService.Server.StealService)

local DefenseService = {}

local updateLeaderstats: (player: Player) -> ()
-- Resolved in init(); held as locals so no statement starts with `(` (which Lua
-- would otherwise parse as a call on the previous line).
local remFeedback: RemoteEvent
local remBuyDefense: RemoteEvent

-- === Helpers ===
local function feedback(player: Player, ok: boolean, message: string)
	remFeedback:FireClient(player, ok, message)
end

local function rootOf(player: Player): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Nearest carrying thief within `range` of `pos`, excluding `exclude`.
local function nearestCarrierNear(pos: Vector3, range: number, exclude: Player?): Player?
	local best: Player? = nil
	local bestDist = range
	for _, player in Players:GetPlayers() do
		if player ~= exclude and StealService.isCarrying(player) then
			local root = rootOf(player)
			if root then
				local dist = (root.Position - pos).Magnitude
				if dist <= bestDist then
					best = player
					bestDist = dist
				end
			end
		end
	end
	return best
end

-- Stun a player: freeze them for `seconds`, then restore normal speed.
function DefenseService.stun(player: Player, seconds: number)
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.Jump = false
	task.delay(seconds, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = GameConfig.NormalWalkSpeed
			humanoid.JumpPower = 50
		end
	end)
end

-- Net a carrier: drop their loot (returns to victim) and stun them.
local function netCarrier(carrier: Player, netter: Player?)
	StealService.dropCarry(carrier)
	DefenseService.stun(carrier, GameConfig.NetStunSeconds)
	remFeedback:FireClient(carrier, false, "You got netted!")
	if netter then
		feedback(netter, true, "Netted " .. carrier.DisplayName .. "!")
	end
end

-- === Net tool ===
local function onNetActivated(activator: Player)
	local root = rootOf(activator)
	if not root then
		return
	end
	local carrier = nearestCarrierNear(root.Position, GameConfig.NetRange, activator)
	if carrier then
		netCarrier(carrier, activator)
	end
end

local function giveNet(player: Player, char: Model)
	local tool = Instance.new("Tool")
	tool.Name = "Net"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Net a carrying thief to make them drop!"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 4, 1)
	handle.Color = Color3.fromRGB(230, 230, 240)
	handle.Parent = tool

	tool.Activated:Connect(function()
		onNetActivated(player)
	end)

	tool.Parent = player:FindFirstChildOfClass("Backpack") or char
end

-- === Guard ===
local function buildGuard(plot: PlotManager.Plot)
	local guard = Instance.new("Model")
	guard.Name = "Guard"
	local torso = Instance.new("Part")
	torso.Anchored = true
	torso.CanCollide = false
	torso.Size = Vector3.new(2, 3, 1)
	torso.Color = Color3.fromRGB(40, 60, 120)
	torso.CFrame = plot.facing * CFrame.new(9, 2, 4)
	torso.Parent = guard
	local head = Instance.new("Part")
	head.Anchored = true
	head.CanCollide = false
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = Color3.fromRGB(240, 210, 170)
	head.CFrame = torso.CFrame * CFrame.new(0, 2.2, 0)
	head.Parent = guard

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 40)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(180, 210, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = "🛡️ Guard"
	label.Parent = bb

	guard.Parent = plot.model
	plot.guardModel = guard

	-- Scan loop: auto-net carrying thieves near the plot (works while owner is away).
	task.spawn(function()
		while plot.guardModel == guard and guard.Parent do
			task.wait(GameConfig.GuardScanSeconds)
			local owner = plot.owner
			local carrier = nearestCarrierNear(plot.center, 22, owner)
			if carrier then
				netCarrier(carrier, nil)
			end
		end
	end)
end

-- === Trap (M2 fast-follow / 4th defense) ===
-- A placeable stun pad: a carrier who lingers on the plot gets stunned + dropped.
-- Reuses the net/stun path. Cheaper than a guard but only fires on the plot itself.
local function buildTrap(plot: PlotManager.Plot)
	local trap = Instance.new("Model")
	trap.Name = "Trap"
	local pad = Instance.new("Part")
	pad.Anchored = true
	pad.CanCollide = false
	pad.Size = Vector3.new(8, 0.4, 8)
	pad.Color = Color3.fromRGB(200, 60, 60)
	pad.Material = Enum.Material.Neon
	pad.Transparency = 0.4
	pad.CFrame = plot.facing * CFrame.new(0, 0.3, 1)
	pad.Parent = trap
	trap.Parent = plot.model
	plot.trapModel = trap

	-- Scan loop: stun a carrier standing on the trap (works while owner is away).
	-- TODO(M2-trap): use a Touched signal + a per-carrier re-arm cooldown instead of
	-- a poll, and a visual "armed/triggered" state.
	task.spawn(function()
		while plot.trapModel == trap and trap.Parent do
			task.wait(GameConfig.GuardScanSeconds)
			local carrier = nearestCarrierNear(pad.Position, GameConfig.TrapRange, plot.owner)
			if carrier then
				StealService.dropCarry(carrier)
				DefenseService.stun(carrier, GameConfig.TrapStunSeconds)
				remFeedback:FireClient(carrier, false, "You hit a trap!")
			end
		end
	end)
end

-- Re-apply defenses a player already owns (called after their plot is assigned).
function DefenseService.applyLoadedDefenses(player: Player)
	local data = DataManager.get(player)
	local plot = PlotManager.getPlotByOwner(player)
	if not (data and plot) then
		return
	end
	if data.defenses.guard then
		buildGuard(plot)
	end
	if data.defenses.trap then
		buildTrap(plot)
	end
end

-- === Purchases ===
local function onBuyDefense(player: Player, which: string)
	local data = DataManager.get(player)
	local plot = PlotManager.getPlotByOwner(player)
	if not (data and plot) then
		return
	end

	if which == "guard" then
		if data.defenses.guard then
			feedback(player, false, "You already have a guard.")
			return
		end
		if data.coins < GameConfig.GuardCost then
			feedback(player, false, "Not enough coins for a guard.")
			return
		end
		data.coins -= GameConfig.GuardCost
		data.defenses.guard = true
		buildGuard(plot)
		updateLeaderstats(player)
		feedback(player, true, "Guard hired! They'll net raiders for you.")
	elseif which == "trap" then
		if data.defenses.trap then
			feedback(player, false, "You already have a trap.")
			return
		end
		if data.coins < GameConfig.TrapCost then
			feedback(player, false, "Not enough coins for a trap.")
			return
		end
		data.coins -= GameConfig.TrapCost
		data.defenses.trap = true
		buildTrap(plot)
		updateLeaderstats(player)
		feedback(player, true, "Trap set! Raiders who linger get zapped.")
	end
end

function DefenseService.init(deps: { remotes: Folder, updateLeaderstats: (player: Player) -> () })
	updateLeaderstats = deps.updateLeaderstats
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuyDefense = deps.remotes:WaitForChild("BuyDefense") :: RemoteEvent
	remBuyDefense.OnServerEvent:Connect(function(player, which)
		if not RateLimit.check(player, "BuyDefense", 5) then
			return
		end
		if type(which) == "string" and #which <= 32 then
			onBuyDefense(player, which)
		end
	end)

	-- Give everyone a Net, covering future spawns and any already-present player
	-- (e.g. a Studio solo tester who joined before this script ran).
	local function setupNet(player: Player)
		player.CharacterAdded:Connect(function(char)
			giveNet(player, char)
		end)
		if player.Character then
			giveNet(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(setupNet)
	for _, player in Players:GetPlayers() do
		setupNet(player)
	end
end

return DefenseService
