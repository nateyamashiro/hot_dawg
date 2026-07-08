--!strict
-- Codes panel (M4). A text box to redeem a promo code for a one-time reward.
-- Untrusted display: fires RedeemCode; the server validates + grants and reports the
-- result via the shared StealFeedback toast. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local redeemCode = remotes:WaitForChild("RedeemCode") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyCodes"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Codes", "🎟️ Codes")
local panel, content = MenuLayout.makePanel(gui, "🎟️ Redeem a Code")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, 0, 0, 44)
box.LayoutOrder = 1
box.BackgroundColor3 = MenuLayout.RowBg
box.TextColor3 = MenuLayout.BodyText
box.PlaceholderText = "Enter code…"
box.TextScaled = true
box.Font = Enum.Font.Gotham
box.Text = ""
box.ClearTextOnFocus = false
box.Parent = content
MenuLayout.addChrome(box, 8)

local submit = Instance.new("TextButton")
submit.Size = UDim2.new(1, 0, 0, 40)
submit.LayoutOrder = 2
submit.Text = "Redeem"
submit.Parent = content
MenuLayout.styleButton(submit, "success")
submit.Activated:Connect(function()
	if box.Text ~= "" then
		redeemCode:FireServer(box.Text)
		box.Text = ""
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
