--!strict
-- Progression menu (items 5 & 6). A bottom-row toggle for Upgrades (grill / display
-- slots / vault slots) and Rebirth. Untrusted UI: it only displays the server-pushed
-- levels and fires BuyUpgrade / Rebirth requests; the server validates + charges.
-- Cost curves are read from the shared GameConfig so labels stay in sync.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

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

-- === Upgrades window (P-D: themed MenuLayout window; the old dark-slate panel is
-- gone — this menu stays as the fallback beside the walk-on pads). ===
local upgradesBtn = MenuLayout.makePrimaryButton(gui, "Upgrades", "🛒 Upgrades")
local upgradesPanel, upgradesContent = MenuLayout.makeWindow(gui, "🛒 Upgrades")

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
	-- One row card per upgrade track (the window content is a UIListLayout column).
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, 88)
	card.LayoutOrder = i
	card.BackgroundColor3 = MenuLayout.RowBg
	card.Parent = upgradesContent
	MenuLayout.addChrome(card, 8)

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -16, 0, 40)
	info.Position = UDim2.fromOffset(8, 4)
	info.BackgroundTransparency = 1
	info.TextColor3 = MenuLayout.BodyText
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextScaled = true
	info.Font = Enum.Font.GothamBold
	info.Text = row.label
	info.Parent = card
	upgradeLabels[row.which] = info

	local buy = Instance.new("TextButton")
	buy.Size = UDim2.fromOffset(180, 36)
	buy.Position = UDim2.fromOffset(8, 46)
	buy.Text = "Buy"
	buy.Parent = card
	MenuLayout.styleButton(buy, "success")
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

-- === Rebirth window ===
local rebirthBtn = MenuLayout.makePrimaryButton(gui, "Rebirth", "✨ Rebirth")
local rebirthPanel, rebirthContent = MenuLayout.makeWindow(gui, "✨ Rebirth")

local function rebirthCost(rebirths: number): number
	return math.floor(GameConfig.RebirthBaseCost * GameConfig.RebirthCostGrowth ^ rebirths)
end

local rebirthInfo = Instance.new("TextLabel")
rebirthInfo.Size = UDim2.new(1, -8, 0, 150)
rebirthInfo.LayoutOrder = 1
rebirthInfo.BackgroundTransparency = 1
rebirthInfo.TextColor3 = MenuLayout.BodyText
rebirthInfo.TextXAlignment = Enum.TextXAlignment.Left
rebirthInfo.TextYAlignment = Enum.TextYAlignment.Top
rebirthInfo.TextSize = 18
rebirthInfo.Font = Enum.Font.Gotham
rebirthInfo.Text = ""
rebirthInfo.Parent = rebirthContent

local rebirthDo = Instance.new("TextButton")
rebirthDo.Size = UDim2.fromOffset(220, 44)
rebirthDo.LayoutOrder = 2
rebirthDo.Text = "✨ Rebirth"
rebirthDo.Parent = rebirthContent
MenuLayout.styleButton(rebirthDo, "danger") -- resets coins: signal the weight
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
