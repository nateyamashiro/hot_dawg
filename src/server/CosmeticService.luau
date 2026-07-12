--!strict
-- Cosmetics (M5, GDD §4.10). Stand skins, character trails, and sign titles —
-- bought with PRESTIGE, never affecting power (non-pay-to-win). Server owns the
-- catalog (GameConfig.Cosmetics), persists owned + one-equipped-per-kind in
-- data.cosmetics, and applies the visuals: stand skin = shell repaint
-- (PlotManager.applyStandSkin), trail = Trail on the character's root, title =
-- chip under the owner sign (PlotManager.setTitle). Untrusted client only
-- requests buy/equip. Mirrors PrestigeShopService (validate → charge → apply →
-- push); visuals re-derive from data.cosmetics.equipped on join/respawn, so a
-- rebuild can never double-apply anything.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Theme = require(ReplicatedStorage.Shared.Theme)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)
local Telemetry = require(ServerScriptService.Server.Telemetry)

local CosmeticService = {}

type CosmeticItem = {
	id: string,
	kind: string, -- "standSkin" | "trail" | "title"
	label: string,
	prestigeCost: number,
	icon: string?,
}
-- Dynamic view of the catalog (its literal type mixes optional fields).
local CATALOG = GameConfig.Cosmetics :: { CosmeticItem }

-- === Visual recipes, keyed by catalog id (config stays presentation-free) ===
-- Stand skins repaint the shell's wall/trim surfaces (palette colors only).
local SKINS: { [string]: PlotManager.StandSkin } = {
	skinGold = { wall = Theme.Palette.VaultGold, trim = Theme.Palette.CharBrown },
	skinRelish = { wall = Theme.Palette.Relish, trim = Theme.Palette.Cream },
}
-- Trails are a color gradient behind the character (small accent — budget-safe).
local TRAILS: { [string]: ColorSequence } = {
	trailFire = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 60)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 110, 40)),
		ColorSequenceKeypoint.new(1, Theme.Palette.Ketchup),
	}),
	trailRainbow = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 70)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 220, 100)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 255)),
	}),
}

local remBuyCosmetic: RemoteEvent
local remEquipCosmetic: RemoteEvent
local remCosmeticUpdate: RemoteEvent
local remFeedback: RemoteEvent
local remCelebrate: RemoteEvent
local pushProgression: (player: Player) -> ()

local function findItem(id: string): CosmeticItem?
	for _, item in CATALOG do
		if item.id == id then
			return item
		end
	end
	return nil
end

function CosmeticService.pushCosmetics(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	-- Balance rides along so the panel can color buy buttons by affordability.
	remCosmeticUpdate:FireClient(player, GameConfig.Cosmetics, data.cosmetics, data.prestige)
end

-- Re-derive the character trail from data.cosmetics.equipped.trail. Idempotent:
-- always clears the old instances first, so equip/unequip/respawn all route here.
local function applyTrail(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	for _, name in { "CosmeticTrail", "CosmeticTrailA0", "CosmeticTrailA1" } do
		local old = root:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local equippedId = data.cosmetics.equipped.trail
	local colors = if equippedId then TRAILS[equippedId] else nil
	if not colors then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "CosmeticTrailA0"
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "CosmeticTrailA1"
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "CosmeticTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = colors
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.4
	trail.MinLength = 0.2
	trail.FaceCamera = true
	trail.LightEmission = 0.5
	trail.Parent = root
end

-- Re-derive the stand visuals (skin repaint + title chip) from equipped state.
local function applyStand(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local skinId = data.cosmetics.equipped.standSkin
	local skin = if skinId then SKINS[skinId] else nil
	PlotManager.applyStandSkin(player, skin)

	local titleId = data.cosmetics.equipped.title
	local titleItem = if titleId then findItem(titleId) else nil
	if titleItem then
		local icon = titleItem.icon
		PlotManager.setTitle(player, (if icon then icon .. " " else "") .. titleItem.label)
	else
		PlotManager.setTitle(player, nil)
	end
end

-- Join hook (Main calls this after the plot is assigned): apply everything the
-- player had equipped, and keep the trail alive across respawns.
function CosmeticService.applyLoaded(player: Player)
	applyStand(player)
	player.CharacterAdded:Connect(function(character)
		-- Trail attaches to the root; wait for it in this event's own thread.
		character:WaitForChild("HumanoidRootPart", 5)
		applyTrail(player)
	end)
	applyTrail(player)
end

local function onBuy(player: Player, id: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local item = findItem(id)
	if not item then
		return
	end
	if data.cosmetics.owned[id] then
		remFeedback:FireClient(player, false, "You already own that cosmetic.")
		return
	end
	if data.prestige < item.prestigeCost then
		remFeedback:FireClient(
			player,
			false,
			"Not enough prestige — need " .. item.prestigeCost .. " ✨."
		)
		return
	end

	-- Charge, own, auto-equip the new piece (buying something you can't see is sad).
	data.prestige -= item.prestigeCost
	data.cosmetics.owned[id] = true
	data.cosmetics.equipped[item.kind] = id
	applyStand(player)
	applyTrail(player)

	pushProgression(player) -- prestige balance changed
	CosmeticService.pushCosmetics(player)
	Telemetry.event(player, "CosmeticBought_" .. id)
	remFeedback:FireClient(player, true, "🎨 Unlocked " .. item.label .. "!")
	local signPost = PlotManager.signPostOf(player)
	if signPost then
		remCelebrate:FireAllClients("purchase", signPost)
	end
end

local function onEquip(player: Player, id: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local item = findItem(id)
	if not item or not data.cosmetics.owned[id] then
		return
	end
	-- Toggle: equipping the already-equipped piece takes it off.
	if data.cosmetics.equipped[item.kind] == id then
		data.cosmetics.equipped[item.kind] = nil
		remFeedback:FireClient(player, true, "Unequipped " .. item.label .. ".")
	else
		data.cosmetics.equipped[item.kind] = id
		remFeedback:FireClient(player, true, "🎨 Equipped " .. item.label .. "!")
	end
	applyStand(player)
	applyTrail(player)
	CosmeticService.pushCosmetics(player)
end

function CosmeticService.init(deps: {
	remotes: Folder,
	pushProgression: (player: Player) -> (),
})
	pushProgression = deps.pushProgression
	remBuyCosmetic = deps.remotes:WaitForChild("BuyCosmetic") :: RemoteEvent
	remEquipCosmetic = deps.remotes:WaitForChild("EquipCosmetic") :: RemoteEvent
	remCosmeticUpdate = deps.remotes:WaitForChild("CosmeticUpdate") :: RemoteEvent
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remCelebrate = deps.remotes:WaitForChild("Celebrate") :: RemoteEvent

	remBuyCosmetic.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "BuyCosmetic", 5) then
			return
		end
		if type(id) == "string" and #id <= 40 then
			onBuy(player, id)
		end
	end)

	remEquipCosmetic.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "EquipCosmetic", 10) then
			return
		end
		if type(id) == "string" and #id <= 40 then
			onEquip(player, id)
		end
	end)
end

return CosmeticService
