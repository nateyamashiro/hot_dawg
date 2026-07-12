--!strict
-- Client UI. Runs on each player's device. This side is NOT trusted with any
-- economy logic — it shows the current values and sends "please cook" requests
-- to the server, then reveals whatever the server rolled. The whole UI is built
-- in code so there's nothing to place by hand in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GlizzyModel = require(ReplicatedStorage.Shared.GlizzyModel)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local Sfx = require(ReplicatedStorage.Shared.Sfx)
local Variants = require(ReplicatedStorage.Shared.Variants)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local cookHotDog = remotes:WaitForChild("CookHotDog") :: RemoteEvent
local cookResult = remotes:WaitForChild("CookResult") :: RemoteEvent
local cookTen = remotes:WaitForChild("CookTen") :: RemoteEvent
local cookTenResult = remotes:WaitForChild("CookTenResult") :: RemoteEvent
local cookStats = remotes:WaitForChild("CookStats") :: RemoteEvent
local storageUpdate = remotes:WaitForChild("StorageUpdate") :: RemoteEvent
local welcomeBack = remotes:WaitForChild("WelcomeBack") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

-- The server creates leaderstats for us; wait for it and its values.
local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins") :: IntValue
local dogs = leaderstats:WaitForChild("Dogs") :: IntValue

-- === Build the UI ===
local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyUI"
gui.ResetOnSpawn = false

