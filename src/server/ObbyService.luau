--!strict
-- Obby "Glizzy Run" (additions #14) — the waiting-time activity. A parkour course
-- at the street's WEST end (the podium bookends the east): touch Start, clear the
-- checkpoints IN ORDER, reach the Finish, and earn ObbyRewardSeconds' worth of
-- YOUR OWN income/sec (dogs + stove, multipliers included) — so the payout scales
-- forever and the obby never goes obsolete. Repeatable on a per-player cooldown
-- (data.obbyReadyAt, persisted).
--
-- Server-authoritative + anti-teleport: the server owns every pad's Touched, the
-- checkpoint order, a minimum-elapsed floor (ObbyMinRunSeconds), and the cooldown.
-- There are no remotes — feedback rides the shared StealFeedback toast channel.
-- Falling never kills (the course hangs low over grass); walk back and re-touch
-- Start to restart.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Theme = require(ReplicatedStorage.Shared.Theme)
local DataManager = require(ServerScriptService.Server.DataManager)
local Telemetry = require(ServerScriptService.Server.Telemetry)

local ObbyService = {}

local remFeedback: RemoteEvent
local remCelebrate: RemoteEvent
local updateLeaderstats: (player: Player) -> ()
-- Main hands us its income math (the grantFreeCook closure pattern): coins/sec =
-- (dog income + stove) × the full income multiplier for that player, right now.
local computeIncome: (player: Player) -> number

type Session = { startedAt: number, nextCheckpoint: number }
local sessions: { [number]: Session } = {}
-- Per-player, per-pad touch debounce (pads fire Touched in bursts).
local nextTouchAllowed: { [number]: number } = {}

Players.PlayerRemoving:Connect(function(player)
	sessions[player.UserId] = nil
	nextTouchAllowed[player.UserId] = nil
end)

local CHECKPOINT_COUNT = 2

local function feedback(player: Player, ok: boolean, message: string)
	remFeedback:FireClient(player, ok, message)
end

local function debounced(player: Player): boolean
	local now = os.clock()
	if now < (nextTouchAllowed[player.UserId] or 0) then
		return true
	end
	nextTouchAllowed[player.UserId] = now + 1
	return false
end

local function playerFromHit(hit: BasePart): Player?
	local character = hit.Parent
	return character and Players:GetPlayerFromCharacter(character)
end

-- === Course geometry ===
-- Start plaza at x = -650 (past the street's west end at -620), running WEST to
-- the finish at ~-758. Platforms hang LOW over grass: falling costs a walk-back,
-- never a respawn.
local function makePart(props: { [string]: any }): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = true
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(part :: any)[k] = v
	end
	return part
end

local function makeSign(parent: BasePart, text: string, color: Color3, wide: number)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(wide, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 120
	bb.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Theme.UI.TitleFont
	label.Text = text
	label.Parent = bb
end

local function onStartTouched(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local now = os.time()
	if now < data.obbyReadyAt then
		feedback(
			player,
			false,
			"🏃 Glizzy Run recharging — back in " .. (data.obbyReadyAt - now) .. "s."
		)
		return
	end
	sessions[player.UserId] = { startedAt = os.clock(), nextCheckpoint = 1 }
	feedback(player, true, "🏃 Glizzy Run started — GO!")
end

local function onCheckpointTouched(player: Player, index: number)
	local session = sessions[player.UserId]
	if not session or session.nextCheckpoint ~= index then
		return
	end
	session.nextCheckpoint = index + 1
	feedback(player, true, "🚩 Checkpoint " .. index .. "/" .. CHECKPOINT_COUNT .. "!")
end

local function onFinishTouched(player: Player, finishPad: BasePart)
	local session = sessions[player.UserId]
	local data = DataManager.get(player)
	if not (session and data) then
		return
	end
	if session.nextCheckpoint <= CHECKPOINT_COUNT then
		feedback(player, false, "🚩 Hit every checkpoint in order first!")
		return
	end
	local elapsed = os.clock() - session.startedAt
	if elapsed < GameConfig.ObbyMinRunSeconds then
		-- Faster than a legit run = teleport/fly cheese. Restart from Start.
		sessions[player.UserId] = nil
		feedback(player, false, "That run didn't count — start again from the Start pad!")
		return
	end
	if os.time() < data.obbyReadyAt then
		sessions[player.UserId] = nil
		return
	end
	sessions[player.UserId] = nil

	-- The reward: ObbyRewardSeconds' worth of THIS player's income, right now.
	local reward = math.max(1, math.floor(GameConfig.ObbyRewardSeconds * computeIncome(player)))
	data.coins += reward
	data.obbyReadyAt = os.time() + GameConfig.ObbyCooldownSeconds
	updateLeaderstats(player)
	Telemetry.event("ObbyComplete")
	remCelebrate:FireAllClients("purchase", finishPad)
	feedback(
		player,
		true,
		"🏁 Glizzy Run complete! +" .. Format.comma(reward) .. " coins (100s of income)."
	)
end

local function buildCourse()
	local existing = Workspace:FindFirstChild("GlizzyRun")
	if existing then
		existing:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "GlizzyRun"

	-- Start plaza.
	local startPad = makePart({
		Name = "ObbyStart",
		Size = Vector3.new(10, 1, 10),
		Color = Theme.Semantic.Affordable,
		CFrame = CFrame.new(-650, 0.9, 0),
	})
	startPad.Parent = model
	makeSign(
		startPad,
		"🏃 GLIZZY RUN — earn 100s of income!",
		Color3.fromRGB(190, 255, 200),
		220
	)
	startPad.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if player and not debounced(player) then
			onStartTouched(player)
		end
	end)

	-- Jump platforms: { dx west of start, y, z }. Rises ≤1.5, gaps ~7-8 studs —
	-- an easy-medium ~35-second course (ObbyMinRunSeconds sits safely under it).
	local hops: { { number } } = {
		{ 10, 2, 3 },
		{ 18, 3, -3 },
		{ 26, 4, 3 },
		{ 34, 5, -2 },
		-- checkpoint 1 sits at dx 42
		{ 50, 6.5, 3 },
		{ 57, 8, -3 },
		{ 64, 9, 2 },
		{ 71, 10, -2 },
		-- checkpoint 2 sits at dx 78
		{ 86, 11, 3 },
		{ 93, 12, -3 },
		{ 100, 12.5, 2 },
	}
	for i, hop in hops do
		local platform = makePart({
			Name = "ObbyHop" .. i,
			Size = Vector3.new(4, 1, 4),
			Color = if i % 2 == 1 then Theme.Palette.Ketchup else Theme.Palette.Cream,
			CFrame = CFrame.new(-650 - hop[1], hop[2], hop[3]),
		})
		platform.Parent = model
	end

	local checkpoints: { { dx: number, y: number } } = {
		{ dx = 42, y = 5.4 },
		{ dx = 78, y = 10.4 },
	}
	for i, spec in checkpoints do
		local pad = makePart({
			Name = "ObbyCheckpoint" .. i,
			Size = Vector3.new(6, 1, 6),
			Color = Theme.Palette.Mustard,
			CFrame = CFrame.new(-650 - spec.dx, spec.y, 0),
		})
		pad.Parent = model
		makeSign(pad, "🚩 Checkpoint " .. i, Color3.fromRGB(255, 240, 170), 130)
		pad.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player then
				onCheckpointTouched(player, i)
			end
		end)
	end

	local finishPad = makePart({
		Name = "ObbyFinish",
		Size = Vector3.new(10, 1, 10),
		Color = Theme.Palette.VaultGold,
		CFrame = CFrame.new(-758, 13, 0),
	})
	finishPad.Parent = model
	makeSign(finishPad, "🏁 FINISH", Color3.fromRGB(255, 230, 140), 110)
	finishPad.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if player and not debounced(player) then
			onFinishTouched(player, finishPad)
		end
	end)

	model.Parent = Workspace
end

function ObbyService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	computeIncome: (player: Player) -> number,
})
	updateLeaderstats = deps.updateLeaderstats
	computeIncome = deps.computeIncome
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remCelebrate = deps.remotes:WaitForChild("Celebrate") :: RemoteEvent
	buildCourse()
end

return ObbyService
