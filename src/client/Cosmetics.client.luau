--!strict
-- Cosmetics wardrobe panel (M5). Stand skins, trails, and titles (non-pay-to-win).
-- Untrusted display: renders the server's CosmeticUpdate snapshot and fires
-- BuyCosmetic / EquipCosmetic. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local cosmeticUpdate = remotes:WaitForChild("CosmeticUpdate") :: RemoteEvent
local buyCosmetic = remotes:WaitForChild("BuyCosmetic") :: RemoteEvent
local equipCosmetic = remotes:WaitForChild("EquipCosmetic") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyCosmetics"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Cosmetics", "🎨 Style")
local panel, content = MenuLayout.makePanel(gui, "🎨 Cosmetics")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

cosmeticUpdate.OnClientEvent:Connect(function(catalog, owned)
	for _, child in content:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if type(catalog) ~= "table" then
		return
	end
	local ownedSet = (type(owned) == "table" and owned.owned) or {}
	for i, item in catalog do
		local isOwned = ownedSet[item.id] == true
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.LayoutOrder = i
		row.BackgroundColor3 = if isOwned then MenuLayout.SuccessBg else MenuLayout.AccentBg
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.TextScaled = true
		row.Font = Enum.Font.GothamBold
		row.Text = (if isOwned then "Equip " else "Buy ") .. item.label
		row.Parent = content
		MenuLayout.addChrome(row, 8)
		row.Activated:Connect(function()
			if isOwned then
				equipCosmetic:FireServer(item.id)
			else
				buyCosmetic:FireServer(item.id)
			end
		end)
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
