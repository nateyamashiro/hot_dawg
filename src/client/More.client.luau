--!strict
-- "⋯ More" primary-row button (M4+). Owns no panel — it just flips the
-- MenuLayout.TRAY_ATTR attribute that every secondary panel's tray toggle watches,
-- so the growing set of panels (Prestige, Fusion, Events, Leaderboards,
-- Achievements, Codes, Passes, Cosmetics, Trade) stays decoupled and the primary
-- bottom row never overflows. Untrusted display only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyMore"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local btn = Instance.new("TextButton")
btn.Size = UDim2.fromOffset(MenuLayout.BUTTON_W, MenuLayout.BUTTON_H)
btn.Position = MenuLayout.primaryPosition(MenuLayout.slotOf("More") or 5)
btn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextScaled = true
btn.Font = Enum.Font.GothamBold
btn.Text = "⋯ More"
btn.Parent = gui

btn.Activated:Connect(function()
	player:SetAttribute(MenuLayout.TRAY_ATTR, player:GetAttribute(MenuLayout.TRAY_ATTR) ~= true)
end)

gui.Parent = player:WaitForChild("PlayerGui")
