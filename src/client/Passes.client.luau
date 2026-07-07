--!strict
-- Monetization panel (M5). Lists game passes (Extra Slots + VIP first, then 2× coins
-- / auto-collect) and dev products (coin packs, refills, steal charges). All
-- non-pay-to-win; NEVER paid gacha. Untrusted display: fires PromptPurchase so the
-- server prompts the real Robux purchase. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 32)
status.LayoutOrder = 1
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(200, 230, 200)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Text = "Owned: —"
status.Parent = content

-- First passes to ship (GDD locked): Extra Slots + VIP. `kind` is the GameConfig key.
local offers = { { "extraSlots", "🎁 Extra Slots" }, { "vip", "👑 VIP" } }
for i, o in offers do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.LayoutOrder = i + 1
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 85)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.Text = o[2]
	btn.Parent = content
	btn.Activated:Connect(function()
		promptPurchase:FireServer(o[1])
	end)
end

purchaseUpdate.OnClientEvent:Connect(function(owned)
	-- TODO(M5-mon): grey out owned passes + show dev-product buttons with prices.
	if type(owned) == "table" then
		status.Text = "VIP: "
			.. tostring(owned.vip)
			.. " · +slots: "
			.. tostring(owned.bonusDisplaySlots)
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