-- Stats readout (coins + storage fullness — additions #9/#13).
local stats = Instance.new("TextLabel")
stats.Size = UDim2.fromOffset(300, 48)
stats.Position = UDim2.fromOffset(20, 20)
stats.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
stats.BackgroundTransparency = 0.3
stats.TextColor3 = Color3.fromRGB(255, 255, 255)
stats.TextScaled = true
stats.Font = Enum.Font.GothamBold
stats.Parent = gui

-- Cook button. The single cook is FREE but cooldown-gated (additions #5): the label
-- counts down and the button glows + toasts + plays CookReady when the wait ends.
local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(260, 50)
button.Position = UDim2.fromOffset(20, 76)
button.BackgroundColor3 = Color3.fromRGB(220, 120, 40)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Text = "🌭 Cook"
button.Parent = gui
local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(150, 255, 160)
buttonStroke.Thickness = 0
buttonStroke.Parent = button

-- Cook-10 button.
local buttonTen = Instance.new("TextButton")
buttonTen.Size = UDim2.fromOffset(260, 40)
buttonTen.Position = UDim2.fromOffset(20, 130)
buttonTen.BackgroundColor3 = Color3.fromRGB(180, 90, 30)
buttonTen.TextColor3 = Color3.fromRGB(255, 255, 255)
buttonTen.TextScaled = true
buttonTen.Font = Enum.Font.GothamBold
buttonTen.Text = string.format(
	"🍳 Cook ×%d (%s)",
	GameConfig.CookTenCount,
	Format.comma(GameConfig.CookCost * GameConfig.CookTenCount)
)
buttonTen.Parent = gui

-- Reveal label: shows the last hot dog(s) you cooked, coloured by rarity.
local reveal = Instance.new("TextLabel")
reveal.Size = UDim2.fromOffset(260, 40)
reveal.Position = UDim2.fromOffset(20, 176)
reveal.BackgroundTransparency = 1
reveal.TextColor3 = Color3.fromRGB(255, 255, 255)
reveal.TextTransparency = 1
reveal.TextScaled = true
reveal.Font = Enum.Font.GothamBlack
reveal.Text = ""
reveal.Parent = gui

-- Disclosed odds + pity progress (static info panel; coin-only gacha so we show all).
local oddsLabel = Instance.new("TextLabel")
oddsLabel.Size = UDim2.fromOffset(260, 168)
oddsLabel.Position = UDim2.fromOffset(20, 220)
oddsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
oddsLabel.BackgroundTransparency = 0.45
oddsLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
oddsLabel.TextXAlignment = Enum.TextXAlignment.Left
oddsLabel.TextYAlignment = Enum.TextYAlignment.Top
oddsLabel.TextSize = 14
oddsLabel.Font = Enum.Font.Gotham
oddsLabel.Text = "🎲 Drop rates loading…"
oddsLabel.Parent = gui

-- Welcome-back (offline earnings) popup, top-center.
local welcome = Instance.new("TextLabel")
welcome.Size = UDim2.fromOffset(520, 44)
welcome.Position = UDim2.new(0.5, -260, 0, 20)
welcome.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
welcome.BackgroundTransparency = 0.1
welcome.TextColor3 = Color3.fromRGB(240, 255, 240)
welcome.TextScaled = true
welcome.Font = Enum.Font.GothamBold
welcome.Text = ""
welcome.Visible = false
welcome.Parent = gui

-- Storage fullness (additions #9): the server pushes shown/capacity for display +
-- vault; until it arrives the plain dog count renders.
type StorageInfo = { shown: number, displayCap: number, vaultUsed: number, vaultCap: number }
local lastStorage: StorageInfo? = nil

local function refreshStats()
	local storage = lastStorage
	local dogsText = if storage
		then string.format(
			"🌭 %d/%d  🔒 %d/%d",
			storage.shown,
			storage.displayCap,
			storage.vaultUsed,
			storage.vaultCap
		)
		else "🌭 " .. Format.comma(dogs.Value)
	stats.Text = "💰 " .. Format.comma(coins.Value) .. "   " .. dogsText
end

coins.Changed:Connect(refreshStats)
dogs.Changed:Connect(refreshStats)
refreshStats()
storageUpdate.OnClientEvent:Connect(function(storage: StorageInfo)
	lastStorage = storage
	refreshStats()
end)

button.Activated:Connect(function()
	cookHotDog:FireServer()
end)
buttonTen.Activated:Connect(function()
	cookTen:FireServer()
end)

-- Show a reveal string, then fade it out.
local function showReveal(text: string, color: Color3)
	reveal.Text = text
	reveal.TextColor3 = color
	reveal.TextTransparency = 0
	TweenService:Create(
		reveal,
		TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.8),
		{ TextTransparency = 1 }
	):Play()
end

-- Cook-reveal viewport (P-C): the freshly rolled glizzy spins under the odds panel
-- for a couple of seconds. Client-side only — GlizzyModel is shared, so the preview
-- is built locally from the same recipe as the real pedestal unit.
local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.fromOffset(260, 140)
viewport.Position = UDim2.fromOffset(20, 392)
viewport.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
viewport.BackgroundTransparency = 0.35
viewport.Visible = false
viewport.Parent = gui
local vpCamera = Instance.new("Camera")
vpCamera.Parent = viewport
viewport.CurrentCamera = vpCamera
vpCamera.CFrame = CFrame.new(Vector3.new(0, 1.4, 5), Vector3.new(0, 0, 0))

local spinToken = 0
local function showRevealModel(name: string, rarity: HotDogDex.Rarity, variant: string)
	spinToken += 1
	local myToken = spinToken
	for _, child in viewport:GetChildren() do
		if child:IsA("Model") then
			child:Destroy()
		end
	end
	local model = GlizzyModel.build(name, {
		rarity = rarity,
		variant = variant,
		anchored = true,
		fx = false, -- emitters don't read in a tiny viewport; the model is the star
	})
	model.Name = "RevealDog" -- not "DogUnit": keep GlizzyFx/steal code away from it
	model.Parent = viewport
	viewport.Visible = true
	task.spawn(function()
		local t0 = os.clock()
		while spinToken == myToken and os.clock() - t0 < 2.2 do
			model:PivotTo(CFrame.Angles(0, (os.clock() - t0) * 2.5, 0))
			task.wait()
		end
		if spinToken == myToken then
			viewport.Visible = false
		end
	end)
end

cookResult.OnClientEvent:Connect(
	function(name: string, rarity: HotDogDex.Rarity, variant: Variants.Variant?)
		local v = variant or "base"
		local def = Variants.def(v)
		if def and v ~= "base" then
			-- Mutation: bigger, variant-coloured reveal to sell the rare pull.
			showReveal(string.format("✨ %s %s! [%s]", def.label, name, rarity), def.color)
		else
			showReveal(string.format("%s  [%s]", name, rarity), HotDogDex.colorFor(rarity))
		end
		showRevealModel(name, rarity, v)
	end
)

-- Summarize a 10-roll as "3× Common, 2× Rare…", coloured by the best pull.
local RARITY_ORDER: { HotDogDex.Rarity } =
	{ "Forbidden", "Secret", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }
cookTenResult.OnClientEvent:Connect(
	function(results: { { name: string, rarity: HotDogDex.Rarity, variant: Variants.Variant? } })
		local counts: { [string]: number } = {}
		local mutations = 0
		for _, r in results do
			counts[r.rarity] = (counts[r.rarity] or 0) + 1
			if r.variant and r.variant ~= "base" then
				mutations += 1
			end
		end
		local parts: { string } = {}
		local best: HotDogDex.Rarity? = nil
		for _, rar in RARITY_ORDER do
			if counts[rar] then
				table.insert(parts, string.format("%d× %s", counts[rar], rar))
				if not best then
					best = rar
				end
			end
		end
		local summary = "🍳 " .. table.concat(parts, ", ")
		if mutations > 0 then
			summary ..= string.format(
				"  ✨ %d mutation%s!",
				mutations,
				if mutations == 1 then "" else "s"
			)
		end
		showReveal(summary, HotDogDex.colorFor(best or "Common"))
	end
)

-- Rebuild the odds + pity readout for the current grill level.
local function refreshOdds(grillLvl: number, cooksSinceRare: number, pityMax: number)
	local lines = { string.format("🎲 Drop rates — Grill Lv %d", grillLvl) }
	for _, o in HotDogDex.odds(grillLvl) do
		table.insert(lines, string.format("%s   %.2f%%", o.rarity, o.chance * 100))
	end
	table.insert(lines, string.format("⏳ Pity: %d/%d cooks → Rare+", cooksSinceRare, pityMax))
	oddsLabel.Text = table.concat(lines, "\n")
end
refreshOdds(1, 0, GameConfig.PityCooks)

-- === Free-cook cooldown countdown + "ready!" notification (additions #5) ===
-- The server sends seconds-remaining on CookStats; the client keeps a local deadline
-- and renders the button state. On the not-ready → ready transition: glow pulse +
-- toast + CookReady sound (silence-safe until Nate fills the id).
local COOK_READY_COLOR = Color3.fromRGB(70, 175, 80)
local COOK_WAIT_COLOR = Color3.fromRGB(125, 125, 125)
local cookDeadline = 0 -- os.clock() when the free cook unlocks
local cookWasReady = true -- true so a join that's already ready doesn't notify

local function updateCookButton()
	local remaining = math.ceil(cookDeadline - os.clock())
	if remaining > 0 then
		button.Text = "🌭 Cook (" .. remaining .. "s)"
		button.BackgroundColor3 = COOK_WAIT_COLOR
		buttonStroke.Thickness = 0
		cookWasReady = false
	else
		button.Text = "🌭 Cook — FREE!"
		button.BackgroundColor3 = COOK_READY_COLOR
		if not cookWasReady then
			cookWasReady = true
			buttonStroke.Thickness = 4
			buttonStroke.Transparency = 0
			TweenService:Create(
				button,
				TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ BackgroundColor3 = COOK_READY_COLOR }
			):Play()
			showReveal("🌭 Glizzy ready to cook!", COOK_READY_COLOR)
			Sfx.play("CookReady")
		end
	end
end

task.spawn(function()
	while true do
		updateCookButton()
		task.wait(0.5)
	end
end)

cookStats.OnClientEvent:Connect(
	function(grillLvl: number, cooksSinceRare: number, pityMax: number, cookRemaining: number?)
		refreshOdds(grillLvl, cooksSinceRare, pityMax)
		if type(cookRemaining) == "number" then
			cookDeadline = os.clock() + cookRemaining
			if cookRemaining > 0 then
				cookWasReady = false
			end
			updateCookButton()
		end
	end
)

-- Offline earnings popup.
local welcomeToken = 0
welcomeBack.OnClientEvent:Connect(function(earned: number, elapsed: number)
	local mins = math.floor(elapsed / 60)
	local timeStr = if mins >= 60
		then string.format("%dh %dm", math.floor(mins / 60), mins % 60)
		else string.format("%dm", mins)
	welcome.Text =
		string.format("👋 Welcome back! +💰%s while away (%s)", Format.comma(earned), timeStr)
	welcome.Visible = true
	welcomeToken += 1
	local myToken = welcomeToken
	task.delay(6, function()
		if myToken == welcomeToken then
			welcome.Visible = false
		end
	end)
end)

gui.Parent = player:WaitForChild("PlayerGui")

-- Handlers are connected; ask the server to (re)send our state so nothing is lost
-- to the join race.
requestState:FireServer()
