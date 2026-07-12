--!strict
-- Trade panel (M6). Two-sided trade window: request a NEARBY player (or accept
-- their invite), both sides build composite-key stack offers with +/− steppers,
-- BOTH confirm, the server transfers atomically. Untrusted display: renders the
-- server's TradeUpdate state (session table / invite record / nil = cleared) and
-- fires TradeRequest / TradeUpdate(offer) / TradeConfirm / TradeCancel. Any offer
-- change clears both confirmations server-side, so the panel re-renders from each
-- push rather than trusting local state. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)
local Variants = require(ReplicatedStorage.Shared.Variants)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local tradeRequest = remotes:WaitForChild("TradeRequest") :: RemoteEvent
local tradeUpdate = remotes:WaitForChild("TradeUpdate") :: RemoteEvent
local tradeConfirm = remotes:WaitForChild("TradeConfirm") :: RemoteEvent
local tradeCancel = remotes:WaitForChild("TradeCancel") :: RemoteEvent
local inventoryUpdate = remotes:WaitForChild("InventoryUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

-- How far away the nearby-player list looks (client-side convenience only — the
-- server enforces its own GameConfig.TradeMaxDistance on the actual handshake).
local NEARBY_STUDS = 60

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyTrade"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Trade", "🤝 Trade")
local panel, content = MenuLayout.makePanel(gui, "🤝 Trade")

-- === Local mirrors of server state (the server's pushes are the truth) ===
local session: any = nil -- live session table, or nil
local invite: { from: number, name: string }? = nil
local inventory: { [string]: number } = {}
local myOffer: { [string]: number } = {}

local function labelFor(key: string): string
	local baseName, variant = Variants.decode(key)
	return if variant == "base" then baseName else baseName .. " (" .. variant .. ")"
end

local function offerStackCount(offer: { [string]: number }): number
	local n = 0
	for _ in offer do
		n += 1
	end
	return n
end

-- === Rendering (full rebuild on every state change — small row counts) ===
local function clearRows()
	for _, child in content:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function addLabel(order: number, text: string, big: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -8, 0, if big then 34 else 24)
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.TextColor3 = MenuLayout.BodyText
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	label.Font = if big then Enum.Font.GothamBold else Enum.Font.Gotham
	label.Text = text
	label.Parent = content
	return label
end

local function addButton(order: number, text: string, kind: string, cb: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -8, 0, 40)
	btn.LayoutOrder = order
	btn.Text = text
	btn.Parent = content
	MenuLayout.styleButton(btn, kind)
	btn.Activated:Connect(cb)
	return btn
end

local render -- forward-declared: stepper callbacks re-render

-- Send the local offer to the server (it validates + broadcasts the session back).
local function pushOffer()
	tradeUpdate:FireServer(myOffer)
end

-- One row of YOUR offer editor: "label ×owned" with a [−] count [+] stepper.
local function addOfferEditorRow(order: number, key: string, owned: number)
	local offered = myOffer[key] or 0

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 38)
	row.BackgroundColor3 = MenuLayout.RowBg
	row.LayoutOrder = order
	row.Parent = content
	MenuLayout.addChrome(row, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -150, 1, -6)
	label.Position = UDim2.fromOffset(8, 3)
	label.BackgroundTransparency = 1
	label.TextColor3 = if offered > 0 then MenuLayout.SuccessText else MenuLayout.BodyText
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Text = labelFor(key) .. " ×" .. owned
	label.Parent = row

	local minus = Instance.new("TextButton")
	minus.Size = UDim2.fromOffset(32, 30)
	minus.Position = UDim2.new(1, -140, 0.5, -15)
	minus.Text = "−"
	minus.Parent = row
	MenuLayout.styleButton(minus, "danger")
	minus.Activated:Connect(function()
		if (myOffer[key] or 0) > 0 then
			local next_ = (myOffer[key] or 0) - 1
			myOffer[key] = if next_ > 0 then next_ else nil
			pushOffer()
			render()
		end
	end)

	local count = Instance.new("TextLabel")
	count.Size = UDim2.fromOffset(60, 30)
	count.Position = UDim2.new(1, -104, 0.5, -15)
	count.BackgroundTransparency = 1
	count.TextColor3 = MenuLayout.BodyText
	count.TextScaled = true
	count.Font = Enum.Font.GothamBold
	count.Text = tostring(offered)
	count.Parent = row

	local plus = Instance.new("TextButton")
	plus.Size = UDim2.fromOffset(32, 30)
	plus.Position = UDim2.new(1, -40, 0.5, -15)
	plus.Text = "+"
	plus.Parent = row
	MenuLayout.styleButton(plus, "success")
	plus.Activated:Connect(function()
		local current = myOffer[key] or 0
		-- Client-side comfort clamps; the server re-validates everything anyway.
		if current >= owned then
			return
		end
		if current == 0 and offerStackCount(myOffer) >= GameConfig.TradeMaxItems then
			return
		end
		myOffer[key] = current + 1
		pushOffer()
		render()
	end)
