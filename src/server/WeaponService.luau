--!strict
-- Non-damaging weapons (Phase 5 — SHIPPED). Condiment "blasters" that DISRUPT a
-- carrying thief near YOUR stand — slow / knockback / brief stun — with NO health or
-- damage (locked all-ages tone). GameConfig.WeaponTiers defines each blaster's cost +
-- effect + magnitude + cooldown. Server owns ownership, the equip, the physical Tool,
-- and the authoritative effect: firing never trusts a client target — the server
-- picks the nearest CARRYING thief in range, and only while they're raiding the
-- firer's own plot (defense, not street griefing). Buy/equip ride the Weapons tray
-- panel; firing rides the Tool click (or the FireWeapon remote — same validated path).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Theme = require(ReplicatedStorage.Shared.Theme)
local DataManager = require(ServerScriptService.Server.DataManager)
local DefenseService = require(ServerScriptService.Server.DefenseService)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)
local StealService = require(ServerScriptService.Server.StealService)

local WeaponService = {}

type WeaponTier = {
	id: string,
	label: string,
	cost: number,
	effect: string, -- "slow" | "knockback" | "stun"
	magnitude: number,
	cooldown: number,
}

local WEAPON_RANGE = 24 -- studs from the firer a carrying thief can be tagged
local PLOT_DEFENSE_RADIUS = 55 -- the thief must be this close to the firer's plot (76×58 pads)
local SLOW_SECONDS = 2 -- how long the "slow" effect lasts

local updateLeaderstats: (player: Player) -> ()
local remFeedback: RemoteEvent
local remBuyWeapon: RemoteEvent
local remEquipWeapon: RemoteEvent
local remFireWeapon: RemoteEvent
local remWeaponUpdate: RemoteEvent
local remCelebrate: RemoteEvent

-- Per-player next-allowed fire time (os.clock; set only on a HIT).
local cooldownUntil: { [number]: number } = {}

local function tierFor(id: string?): WeaponTier?
	if not id then
		return nil
	end
	for _, tier in GameConfig.WeaponTiers :: { WeaponTier } do
		if tier.id == id then
			return tier
		end
	end
	return nil
end

-- Condiment color per blaster (handle tint + splat burst).
local function colorFor(id: string): Color3
	if id == "mustardSquirter" then
		return Theme.Palette.Mustard
	elseif id == "ketchupCannon" then
		return Theme.Palette.Ketchup
	elseif id == "relishRepeller" then
		return Theme.Palette.Relish
	end
	return Theme.Palette.Steel
end

