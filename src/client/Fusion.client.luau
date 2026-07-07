--!strict
-- Fusion panel (M3 remainder). Lists dogs you own enough duplicates of to fuse into
-- a better outcome. Untrusted display: reads the InventoryUpdate snapshot and fires
-- Fuse(key); the server validates ownership + consumes. Reached via the "⋯ More" tray.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)
local Variants = require(ReplicatedStorage.Shared.Variants)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryUpdate = remotes:WaitForChild("InventoryUpdate") :: RemoteEvent
local fuse = remotes:WaitForChild("Fuse") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyFusion"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Fusion", "⚗️ Fuse")
local panel, content = MenuLayout.makePanel(gui, "⚗️ Fusion")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

inventoryUpdate.OnClientEvent:Connect(function(hotDogs)
	for _, child in content:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	if type(hotDogs) ~= "table" then
		return
	end
	-- TODO(M3-fusion): preview the fusion RESULT per key + confirm dialog.
	local i = 0
	for key, count in hotDogs do
		if count >= GameConfig.FusionInputs then
			i += 1
			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1, 0, 0, 40)
			row.LayoutOrder = i
			row.BackgroundColor3 = Color3.fromRGB(60, 55, 75)
			row.TextColor3 = Color3.fromRGB(255, 255, 255)
			row.TextScaled = true
			row.Font = Enum.Font.GothamBold
			row.Text = "Fuse " .. GameConfig.FusionInputs .. "× " .. Variants.displayName(key)
			row.Parent = content
			row.Activated:Connect(function()
				fuse:FireServer(key)
			end)
		end
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
