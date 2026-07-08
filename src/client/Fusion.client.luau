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
	-- Show one row per key you own ≥FusionInputs of, previewing the fused RESULT
	-- (base → Gold → Rainbow → Giant). Keys already at the top variant (Giant) can't
	-- fuse higher, so we skip them — the server refuses too. Result colour comes from
	-- the target variant so the reward reads at a glance.
	local i = 0
	for key, count in hotDogs do
		local _, variant = Variants.decode(key)
		local nextVariant = Variants.nextVariant(variant)
		if count >= GameConfig.FusionInputs and nextVariant then
			i += 1
			local resultKey = Variants.encode(Variants.baseName(key), nextVariant)
			local resultDef = Variants.def(nextVariant)
			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1, 0, 0, 40)
			row.LayoutOrder = i
			row.BackgroundColor3 = MenuLayout.RowBg
			row.TextColor3 = if resultDef then resultDef.color else MenuLayout.BodyText
			row.TextScaled = true
			row.Font = Enum.Font.GothamBold
			row.Text = GameConfig.FusionInputs
				.. "× "
				.. Variants.displayName(key)
				.. "  →  "
				.. Variants.displayName(resultKey)
			row.Parent = content
			row.Activated:Connect(function()
				fuse:FireServer(key)
			end)
		end
	end
end)

requestState:FireServer()
gui.Parent = player:WaitForChild("PlayerGui")
