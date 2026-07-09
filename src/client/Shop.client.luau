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

local toggle = MenuLayout.makePrimaryButton(gui, "Shop", "🛒 Shop")

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(480, 400)
panel.Position = UDim2.new(0.5, -240, 0.5, -200)
panel.Visible = false
panel.Parent = gui
MenuLayout.themePanel(panel)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 34)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.TextColor3 = MenuLayout.BodyText
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.Font = MenuLayout.TitleFont
title.Text = "🛒 Hot Dog Shop"
title.Parent = panel

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(36, 36)
close.Position = UDim2.new(1, -42, 0, 10)
close.Text = "✕"
close.Parent = panel
MenuLayout.styleButton(close, "danger")
close.Activated:Connect(function()
	panel.Visible = false
end)

local timer = Instance.new("TextLabel")
timer.Size = UDim2.new(1, -24, 0, 22)
timer.Position = UDim2.fromOffset(12, 44)
timer.BackgroundTransparency = 1
timer.TextColor3 = MenuLayout.MutedText
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
-- `boughtToday`/`cap` drive the per-offer daily limit display (cap 0 = unlimited).
local function renderOffers(offers: { Offer }, boughtToday: { [string]: number }, cap: number)
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for i, offer in offers do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 52)
		row.BackgroundColor3 = MenuLayout.RowBg
		row.LayoutOrder = i
		row.Parent = list
		MenuLayout.addChrome(row, 8)

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

		local bought = boughtToday[offer.name] or 0
		local capped = cap > 0 and bought >= cap

		local detail = Instance.new("TextLabel")
		detail.Size = UDim2.new(1, -150, 0, 18)
		detail.Position = UDim2.fromOffset(18, 30)
		detail.BackgroundTransparency = 1
		detail.TextColor3 = MenuLayout.MutedText
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.TextScaled = true
		detail.Font = Enum.Font.Gotham
		detail.Text = if cap > 0
			then string.format(
				"%s · +%d/s income · %d/%d today",
				offer.rarity,
				offer.income,
				bought,
				cap
			)
			else string.format("%s · +%d/s income", offer.rarity, offer.income)
		detail.Parent = row

		local buy = Instance.new("TextButton")
		buy.Size = UDim2.fromOffset(128, 40)
		buy.Position = UDim2.new(1, -134, 0.5, -20)
		buy.Text = if capped then "✅ Maxed today" else "💰 " .. offer.price
		buy.Parent = row
		MenuLayout.styleButton(buy, if capped then "danger" else "success")
		if capped then
			buy.BackgroundColor3 = MenuLayout.Disabled
		end
		buy.Activated:Connect(function()
			if not capped then
				buyFromShop:FireServer(offer.name)
			end
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

shopUpdate.OnClientEvent:Connect(function(offers: { Offer }, refreshInSeconds: number, bought, cap)
	secondsLeft = refreshInSeconds
	timer.Text = formatCountdown(secondsLeft)
	renderOffers(
		offers,
		if type(bought) == "table" then bought else {},
		if type(cap) == "number" then cap else 0
	)
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
