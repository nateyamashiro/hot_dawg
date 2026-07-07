--!strict
-- Trade panel (M6). A two-sided trade window: request a nearby player, both add
-- stacks, BOTH confirm, done. Untrusted display: renders the server's TradeUpdate
-- session state and fires TradeRequest / TradeUpdate (offer) / TradeConfirm /
-- TradeCancel; the server owns the authoritative session + atomic transfer. Reached
-- via the "⋯ More" tray. (Ships after the anti-exploit hardening pass.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local tradeRequest = remotes:WaitForChild("TradeRequest") :: RemoteEvent
local tradeUpdate = remotes:WaitForChild("TradeUpdate") :: RemoteEvent
local tradeConfirm = remotes:WaitForChild("TradeConfirm") :: RemoteEvent
local tradeCancel = remotes:WaitForChild("TradeCancel") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyTrade"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Trade", "🤝 Trade")
local panel, content = MenuLayout.makePanel(gui, "🤝 Trade")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 48)
status.LayoutOrder = 1
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(220, 220, 230)
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Text = "No active trade."
status.Parent = content

local function makeBtn(order: number, text: string, color: Color3): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.LayoutOrder = order
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.Parent = content
	return btn
end

-- TODO(M6-trade): replace with a real "trade nearest player" target picker + an
-- offer editor (drag stacks in). For now these just exercise the remotes.
makeBtn(2, "Request trade", Color3.fromRGB(60, 60, 85)).Activated:Connect(function()
	tradeRequest:FireServer(0) -- TODO: pass the chosen target's UserId
end)
makeBtn(3, "Update offer", Color3.fromRGB(60, 70, 80)).Activated:Connect(function()
	tradeUpdate:FireServer({}) -- TODO: send this side's {key = qty} offer
end)
makeBtn(4, "Confirm", Color3.fromRGB(70, 90, 55)).Activated:Connect(function()
	tradeConfirm:FireServer()
end)
makeBtn(5, "Cancel", Color3.fromRGB(120, 50, 50)).Activated:Connect(function()
	tradeCancel:FireServer()
end)

tradeUpdate.OnClientEvent:Connect(function(session)
	-- TODO(M6-trade): render both offers + each side's confirmed state + a
	-- value-diff note; here just reflect that a session exists.
	if type(session) == "table" then
		status.Text = "Trade in progress… (confirm A: "
			.. tostring(session.confirmA)
			.. ", B: "
			.. tostring(session.confirmB)
			.. ")"
	else
		status.Text = "No active trade."
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
