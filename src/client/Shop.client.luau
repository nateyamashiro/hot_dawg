--!strict
-- Rotating shop UI (M3 remainder, GDD §4.3). A toggleable panel listing today's
-- buyable hot dogs (the same set for everyone, chosen server-side by UTC day) with a
-- countdown to the next rotation. Untrusted display only: it renders the server's
-- ShopUpdate snapshot and fires BuyFromShop; the server validates + charges.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyFromShop = remotes:WaitForChild("BuyFromShop") :: RemoteEvent
local shopUpdate = remotes:WaitForChild("ShopUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

type Offer = { name: string, rarity: HotDogDex.Rarity, income: number, price: number }

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyShop"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(MenuLayout.BUTTON_W, MenuLayout.BUTTON_H)
toggle.Position = MenuLayout.primaryPosition(MenuLayout.slotOf("Shop") or 4)
toggle.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.Text = "🛒 Shop"
toggle.Parent = gui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(480, 400)
panel.Position = UDim2.new(0.5, -240, 0.5, -200)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 34)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 230, 150)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Text = "🛒 Hot Dog Shop"
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(36, 36)
close.Position = UDim2.new(1, -42, 0, 10)
close.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextScaled = true
close.Font = Enum.Font.GothamBold
close.Text = "✕"
close.Parent = panel
close.Activated:Connect(function()
	panel.Visible = false
end)

local timer = Instance.new("TextLabel")
timer.Size = UDim2.new(1, -24, 0, 22)
timer.Position = UDim2.fromOffset(12, 44)
timer.BackgroundTransparency = 1
timer.TextColor3 = Color3.fromRGB(170, 200, 255)
timer.TextXAlignment = Enum.TextXAlignment.Left
timer.TextScaled = true
timer.Font = Enum.Font.Gotham
timer.Text = "Refreshes daily"
timer.Parent = panel

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -24, 1, -84)
list.Position = UDim2.fromOffset(12, 72)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 8
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

-- Build one row per offer, fresh on each ShopUpdate (offer set is small + changes daily).
local function renderOffers(offers: { Offer })
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for i, offer in offers do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 52)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		row.LayoutOrder = i
		row.Parent = list

		local swatch = Instance.new("Frame")
		swatch.Size = UDim2.fromOffset(8, 52)
		swatch.BackgroundColor3 = HotDogDex.colorFor(offer.rarity)
		swatch.BorderSizePixel = 0
		swatch.Parent = row

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -150, 0, 28)
		name.Position = UDim2.fromOffset(18, 4)
		name.BackgroundTransparency = 1
		name.TextColor3 = HotDogDex.colorFor(offer.rarity)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextScaled = true
		name.Font = Enum.Font.GothamBold
		name.Text = offer.name
		name.Parent = row

		local detail = Instance.new("TextLabel")
		detail.Size = UDim2.new(1, -150, 0, 18)
		detail.Position = UDim2.fromOffset(18, 30)
		detail.BackgroundTransparency = 1
		detail.TextColor3 = Color3.fromRGB(190, 190, 200)
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.TextScaled = true
		detail.Font = Enum.Font.Gotham
		detail.Text = string.format("%s · +%d/s income", offer.rarity, offer.income)
		detail.Parent = row

		local buy = Instance.new("TextButton")
		buy.Size = UDim2.fromOffset(128, 40)
		buy.Position = UDim2.new(1, -134, 0.5, -20)
		buy.BackgroundColor3 = Color3.fromRGB(60, 140, 80)
		buy.TextColor3 = Color3.fromRGB(255, 255, 255)
		buy.TextScaled = true
		buy.Font = Enum.Font.GothamBold
		buy.Text = "💰 " .. offer.price
		buy.Parent = row
		buy.Activated:Connect(function()
			buyFromShop:FireServer(offer.name)
		end)
	end
end

-- Client-side countdown, seeded by the server's secondsLeft and ticked locally.
local secondsLeft = 0

local function formatCountdown(s: number): string
	s = math.max(0, math.floor(s))
	local h = math.floor(s / 3600)
	local m = math.floor((s % 3600) / 60)
	local sec = s % 60
	return string.format("Refreshes in %02d:%02d:%02d", h, m, sec)
end

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

shopUpdate.OnClientEvent:Connect(function(offers: { Offer }, refreshInSeconds: number)
	secondsLeft = refreshInSeconds
	timer.Text = formatCountdown(secondsLeft)
	renderOffers(offers)
end)

-- Tick the countdown down each second; when it lapses, ask the server for the fresh
-- rotation (its rollover push may arrive first, which just re-seeds the timer).
task.spawn(function()
	while true do
		task.wait(1)
		if secondsLeft > 0 then
			secondsLeft -= 1
			timer.Text = formatCountdown(secondsLeft)
			if secondsLeft <= 0 then
				requestState:FireServer()
			end
		end
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
requestState:FireServer() -- request today's offers now that we're listening
