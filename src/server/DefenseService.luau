--!strict
-- Defense side of the loop. Three pieces (GDD §4.1):
--   * Net tool  — everyone gets one; activate near a carrying thief to stun + drop.
--   * Wall      — buyable; lengthens the steal hold-time on your stand.
--   * NPC guard — buyable; auto-nets carrying thieves on your plot even while away.
-- Purchases mutate coins server-side; StealService owns the actual carry/drop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
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

-- === Wall ===
local function buildWall(plot: PlotManager.Plot)
	local wall = Instance.new("Model")
	wall.Name = "Wall"
	-- A low fence across the front of the pedestals.
	local fence = Instance.new("Part")
	fence.Anchored = true
	fence.CanCollide = true
	fence.Size = Vector3.new(24, 4, 1)
	fence.Color = Color3.fromRGB(90, 90, 110)
	fence.Material = Enum.Material.Metal
	fence.CFrame = plot.facing * CFrame.new(0, 2, 5)
	fence.Parent = wall
	wall.Parent = plot.model
	plot.wallModel = wall
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

-- Re-apply defenses a player already owns (called after their plot is assigned).
function DefenseService.applyLoadedDefenses(player: Player)
	local data = DataManager.get(player)
	local plot = PlotManager.getPlotByOwner(player)
	if not (data and plot) then
		return
	end
	if data.defenses.wall then
		buildWall(plot)
		PlotManager.setStealHoldBonus(player, GameConfig.WallHoldBonusSeconds)
	end
	if data.defenses.guard then
		buildGuard(plot)
	end
end

-- === Purchases ===
local function onBuyDefense(player: Player, which: string)
	local data = DataManager.get(player)
	local plot = PlotManager.getPlotByOwner(player)
	if not (data and plot) then
		return
	end

	if which == "wall" then
		if data.defenses.wall then
			feedback(player, false, "You already have a wall.")
			return
		end
		if data.coins < GameConfig.WallCost then
			feedback(player, false, "Not enough coins for a wall.")
			return
		end
		data.coins -= GameConfig.WallCost
		data.defenses.wall = true
		buildWall(plot)
		PlotManager.setStealHoldBonus(player, GameConfig.WallHoldBonusSeconds)
		updateLeaderstats(player)
		feedback(player, true, "Wall built! Thieves take longer to steal.")
	elseif which == "guard" then
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
	end
end

function DefenseService.init(deps: { remotes: Folder, updateLeaderstats: (player: Player) -> () })
	updateLeaderstats = deps.updateLeaderstats
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuyDefense = deps.remotes:WaitForChild("BuyDefense") :: RemoteEvent
	remBuyDefense.OnServerEvent:Connect(function(player, which)
		if type(which) == "string" then
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
