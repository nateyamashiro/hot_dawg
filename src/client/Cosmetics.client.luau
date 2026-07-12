--!strict
-- Cosmetics wardrobe panel (M5). Stand skins, trails, and titles (non-pay-to-win,
-- prestige-priced). Untrusted display: renders the server's CosmeticUpdate snapshot
-- (catalog + owned/equipped + prestige balance) and fires BuyCosmetic /
-- EquipCosmetic; the server validates, charges, and applies the visuals. Equipping
-- an equipped piece unequips it. Mirrors PrestigeShop.client. Reached via the
-- "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local cosmeticUpdate = remotes:WaitForChild("CosmeticUpdate") :: RemoteEvent
local buyCosmetic = remotes:WaitForChild("BuyCosmetic") :: RemoteEvent
local equipCosmetic = remotes:WaitForChild("EquipCosmetic") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

type Item = { id: string, kind: string, label: string, prestigeCost: number, icon: string? }

local KIND_ICONS: { [string]: string } = {
	standSkin = "🏠",
	trail = "💫",
	title = "📛",
}

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyCosmetics"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Cosmetics", "🎨 Style")
local panel, content = MenuLayout.makePanel(gui, "🎨 Cosmetics")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

-- Persistent balance header (always LayoutOrder 0, above the rebuilt rows).
local balance = Instance.new("TextLabel")
balance.Size = UDim2.new(1, -8, 0, 30)
balance.LayoutOrder = 0
balance.BackgroundColor3 = MenuLayout.RowBg
balance.TextColor3 = MenuLayout.BodyText
balance.TextScaled = true
balance.Font = Enum.Font.GothamBold
balance.Text = "✨ Prestige: 0"
balance.Parent = content

cosmeticUpdate.OnClientEvent:Connect(function(catalog, cosmetics, prestige)
	local balanceNum = if type(prestige) == "number" then prestige else 0
	balance.Text = "✨ Prestige: " .. tostring(balanceNum)

	for _, child in content:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	if type(catalog) ~= "table" then
		return
	end
	local ownedSet = (type(cosmetics) == "table" and type(cosmetics.owned) == "table")
			and cosmetics.owned
		or {}
	local equippedSet = (type(cosmetics) == "table" and type(cosmetics.equipped) == "table")
			and cosmetics.equipped
		or {}

	for i, item: Item in catalog do
		local isOwned = ownedSet[item.id] == true
		local isEquipped = equippedSet[item.kind] == item.id
		local affordable = not isOwned and balanceNum >= item.prestigeCost

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 52)
		row.BackgroundColor3 = MenuLayout.RowBg
		row.LayoutOrder = i
		row.Parent = content
		MenuLayout.addChrome(row, 8)

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -134, 1, -8)
		label.Position = UDim2.fromOffset(10, 4)
		label.BackgroundTransparency = 1
		label.TextColor3 = if isEquipped then MenuLayout.SuccessText else MenuLayout.BodyText
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Text = (item.icon or KIND_ICONS[item.kind] or "🎨") .. " " .. item.label
		label.Parent = row

		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(116, 40)
		button.Position = UDim2.new(1, -122, 0.5, -20)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		if not isOwned then
			button.BackgroundColor3 = if affordable
				then MenuLayout.SuccessBg
				else MenuLayout.DangerBg
			button.Text = tostring(item.prestigeCost) .. " ✨"
			button.Activated:Connect(function()
				buyCosmetic:FireServer(item.id)
			end)
		elseif isEquipped then
			button.BackgroundColor3 = MenuLayout.SuccessBg
			button.Text = "Equipped ✓"
			button.Activated:Connect(function()
				equipCosmetic:FireServer(item.id) -- toggles off
			end)
		else
			button.BackgroundColor3 = MenuLayout.AccentBg
			button.Text = "Equip"
			button.Activated:Connect(function()
				equipCosmetic:FireServer(item.id)
			end)
		end
		button.Parent = row
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
