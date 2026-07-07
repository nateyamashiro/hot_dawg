--!strict
-- Prestige shop panel (M3 remainder). Lists premium unlocks bought with the
-- `prestige` currency rebirths bank. Untrusted display: renders the server's
-- PrestigeShopUpdate snapshot and fires BuyPrestige; the server validates + charges.
-- Mirrors Shop.client. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local prestigeShopUpdate = remotes:WaitForChild("PrestigeShopUpdate") :: RemoteEvent
local buyPrestige = remotes:WaitForChild("BuyPrestige") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyPrestige"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "PrestigeShop", "✨ Prestige")
local panel, content = MenuLayout.makePanel(gui, "✨ Prestige Shop")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

prestigeShopUpdate.OnClientEvent:Connect(function(items, prestige)
	-- TODO(M3-prestige): render a row per unlock with an affordability-aware Buy
	-- button; for now, wire one button per item that fires BuyPrestige(item.id).
	for _, child in content:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if type(items) ~= "table" then
		return
	end
	for i, item in items do
		local affordable = type(prestige) == "number" and prestige >= item.cost
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.LayoutOrder = i
		row.BackgroundColor3 = if affordable
			then Color3.fromRGB(55, 75, 55)
			else Color3.fromRGB(70, 55, 55)
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.TextScaled = true
		row.Font = Enum.Font.GothamBold
		row.Text = item.label .. "  —  " .. tostring(item.cost) .. " ✨"
		row.Parent = content
		row.Activated:Connect(function()
			buyPrestige:FireServer(item.id)
		end)
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
