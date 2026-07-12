--!strict
-- Monetization panel (M5). Game passes (Extra Slots + VIP first) and dev products
-- (coin packs, steal charges). All non-pay-to-win; NEVER paid gacha. Untrusted
-- display: fires PromptPurchase so the SERVER prompts the real Robux purchase and
-- owns every grant; PurchaseUpdate greys out owned passes. Reached via "⋯ More".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local promptPurchase = remotes:WaitForChild("PromptPurchase") :: RemoteEvent
local purchaseUpdate = remotes:WaitForChild("PurchaseUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyPasses"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Passes", "💎 Shop+")
local panel, content = MenuLayout.makePanel(gui, "💎 Passes & Perks")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local function makeHeader(text: string, order: number)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 26)
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.TextColor3 = MenuLayout.BodyText
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.Parent = content
end

-- First passes to ship (GDD locked): Extra Slots + VIP. `kind` = the GameConfig key.
makeHeader("Game Passes", 1)
local passOffers = {
	{
		"extraSlots",
		string.format(
			"🎁 Extra Slots (+%d display / +%d vault)",
			GameConfig.ExtraSlotsPassDisplay,
			GameConfig.ExtraSlotsPassVault
		),
	},
	{ "vip", string.format("👑 VIP (+%d%% income)", GameConfig.VipIncomeBonus * 100) },
}
local passButtons: { [string]: TextButton } = {}
local passLabels: { [string]: string } = {}
local passColors: { [string]: Color3 } = {}
for i, o in passOffers do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.LayoutOrder = i + 1
	btn.Text = o[2]
	btn.Parent = content
	MenuLayout.styleButton(btn, "primary")
	btn.Activated:Connect(function()
		promptPurchase:FireServer(o[1])
	end)
	passButtons[o[1]] = btn
	passLabels[o[1]] = o[2]
	passColors[o[1]] = btn.BackgroundColor3
end

-- Dev products: consumables the server grants through ProcessReceipt.
makeHeader("Boosts", 10)
local productOffers = {
	{
		"coinsSmall",
		string.format("💰 %s Coins", Format.comma(GameConfig.ProductGrants.coinsSmall)),
	},
	{
		"coinsLarge",
		string.format("💰 %s Coins", Format.comma(GameConfig.ProductGrants.coinsLarge)),
	},
	{
		"stealCharges",
		string.format("⚡ +%d Steal Charges", GameConfig.ProductGrants.stealCharges),
	},
}
for i, o in productOffers do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.LayoutOrder = i + 10
	btn.Text = o[2]
	btn.Parent = content
	MenuLayout.styleButton(btn, "success")
	btn.Activated:Connect(function()
		promptPurchase:FireServer(o[1])
	end)
end

purchaseUpdate.OnClientEvent:Connect(function(owned)
	if type(owned) ~= "table" or type(owned.passes) ~= "table" then
		return
	end
	for kind, btn in passButtons do
		if owned.passes[kind] == true then
			btn.Text = passLabels[kind] .. " — OWNED ✓"
			btn.Active = false
			btn.AutoButtonColor = false
			btn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		else
			btn.Text = passLabels[kind]
			btn.Active = true
			btn.AutoButtonColor = true
			btn.BackgroundColor3 = passColors[kind]
		end
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
