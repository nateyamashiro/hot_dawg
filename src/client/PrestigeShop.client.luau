--!strict
-- Prestige shop panel (M3 remainder). Lists premium unlocks bought with the
-- `prestige` currency rebirths + the dex reward bank. Untrusted display: renders the
-- server's PrestigeShopUpdate snapshot (catalog + balance + owned set) and fires
-- BuyPrestige; the server validates + charges. Mirrors Shop.client. Reached via the
-- "⋯ More" tray. Unlocks are one-time, so owned rows show as claimed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local prestigeShopUpdate = remotes:WaitForChild("PrestigeShopUpdate") :: RemoteEvent
local buyPrestige = remotes:WaitForChild("BuyPrestige") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

type Item = { id: string, cost: number, label: string, effect: string, amount: number }

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyPrestige"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "PrestigeShop", "✨ Prestige")
local panel, content = MenuLayout.makePanel(gui, "✨ Prestige Shop")
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

prestigeShopUpdate.OnClientEvent:Connect(function(items, prestige, unlocks)
	local balanceNum = if type(prestige) == "number" then prestige else 0
	balance.Text = "✨ Prestige: " .. tostring(balanceNum)

	-- Rebuild the item rows (small, fixed catalog) each update.
	for _, child in content:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	if type(items) ~= "table" then
		return
	end
	local owned = if type(unlocks) == "table" then unlocks else {}

	for i, item: Item in items do
		local isOwned = owned[item.id] == true
		local affordable = not isOwned and balanceNum >= item.cost

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
		label.TextColor3 = if isOwned then MenuLayout.SuccessText else MenuLayout.BodyText
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Text = item.label
		label.Parent = row

		local buy = Instance.new("TextButton")
		buy.Size = UDim2.fromOffset(116, 40)
		buy.Position = UDim2.new(1, -122, 0.5, -20)
		buy.TextColor3 = Color3.fromRGB(255, 255, 255)
		buy.TextScaled = true
		buy.Font = Enum.Font.GothamBold
		if isOwned then
			buy.BackgroundColor3 = MenuLayout.Disabled
			buy.Text = "Owned ✓"
			buy.AutoButtonColor = false
			buy.Active = false
		else
			buy.BackgroundColor3 = if affordable then MenuLayout.SuccessBg else MenuLayout.DangerBg
			buy.Text = tostring(item.cost) .. " ✨"
			buy.Activated:Connect(function()
				buyPrestige:FireServer(item.id)
			end)
		end
		buy.Parent = row
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