end

local function renderNoSession()
	if invite then
		addLabel(1, "🤝 " .. invite.name .. " wants to trade!", true)
		local from = invite.from
		addButton(2, "Accept trade with " .. invite.name, "success", function()
			tradeRequest:FireServer(from)
		end)
	else
		addLabel(1, "Trade glizzies with a nearby player.", true)
	end
	addLabel(3, "Nearby players:")

	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local order = 4
	local found = false
	if myRoot and myRoot:IsA("BasePart") then
		for _, other in Players:GetPlayers() do
			if other ~= player then
				local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				if
					root
					and root:IsA("BasePart")
					and (root.Position - myRoot.Position).Magnitude <= NEARBY_STUDS
				then
					found = true
					local uid = other.UserId
					addButton(order, "Request " .. other.DisplayName, "primary", function()
						tradeRequest:FireServer(uid)
					end)
					order += 1
				end
			end
		end
	end
	if not found then
		addLabel(order, "No one close enough — walk up to another player.")
	end
end

local function renderSession()
	local mineIsA = session.a == player.UserId
	local theirName = if mineIsA then session.nameB else session.nameA
	local theirOffer = (if mineIsA then session.offerB else session.offerA) or {}
	local theirConfirmed = if mineIsA then session.confirmB else session.confirmA
	local myConfirmed = if mineIsA then session.confirmA else session.confirmB

	addLabel(1, "Trading with " .. tostring(theirName), true)

	addLabel(2, "Their offer" .. (if theirConfirmed then "  ✅ confirmed" else ""), true)
	local order = 3
	local theirEmpty = true
	for key, qty in theirOffer do
		theirEmpty = false
		addLabel(order, "• " .. labelFor(key) .. " ×" .. tostring(qty))
		order += 1
	end
	if theirEmpty then
		addLabel(order, "— nothing yet —")
		order += 1
	end

	addLabel(
		order,
		"Your offer ("
			.. offerStackCount(myOffer)
			.. "/"
			.. GameConfig.TradeMaxItems
			.. " stacks)"
			.. (if myConfirmed then "  ✅ confirmed" else ""),
		true
	)
	order += 1

	-- Every owned stack is an editor row (the window content scrolls).
	local keys: { string } = {}
	for key in inventory do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in keys do
		addOfferEditorRow(order, key, inventory[key])
		order += 1
	end
	if #keys == 0 then
		addLabel(order, "You have no glizzies to offer.")
		order += 1
	end

	addButton(
		order,
		if myConfirmed then "Confirmed — waiting…" else "Confirm ✓",
		"success",
		function()
			tradeConfirm:FireServer()
		end
	)
	addButton(order + 1, "Cancel trade", "danger", function()
		tradeCancel:FireServer()
	end)
end

render = function()
	clearRows()
	if session then
		renderSession()
	else
		renderNoSession()
	end
end

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		render()
	end
end)

tradeUpdate.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" then
		-- Cleared: trade finished or cancelled.
		session = nil
		myOffer = {}
	elseif type(state.invite) == "table" then
		invite = state.invite
	elseif state.a ~= nil then
		session = state
		invite = nil
		-- Sync the local mirror to the server's accepted offer for my side.
		local serverOffer = (if state.a == player.UserId then state.offerA else state.offerB) or {}
		myOffer = {}
		for key, qty in serverOffer do
			myOffer[key] = qty
		end
	end
	render()
end)

inventoryUpdate.OnClientEvent:Connect(function(hotDogs)
	inventory = {}
	if type(hotDogs) == "table" then
		for key, qty in hotDogs do
			if type(key) == "string" and type(qty) == "number" then
				inventory[key] = qty
			end
		end
	end
	if panel.Visible then
		render()
	end
end)

-- The nearby-player list goes stale as people walk around: refresh it while the
-- panel is open and idle (sessions re-render on server pushes instead).
task.spawn(function()
	while true do
		task.wait(2)
		if panel.Visible and not session then
			render()
		end
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
