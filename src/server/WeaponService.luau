--!strict
-- Non-damaging weapons (Phase 5, visual-overhaul/tycoon plan). Condiment "blasters"
-- that DISRUPT a carrying thief on your plot — slow / knockback / brief stun — with NO
-- health or damage (locked all-ages tone decision). GameConfig.WeaponTiers defines each
-- blaster's cost + effect + magnitude + cooldown. Server owns ownership, the equip, and
-- the authoritative effect application (reusing StealService's carry state); the client
-- only requests buy/equip/fire. Mirrors CosmeticService (buy+equip) + DefenseService.
--
-- SCAFFOLD: buy/equip/fire logic is TODO(Phase5). Today this ships the pushState
-- handshake so the future client panel can render the blaster catalog.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local WeaponService = {}

local updateLeaderstats: (player: Player) -> ()
local remFeedback: RemoteEvent
local remBuyWeapon: RemoteEvent
local remEquipWeapon: RemoteEvent
local remFireWeapon: RemoteEvent
local remWeaponUpdate: RemoteEvent

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

local function onBuy(player: Player, id: string)
	-- TODO(Phase5): validate id in WeaponTiers, not already owned, coins >= cost; charge,
	-- set data.weaponsOwned[id] = true, push.
	local _ = id
	local _ = remFeedback
	updateLeaderstats(player)
	WeaponService.pushState(player)
end

local function onEquip(player: Player, id: string)
	-- TODO(Phase5): validate the player owns id, set data.weaponEquipped, hand them the
	-- blaster tool, push.
	local _ = id
	WeaponService.pushState(player)
end

local function onFire(player: Player, targetUserId: number)
	-- TODO(Phase5): enforce cooldown; only affect a thief CURRENTLY carrying loot on the
	-- firing player's plot; apply the equipped blaster's non-damaging effect
	-- (slow/knockback/stun) via StealService carry state. NEVER apply damage.
	local _ = player
	local _ = targetUserId
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
	remFireWeapon.OnServerEvent:Connect(function(player, targetUserId)
		if not RateLimit.check(player, "FireWeapon", 20) then
			return
		end
		if type(targetUserId) == "number" then
			onFire(player, targetUserId)
		end
	end)
end

return WeaponService
