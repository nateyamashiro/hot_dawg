--!strict
-- Progression menu (items 5 & 6). A bottom-row toggle for Upgrades (grill / display
-- slots / vault slots) and Rebirth. Untrusted UI: it only displays the server-pushed
-- levels and fires BuyUpgrade / Rebirth requests; the server validates + charges.
-- Cost curves are read from the shared GameConfig so labels stay in sync.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyUpgrade = remotes:WaitForChild("BuyUpgrade") :: RemoteEvent
local rebirth = remotes:WaitForChild("Rebirth") :: RemoteEvent
local progressionUpdate = remotes:WaitForChild("ProgressionUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

-- Latest server-pushed progression snapshot.
type Progression = {
	grillLvl: number,
	displaySlotsLvl: number,
	vaultSlotsLvl: number,
	rebirths: number,
	prestige: number,
}
local prog: Progression =
	{ grillLvl = 1, displaySlotsLvl = 1, vaultSlotsLvl = 1, rebirths = 0, prestige = 0 }

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- === Bottom menu row: buttons at fixed slots (Dex + Daily own their own slots) ===
local BUTTON_W = 140
local SPACING = 150
local ROW_START_X = -295 -- centers a 4-slot row (Upgrades, Rebirth, Dex, Daily)

local function makeMenuButton(slot: number, text: string): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(BUTTON_W, 40)
	btn.Position = UDim2.new(0.5, ROW_START_X + slot * SPACING, 1, -150)
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.Parent = gui
	return btn
end

-- Simple centered panel with a title + a content area, hidden by default.
local function makePanel(title: string): (Frame, Frame)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(440, 320)
	frame.Position = UDim2.new(0.5, -220, 0.5, -160)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	frame.BackgroundTransparency = 0.05
	frame.Visible = false
	frame.Parent = gui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 0, 44)
	titleLabel.Position = UDim2.fromOffset(12, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 230, 150)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = title
	titleLabel.Parent = frame

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -42, 0, 10)
	close.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextScaled = true
	close.Font = Enum.Font.GothamBold
	close.Text = "✕"
	close.Parent = frame
	close.Activated:Connect(function()
		frame.Visible = false
	end)

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -24, 1, -64)
	content.Position = UDim2.fromOffset(12, 56)
	content.BackgroundTransparency = 1
	content.Parent = frame

	return frame, content
end

-- === Upgrades panel ===
local upgradesBtn = makeMenuButton(0, "🛒 Upgrades")
local upgradesPanel, upgradesContent = makePanel("🛒 Upgrades")

type UpgradeRow = { which: string, label: string, levels: { { cost: number } } }
local UPGRADE_ROWS: { UpgradeRow } = {
	{ which = "grill", label = "🔥 Grill", levels = GameConfig.GrillLevels },
	{ which = "display", label = "🅿️ Display Slots", levels = GameConfig.DisplaySlotLevels },
	{ which = "vault", label = "🔒 Vault Slots", levels = GameConfig.VaultSlotLevels },
}

local function currentLevel(which: string): number
	if which == "grill" then
		return prog.grillLvl
	elseif which == "display" then
		return prog.displaySlotsLvl
	else
		return prog.vaultSlotsLvl
	end
end

local upgradeLabels: { [string]: TextLabel } = {}
for i, row in UPGRADE_ROWS do
	local y = (i - 1) * 84

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, 0, 0, 40)
	info.Position = UDim2.fromOffset(0, y)
	info.BackgroundTransparency = 1
	info.TextColor3 = Color3.fromRGB(240, 240, 240)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextScaled = true
	info.Font = Enum.Font.GothamBold
	info.Text = row.label
	info.Parent = upgradesContent
	upgradeLabels[row.which] = info

	local buy = Instance.new("TextButton")
	buy.Size = UDim2.fromOffset(180, 36)
	buy.Position = UDim2.fromOffset(0, y + 40)
	buy.BackgroundColor3 = Color3.fromRGB(60, 140, 80)
	buy.TextColor3 = Color3.fromRGB(255, 255, 255)
	buy.TextScaled = true
	buy.Font = Enum.Font.GothamBold
	buy.Text = "Buy"
	buy.Parent = upgradesContent
	buy.Activated:Connect(function()
		buyUpgrade:FireServer(row.which)
	end)
end

local function refreshUpgrades()
	for _, row in UPGRADE_ROWS do
		local lvl = currentLevel(row.which)
		local nextDef = row.levels[lvl + 1]
		local label = upgradeLabels[row.which]
		if nextDef then
			label.Text =
				string.format("%s — Lv %d → Next: 💰%d", row.label, lvl, nextDef.cost)
		else
			label.Text = string.format("%s — Lv %d (MAX)", row.label, lvl)
		end
	end
end

upgradesBtn.Activated:Connect(function()
	upgradesPanel.Visible = not upgradesPanel.Visible
	refreshUpgrades()
end)

-- === Rebirth panel ===
local rebirthBtn = makeMenuButton(1, "✨ Rebirth")
local rebirthPanel, rebirthContent = makePanel("✨ Rebirth")

local function rebirthCost(rebirths: number): number
	return math.floor(GameConfig.RebirthBaseCost * GameConfig.RebirthCostGrowth ^ rebirths)
end

local rebirthInfo = Instance.new("TextLabel")
rebirthInfo.Size = UDim2.new(1, 0, 0, 140)
rebirthInfo.BackgroundTransparency = 1
rebirthInfo.TextColor3 = Color3.fromRGB(240, 240, 240)
rebirthInfo.TextXAlignment = Enum.TextXAlignment.Left
rebirthInfo.TextYAlignment = Enum.TextYAlignment.Top
rebirthInfo.TextSize = 18
rebirthInfo.Font = Enum.Font.Gotham
rebirthInfo.Text = ""
rebirthInfo.Parent = rebirthContent

local rebirthDo = Instance.new("TextButton")
rebirthDo.Size = UDim2.fromOffset(220, 44)
rebirthDo.Position = UDim2.fromOffset(0, 150)
rebirthDo.BackgroundColor3 = Color3.fromRGB(150, 90, 200)
rebirthDo.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthDo.TextScaled = true
rebirthDo.Font = Enum.Font.GothamBold
rebirthDo.Text = "✨ Rebirth"
rebirthDo.Parent = rebirthContent
rebirthDo.Activated:Connect(function()
	rebirth:FireServer()
end)

local function refreshRebirth()
	local cost = rebirthCost(prog.rebirths)
	local curBonus = math.floor(prog.rebirths * GameConfig.RebirthIncomeBonus * 100)
	local nextBonus = math.floor((prog.rebirths + 1) * GameConfig.RebirthIncomeBonus * 100)
	rebirthInfo.Text = string.format(
		"Rebirths: %d   (Prestige: %d)\nCurrent income bonus: +%d%%\n\nRebirth resets your coins but KEEPS every hot dog + upgrade, and permanently boosts income to +%d%%.\n\nCost: 💰%d coins",
		prog.rebirths,
		prog.prestige,
		curBonus,
		nextBonus,
		cost
	)
end

rebirthBtn.Activated:Connect(function()
	rebirthPanel.Visible = not rebirthPanel.Visible
	refreshRebirth()
end)

-- === Server pushes ===
progressionUpdate.OnClientEvent:Connect(function(snapshot: Progression)
	prog = snapshot
	refreshUpgrades()
	refreshRebirth()
end)

gui.Parent = player:WaitForChild("PlayerGui")
requestState:FireServer() -- request initial progression now that we're listening
