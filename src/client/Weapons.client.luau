--!strict
-- Weapons panel (Phase 5, "⋯ More" tray). Lists the three condiment blasters:
-- Buy (coins) → Equip → equipped ✓. Untrusted display: renders the server's
-- WeaponUpdate snapshot and fires BuyWeapon / EquipWeapon; firing happens with the
-- physical blaster Tool (server-validated), never from here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local MenuLayout = require(ReplicatedStorage.Shared.MenuLayout)

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyWeapon = remotes:WaitForChild("BuyWeapon") :: RemoteEvent
local equipWeapon = remotes:WaitForChild("EquipWeapon") :: RemoteEvent
local weaponUpdate = remotes:WaitForChild("WeaponUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent

type WeaponTier = {
	id: string,
	label: string,
	cost: number,
	effect: string,
	magnitude: number,
	cooldown: number,
}

local EFFECT_BLURB: { [string]: string } = {
	slow = "slows a thief",
	knockback = "launches a thief",
	stun = "freezes a thief",
}

local gui = Instance.new("ScreenGui")
gui.Name = "GlizzyWeapons"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local toggle = MenuLayout.makeTrayToggle(gui, player, "Weapons", "🔫 Blasters")
local panel, content = MenuLayout.makePanel(gui, "🔫 Condiment Blasters")
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

weaponUpdate.OnClientEvent:Connect(
	function(
		catalog: { WeaponTier }?,
		owned: { [string]: boolean }?,
		equipped: string?,
		coins: number?
	)
		for _, child in content:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		if type(catalog) ~= "table" then
			return
		end
		local ownedSet = if type(owned) == "table" then owned else {}
		local balance = if type(coins) == "number" then coins else 0

		for i, tier in catalog do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 56)
			row.LayoutOrder = i
			row.BackgroundColor3 = MenuLayout.RowBg
			row.Parent = content
			MenuLayout.addChrome(row, 8)

			local isOwned = ownedSet[tier.id] == true
			local isEquipped = equipped == tier.id

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -130, 1, -8)
			label.Position = UDim2.fromOffset(10, 4)
			label.BackgroundTransparency = 1
			label.TextColor3 = if isEquipped then MenuLayout.SuccessText else MenuLayout.BodyText
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			local blurb = EFFECT_BLURB[tier.effect] or tier.effect
			label.Text = if isEquipped
				then string.format("✅ %s — equipped", tier.label)
				else string.format("%s — %s (%.0fs cd)", tier.label, blurb, tier.cooldown)
			label.Parent = row

			if not isEquipped then
				local action = Instance.new("TextButton")
				action.Size = UDim2.fromOffset(110, 38)
				action.Position = UDim2.new(1, -118, 0.5, -19)
				action.Parent = row
				if isOwned then
					action.Text = "Equip"
					MenuLayout.styleButton(action, "primary")
					action.Activated:Connect(function()
						equipWeapon:FireServer(tier.id)
					end)
				else
					action.Text = "💰 " .. Format.comma(tier.cost)
					MenuLayout.styleButton(
						action,
						if balance >= tier.cost then "success" else "primary"
					)
					action.Activated:Connect(function()
						buyWeapon:FireServer(tier.id)
					end)
				end
			end
		end
	end
)

gui.Parent = player:WaitForChild("PlayerGui")
requestState:FireServer() -- pull the blaster catalog snapshot past the join race