-- Send the blaster catalog + owned set + equipped id + coin balance to the client.
-- Also called from Main.pushAllState (handshake).
function WeaponService.pushState(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remWeaponUpdate:FireClient(
		player,
		GameConfig.WeaponTiers,
		data.weaponsOwned,
		data.weaponEquipped,
		data.coins
	)
end

-- === Firing (Tool click OR FireWeapon remote — one validated path) ===
local function rootOf(player: Player): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function fire(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local entry = tierFor(data.weaponEquipped)
	if not entry then
		return
	end
	local now = os.clock()
	if now < (cooldownUntil[player.UserId] or 0) then
		return
	end
	local root = rootOf(player)
	local plotCenter = PlotManager.plotCenterOf(player)
	if not (root and plotCenter) then
		return
	end

	-- Nearest carrying thief within range of the firer.
	local carrier: Player? = nil
	local bestDist = WEAPON_RANGE
	for _, other in Players:GetPlayers() do
		if other ~= player and StealService.isCarrying(other) then
			local otherRoot = rootOf(other)
			if otherRoot then
				local dist = (otherRoot.Position - root.Position).Magnitude
				if dist <= bestDist then
					carrier = other
					bestDist = dist
				end
			end
		end
	end
	if not carrier then
		remFeedback:FireClient(player, false, "No carrying thief in range!")
		return
	end
	local carrierRoot = rootOf(carrier) :: BasePart
	-- Defense only: the thief must be raiding YOUR stand, not crossing the street.
	if (carrierRoot.Position - plotCenter).Magnitude > PLOT_DEFENSE_RADIUS then
		remFeedback:FireClient(player, false, "Blasters only work defending your own stand!")
		return
	end

	local char = carrier.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if entry.effect == "slow" then
		-- Halve (etc.) the carry speed briefly; restore only if still our slow so we
		-- never stomp a net/trap stun (same guard as the gate).
		local slowSpeed = math.max(2, GameConfig.CarryWalkSpeed * (1 - entry.magnitude))
		if humanoid.WalkSpeed > slowSpeed then
			humanoid.WalkSpeed = slowSpeed
			local slowed = carrier -- captured for the restore closure
			task.delay(SLOW_SECONDS, function()
				if humanoid.Parent and humanoid.WalkSpeed == slowSpeed then
					humanoid.WalkSpeed = if StealService.isCarrying(slowed)
						then GameConfig.CarryWalkSpeed
						else GameConfig.NormalWalkSpeed
				end
			end)
		end
	elseif entry.effect == "knockback" then
		local away = carrierRoot.Position - root.Position
		local flat = Vector3.new(away.X, 0, away.Z)
		local dir = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
		carrierRoot.AssemblyLinearVelocity = dir * entry.magnitude
			+ Vector3.new(0, entry.magnitude * 0.5, 0)
	elseif entry.effect == "stun" then
		-- Freeze briefly; NEVER damage (reuses the net's stun path).
		DefenseService.stun(carrier, entry.magnitude)
	end

	cooldownUntil[player.UserId] = now + entry.cooldown
	remCelebrate:FireAllClients("splat", carrierRoot, colorFor(entry.id))
	remFeedback:FireClient(player, true, "🎯 Splatted " .. carrier.DisplayName .. "!")
	remFeedback:FireClient(carrier, false, "You got splatted — " .. entry.label .. "!")
end

-- === The physical blaster Tool ===
local function giveBlaster(player: Player, entry: WeaponTier)
	-- One blaster at a time: clear any previous tool first.
	local containers: { Instance } = {}
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		table.insert(containers, backpack)
	end
	if player.Character then
		table.insert(containers, player.Character :: Instance)
	end
	for _, container in containers do
		local old = container:FindFirstChild("CondimentBlaster")
		if old then
			old:Destroy()
		end
	end

	local tool = Instance.new("Tool")
	tool.Name = "CondimentBlaster"
	tool.ToolTip = entry.label .. " — blast a thief raiding your stand!"
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.9, 0.9, 2.6)
	handle.Color = colorFor(entry.id)
	handle.Material = Enum.Material.Neon
	handle.CastShadow = false
	handle.Parent = tool

	tool.Activated:Connect(function()
		fire(player)
	end)
	tool.Parent = player:FindFirstChildOfClass("Backpack") or player.Character
end

-- === Buy / equip ===
local function onEquip(player: Player, id: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	if not data.weaponsOwned[id] then
		remFeedback:FireClient(player, false, "You don't own that blaster yet.")
		return
	end
	local entry = tierFor(id)
	if not entry then
		return
	end
	data.weaponEquipped = id
	giveBlaster(player, entry)
	WeaponService.pushState(player)
	remFeedback:FireClient(player, true, "🔫 " .. entry.label .. " equipped!")
end

local function onBuy(player: Player, id: string)
	local data = DataManager.get(player)
	local entry = tierFor(id)
	if not (data and entry) then
		return
	end
	if data.weaponsOwned[id] then
		remFeedback:FireClient(player, false, "You already own the " .. entry.label .. ".")
		return
	end
	if data.coins < entry.cost then
		remFeedback:FireClient(
			player,
			false,
			"Need " .. entry.cost .. " coins for the " .. entry.label .. "."
		)
		return
	end
	data.coins -= entry.cost
	data.weaponsOwned[id] = true
	updateLeaderstats(player)
	remFeedback:FireClient(player, true, "🔫 Bought the " .. entry.label .. "!")
	if data.weaponEquipped == nil then
		onEquip(player, id) -- first blaster auto-equips (also pushes state)
	else
		WeaponService.pushState(player)
	end
end

function WeaponService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remBuyWeapon = deps.remotes:WaitForChild("BuyWeapon") :: RemoteEvent
	remEquipWeapon = deps.remotes:WaitForChild("EquipWeapon") :: RemoteEvent
	remFireWeapon = deps.remotes:WaitForChild("FireWeapon") :: RemoteEvent
	remWeaponUpdate = deps.remotes:WaitForChild("WeaponUpdate") :: RemoteEvent
	remCelebrate = deps.remotes:WaitForChild("Celebrate") :: RemoteEvent

	remBuyWeapon.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "BuyWeapon", 5) then
			return
		end
		if type(id) == "string" then
			onBuy(player, id)
		end
	end)
	remEquipWeapon.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "EquipWeapon", 5) then
			return
		end
		if type(id) == "string" then
			onEquip(player, id)
		end
	end)
	remFireWeapon.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "FireWeapon", 20) then
			return
		end
		-- The server picks the target; a client-supplied target is never trusted.
		fire(player)
	end)

	-- Re-hand the equipped blaster on every spawn (covers players already present).
	local function setupSpawns(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				local data = DataManager.get(player)
				local entry = data and tierFor(data.weaponEquipped)
				if entry then
					giveBlaster(player, entry)
				end
			end)
		end)
		local data = DataManager.get(player)
		local entry = data and tierFor(data.weaponEquipped)
		if entry and player.Character then
			giveBlaster(player, entry)
		end
	end
	Players.PlayerAdded:Connect(setupSpawns)
	for _, player in Players:GetPlayers() do
		setupSpawns(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		cooldownUntil[player.UserId] = nil
	end)
end

return WeaponService
