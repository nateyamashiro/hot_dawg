--!strict
-- Server entry point / orchestrator. This is the AUTHORITATIVE side: all coin,
-- cooking, inventory, steal, and defense logic lives on the server so exploiters
-- on the client can't fake coins or spawn rare hot dogs. The client only ever
-- *requests* things via RemoteEvents.
--
-- This file wires the pieces together:
--   PlotManager   — physical stands, stealable display, vault.
--   StealService  — grab/carry/deposit rules, charges, cooldowns, shield.
--   DefenseService— net tool, wall, guard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BuildGrants = require(ReplicatedStorage.Shared.BuildGrants)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local Variants = require(ReplicatedStorage.Shared.Variants)
local DataManager = require(ServerScriptService.Server.DataManager)
local EnvironmentService = require(ServerScriptService.Server.EnvironmentService)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local StealService = require(ServerScriptService.Server.StealService)
local DefenseService = require(ServerScriptService.Server.DefenseService)
local UpgradeService = require(ServerScriptService.Server.UpgradeService)
local RebirthService = require(ServerScriptService.Server.RebirthService)
local DailyService = require(ServerScriptService.Server.DailyService)
local ShopService = require(ServerScriptService.Server.ShopService)
-- M3-remainder → M6 systems (scaffold stubs; see each service for its TODOs).
local MutationService = require(ServerScriptService.Server.MutationService)
local PrestigeShopService = require(ServerScriptService.Server.PrestigeShopService)
local FusionService = require(ServerScriptService.Server.FusionService)
local EventService = require(ServerScriptService.Server.EventService)
local LeaderboardService = require(ServerScriptService.Server.LeaderboardService)
local AchievementService = require(ServerScriptService.Server.AchievementService)
local CodesService = require(ServerScriptService.Server.CodesService)
local PurchaseService = require(ServerScriptService.Server.PurchaseService)
local CosmeticService = require(ServerScriptService.Server.CosmeticService)
local TradeService = require(ServerScriptService.Server.TradeService)
local EmoteService = require(ServerScriptService.Server.EmoteService)
-- Visual-overhaul / tycoon-layer systems (scaffold stubs; see each service for TODOs).
local AutoCookerService = require(ServerScriptService.Server.AutoCookerService)
local BuildService = require(ServerScriptService.Server.BuildService)
local WeaponService = require(ServerScriptService.Server.WeaponService)
local ConveyorService = require(ServerScriptService.Server.ConveyorService)
local UpgraderService = require(ServerScriptService.Server.UpgraderService)
local ZoneService = require(ServerScriptService.Server.ZoneService)

-- === Set up remotes ===
-- Created in code so there's nothing to wire up by hand in Studio. The client
-- waits for these same paths.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"

local function makeRemote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

local cookHotDog = makeRemote("CookHotDog") -- client -> server: "cook one"
local cookResult = makeRemote("CookResult") -- server -> client: reveal popup
makeRemote("StealAlert") -- server -> victim: "you're being robbed"
makeRemote("CarryUpdate") -- server -> thief: carrying on/off
local stealFeedback = makeRemote("StealFeedback") -- server -> player: toast messages
makeRemote("StatsUpdate") -- server -> player: steal charges + shield
makeRemote("BuyDefense") -- client -> server: buy wall/guard
-- === M3 progression remotes ===
makeRemote("BuyUpgrade") -- client -> server: buy grill/display/vault (UpgradeService)
makeRemote("Rebirth") -- client -> server: rebirth (RebirthService)
makeRemote("DailyUpdate") -- server -> client: streak + missions (DailyService)
makeRemote("ClaimDaily") -- client -> server: claim streak reward (DailyService)
makeRemote("ClaimMission") -- client -> server: claim a mission (DailyService)
local welcomeBack = makeRemote("WelcomeBack") -- server -> client: offline earnings popup
local inventoryUpdate = makeRemote("InventoryUpdate") -- server -> client: owned dogs snapshot
local cookTen = makeRemote("CookTen") -- client -> server: "cook ten"
local cookTenResult = makeRemote("CookTenResult") -- server -> client: 10-roll summary
local cookStats = makeRemote("CookStats") -- server -> client: grill level + pity progress
local progressionUpdate = makeRemote("ProgressionUpdate") -- server -> client: levels/rebirths
local requestState = makeRemote("RequestState") -- client -> server: "I'm ready, send my state"
makeRemote("BuyFromShop") -- client -> server: buy a dog from the rotating shop (ShopService)
makeRemote("ShopUpdate") -- server -> client: today's shop offers + refresh timer (ShopService)
-- === M3-remainder → M6 remotes (scaffold) ===
makeRemote("BuyPrestige") -- c -> s: spend prestige (PrestigeShopService)
makeRemote("PrestigeShopUpdate") -- s -> c: prestige catalog + balance
makeRemote("Fuse") -- c -> s: fuse duplicates (FusionService)
local setVaultPin = makeRemote("SetVaultPin") -- c -> s: pin/unpin a dog as vault-safe
makeRemote("EventUpdate") -- s -> c: active weekly event (EventService)
makeRemote("ClaimEventReward") -- c -> s: claim an event reward tier
makeRemote("LeaderboardUpdate") -- s -> c: cached top-N boards (LeaderboardService)
makeRemote("RequestLeaderboard") -- c -> s: refresh a board
makeRemote("AchievementUpdate") -- s -> c: achievement progress (AchievementService)
makeRemote("ClaimAchievement") -- c -> s: claim a completed achievement
makeRemote("RedeemCode") -- c -> s: redeem a promo code (CodesService)
makeRemote("PromptPurchase") -- c -> s: prompt a pass/product purchase (PurchaseService)
makeRemote("PurchaseUpdate") -- s -> c: owned-pass status
makeRemote("BuyCosmetic") -- c -> s: buy a cosmetic (CosmeticService)
makeRemote("EquipCosmetic") -- c -> s: equip a cosmetic
makeRemote("CosmeticUpdate") -- s -> c: cosmetic catalog + owned/equipped
makeRemote("TradeRequest") -- c -> s: request a trade (TradeService)
makeRemote("TradeUpdate") -- both: set offer / broadcast session state
makeRemote("TradeConfirm") -- c -> s: confirm your side
makeRemote("TradeCancel") -- c -> s: cancel the trade
makeRemote("PlayEmote") -- both: request an emote / broadcast to others (EmoteService)
-- === Visual-overhaul / tycoon-layer remotes (scaffold) ===
makeRemote("BuyAutoCooker") -- c -> s: upgrade the passive auto-cooker (AutoCookerService)
makeRemote("AutoCookerUpdate") -- s -> c: auto-cooker tiers + level + balance
makeRemote("Build") -- c -> s: construct a base structure (BuildService)
makeRemote("BuildUpdate") -- s -> c: build catalog + constructed set + balance
makeRemote("BuyWeapon") -- c -> s: buy a non-damaging blaster (WeaponService)
makeRemote("EquipWeapon") -- c -> s: equip a blaster
makeRemote("FireWeapon") -- c -> s: fire the equipped blaster at a carrying thief
makeRemote("WeaponUpdate") -- s -> c: blaster catalog + owned/equipped + balance
makeRemote("BuyUpgrader") -- c -> s: upgrade the cooker upgrader (UpgraderService)
makeRemote("UpgraderUpdate") -- s -> c: upgrader tiers + level + balance
makeRemote("BuyZone") -- c -> s: expand plot zone with prestige (ZoneService)
makeRemote("ZoneUpdate") -- s -> c: zone tiers + level + prestige balance
-- === Juice (P-C) ===
-- s -> c one-shot celebration: (kind, target: BasePart|Vector3, extra?). Kinds:
-- "cook" (burst at the station, extra=rarity), "purchase" (pad flash + label pop),
-- "build" (dust puff at the plot), "stealAlarm" (red flashes on the victim's sign),
-- "giantShake" (camera shake near a Giant grab). Rendered by Celebrate.client.
local celebrate = makeRemote("Celebrate")
remotes.Parent = ReplicatedStorage

-- === Pure helpers ===
local function incomePerSecond(data: DataManager.PlayerData): number
	local total = 0
	for key, count in data.hotDogs do
		-- getByKey decodes composite keys, so a minted variant pays its scaled income.
		local dog = HotDogDex.getByKey(key)
		if dog then
			total += dog.income * count
		end
	end
	return total
end

local function totalDogs(data: DataManager.PlayerData): number
	local total = 0
	for _, count in data.hotDogs do
		total += count
	end
	return total
end

-- Push the authoritative numbers into leaderstats so they replicate to the
-- client (and show on the player list).
local function updateLeaderstats(player: Player)
	local data = DataManager.get(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not (data and leaderstats) then
		return
	end
	(leaderstats:FindFirstChild("Coins") :: IntValue).Value = data.coins;
	(leaderstats:FindFirstChild("Dogs") :: IntValue).Value = totalDogs(data);
	(leaderstats:FindFirstChild("Steals") :: IntValue).Value = data.totalSteals;
	(leaderstats:FindFirstChild("Rebirths") :: IntValue).Value = data.rebirths
end

local function setupLeaderstats(player: Player, data: DataManager.PlayerData)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.coins
	coins.Parent = leaderstats

	local dogs = Instance.new("IntValue")
	dogs.Name = "Dogs"
	dogs.Value = totalDogs(data)
	dogs.Parent = leaderstats

	local steals = Instance.new("IntValue")
	steals.Name = "Steals"
	steals.Value = data.totalSteals
	steals.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = data.rebirths
	rebirths.Parent = leaderstats

	leaderstats.Parent = player
end

-- Permanent income multiplier: rebirths (item 6) + prestige-shop income unlocks
-- (data.prestigeIncomeMult, banked by PrestigeShopService) + built decor
-- (BuildGrants.incomeBonus — derived from data.built at read time, never banked).
-- All additive. Offline earnings and the live tick both call this, so decor income
-- applies everywhere automatically.
local function incomeMultiplier(data: DataManager.PlayerData): number
	return 1
		+ data.rebirths * GameConfig.RebirthIncomeBonus
		+ data.prestigeIncomeMult
		+ BuildGrants.incomeBonus(data.built)
end

-- === Client state pushes (server -> client snapshots) ===
local function pushCookStats(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	cookStats:FireClient(player, data.grillLvl, data.cooksSinceRare, GameConfig.PityCooks)
end

local function pushProgression(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	progressionUpdate:FireClient(player, {
		grillLvl = data.grillLvl,
		displaySlotsLvl = data.displaySlotsLvl,
		vaultSlotsLvl = data.vaultSlotsLvl,
		rebirths = data.rebirths,
		prestige = data.prestige,
	})
end

local function ownsEveryDog(data: DataManager.PlayerData): boolean
	-- Collapse composite keys to their base dog: owning a Gold variant still credits
	-- the base dog toward dex completion.
	local ownedBase: { [string]: boolean } = {}
	for key, count in data.hotDogs do
		if count > 0 then
			ownedBase[Variants.baseName(key)] = true
		end
	end
	for _, dog in HotDogDex.all() do
		if not ownedBase[dog.name] then
			return false
		end
	end
	return true
end

-- Send the owned-dogs snapshot for the dex (item 8) and, once the collection is
-- complete, grant the one-time completion reward.
local function pushInventory(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	inventoryUpdate:FireClient(player, data.hotDogs)
	if not data.dexRewarded and ownsEveryDog(data) then
		data.dexRewarded = true
		data.coins += GameConfig.DexCompletionReward
		data.prestige += GameConfig.DexCompletionPrestige
		updateLeaderstats(player)
		pushProgression(player)
		stealFeedback:FireClient(
			player,
			true,
			"🏆 Dex complete! +" .. GameConfig.DexCompletionReward .. " coins!"
		)
	end
end

-- Roll one hot dog for `player`, applying grill odds + pity, and bank it. Shared by
-- cook-1 and cook-10. Returns the rolled dog (caller charges coins + pushes state).
local function doCook(player: Player, data: DataManager.PlayerData): (HotDogDex.HotDog, string)
	data.cooksSinceRare += 1
	local guaranteeRare = data.cooksSinceRare >= GameConfig.PityCooks
	local dog = HotDogDex.roll(data.grillLvl, guaranteeRare)
	if HotDogDex.rarityRank(dog.rarity) >= 3 then
		data.cooksSinceRare = 0 -- pity satisfied by a Rare-or-better
	end
	-- Random mutation on acquire (GDD §4.4): maybeMint returns the inventory KEY to
	-- bank — a composite "Name#Variant" when it mutates, or the plain name otherwise.
	-- Income, pedestals/vault, and dex credit are all variant-aware, so a minted key
	-- is fully live. Returns the base dog (for the reveal) plus the banked key.
	-- data.mutationLuck (banked by the prestige "+mutation luck" unlock) raises the odds.
	local key = MutationService.maybeMint(dog.name, data.mutationLuck)
	data.hotDogs[key] = (data.hotDogs[key] or 0) + 1
	DailyService.progress(player, "cook", 1)
	return dog, key
end

-- === Build the world & init services ===
EnvironmentService.init() -- lighting + street/ground FIRST so plots land on a real place
PlotManager.build()
StealService.init({
	remotes = remotes,
	updateLeaderstats = updateLeaderstats,
	onInventoryChanged = pushInventory,
	onSteal = function(player)
		DailyService.progress(player, "steal", 1)
	end,
})
DefenseService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
UpgradeService.init({
	remotes = remotes,
	updateLeaderstats = updateLeaderstats,
	pushCookStats = pushCookStats,
	pushProgression = pushProgression,
})
RebirthService.init({
	remotes = remotes,
	updateLeaderstats = updateLeaderstats,
	pushProgression = pushProgression,
})
DailyService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
ShopService.init({
	remotes = remotes,
	updateLeaderstats = updateLeaderstats,
	onInventoryChanged = pushInventory,
})
-- === M3-remainder → M6 services (scaffold stubs) ===
PrestigeShopService.init({
	remotes = remotes,
	updateLeaderstats = updateLeaderstats,
	pushProgression = pushProgression,
})
FusionService.init({
	remotes = remotes,
	updateLeaderstats = updateLeaderstats,
	onInventoryChanged = pushInventory,
})
EventService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
LeaderboardService.init({ remotes = remotes })
AchievementService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
CodesService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
PurchaseService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
CosmeticService.init({ remotes = remotes })
TradeService.init({ remotes = remotes })
EmoteService.init({ remotes = remotes })
-- === Visual-overhaul / tycoon-layer services (scaffold stubs) ===
AutoCookerService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
BuildService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
WeaponService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
ConveyorService.init({
	remotes = remotes,
	updateLeaderstats = updateLeaderstats,
	onInventoryChanged = pushInventory,
})
UpgraderService.init({ remotes = remotes, updateLeaderstats = updateLeaderstats })
ZoneService.init({
	remotes = remotes,
	updateLeaderstats = updateLeaderstats,
	pushProgression = pushProgression,
})

-- === Physical tycoon stations (walk-on pads + cook grill) ===
-- Cook one glizzy for `player` (charge + roll + reveal). Shared by the on-screen Cook
-- button (CookHotDog remote) and the physical cook-station ProximityPrompt.
local function cookOne(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	-- Free, but gated behind a cooldown (the glizzy "wall"). Cook-10 is the paid bypass.
	local now = os.time()
	if now < data.cookReadyAt then
		local remaining = data.cookReadyAt - now
		stealFeedback:FireClient(player, false, "⏳ Next free glizzy in " .. remaining .. "s")
		return
	end
	data.cookReadyAt = now + GameConfig.CookCooldownSeconds
	local dog, key = doCook(player, data)
	local _, variant = Variants.decode(key)
	updateLeaderstats(player)
	PlotManager.syncDisplay(player)
	pushInventory(player)
	pushCookStats(player)
	cookResult:FireClient(player, dog.name, dog.rarity, variant)
	local station = PlotManager.cookStationOf(player)
	if station then
		celebrate:FireAllClients("cook", station, dog.rarity)
	end
end

-- Compute which walk-on pads are available (+ their cost labels) for the player and push
-- that to PlotManager, plus (re)render the physical stove for the current level.
local function syncPads(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local info: { [string]: { text: string, affordable: boolean } } = {}
	local stoveNext = GameConfig.AutoCookerTiers[data.autoCookerLvl + 1]
	if stoveNext then
		local verb = if data.autoCookerLvl == 0
			then "🔥 Build Stove"
			else "🔥 Stove Lv " .. (data.autoCookerLvl + 1)
		local cost = if stoveNext.cost > 0 then "$" .. stoveNext.cost else "FREE"
		info.stove = { text = verb .. "\n" .. cost, affordable = data.coins >= stoveNext.cost }
	end
	local grillNext = GameConfig.GrillLevels[data.grillLvl + 1]
	if grillNext then
		info.grill = {
			text = "🔥 Grill Lv " .. (data.grillLvl + 1) .. "\n$" .. grillNext.cost,
			affordable = data.coins >= grillNext.cost,
		}
	end
	local displayNext = GameConfig.DisplaySlotLevels[data.displaySlotsLvl + 1]
	if displayNext then
		info.display = {
			text = "🅿️ +Display\n$" .. displayNext.cost,
			affordable = data.coins >= displayNext.cost,
		}
	end
	local vaultNext = GameConfig.VaultSlotLevels[data.vaultSlotsLvl + 1]
	if vaultNext then
		info.vault = {
			text = "🔒 +Vault\n$" .. vaultNext.cost,
			affordable = data.coins >= vaultNext.cost,
		}
	end
	-- Building pads: each offers exactly ONE item — the next structural / decor
	-- catalog entry (BuildService re-derives on step; the label is advisory only).
	-- Omitting the key hides the pad once its category is exhausted.
	local buildNext = BuildService.nextEntry(data, "build")
	if buildNext then
		info.build = {
			text = "🏗️ " .. buildNext.label .. "\n$" .. buildNext.cost,
			affordable = data.coins >= buildNext.cost,
		}
	end
	local decorNext = BuildService.nextEntry(data, "decor")
	if decorNext then
		info.decor = {
			text = "🎪 " .. decorNext.label .. "\n$" .. decorNext.cost,
			affordable = data.coins >= decorNext.cost,
		}
	end
	-- ⚙️ Upgrader: multiplies stove output, so it only appears once the stove exists.
	if data.autoCookerLvl >= 1 then
		local upgraderNext = GameConfig.UpgraderTiers[data.upgraderLvl + 1]
		if upgraderNext then
			info.upgrader = {
				text = "⚙️ Upgrader Lv "
					.. (data.upgraderLvl + 1)
					.. "\n$"
					.. upgraderNext.cost,
				affordable = data.coins >= upgraderNext.cost,
			}
		end
	end
	-- 🌍 Zone expansion: priced in PRESTIGE (the framework's affordable flag is just
	-- a bool, so prestige-affordability drives the green/red exactly like coins).
	local zoneNext = GameConfig.ZoneTiers[data.zoneLvl + 1]
	if zoneNext then
		info.zone = {
			text = "🌍 Expand Zone\n✨" .. zoneNext.prestigeCost,
			affordable = data.prestige >= zoneNext.prestigeCost,
		}
	end
	PlotManager.updatePads(player, info)
	PlotManager.setStove(player, data.autoCookerLvl, AutoCookerService.coinsPerSecond(data))
end

PlotManager.setCookHandler(cookOne)
PlotManager.setPadHandler(function(player: Player, padId: string)
	local bought = false
	if padId == "stove" then
		bought = AutoCookerService.tryUpgrade(player)
	elseif padId == "grill" or padId == "display" or padId == "vault" then
		bought = UpgradeService.tryBuy(player, padId)
	elseif padId == "build" or padId == "decor" then
		bought = BuildService.tryBuildNext(player, padId)
	elseif padId == "upgrader" then
		bought = UpgraderService.tryUpgrade(player)
	elseif padId == "zone" then
		bought = ZoneService.tryUpgrade(player)
	end
	if bought then
		-- Purchase pop (P-C): flash the pad + pop its label on every watching client.
		local padPart = PlotManager.padPartOf(player, padId)
		if padPart then
			celebrate:FireAllClients("purchase", padPart)
		end
	end
	syncPads(player) -- refresh labels/visibility after any purchase
end)

-- Manual vault selection (M2 fast-follow): toggle whether a dog key is pinned safe.
-- PlotManager.syncDisplay honours data.vaultPins (see its TODO). Kept here as a tiny
-- handler until the Dex pin UI is built. Server-authoritative + rate-limited.
setVaultPin.OnServerEvent:Connect(function(player: Player, key)
	if type(key) ~= "string" then
		return
	end
	local data = DataManager.get(player)
	if not data then
		return
	end
	if data.vaultPins[key] then
		data.vaultPins[key] = nil
	else
		data.vaultPins[key] = true
	end
	PlotManager.syncDisplay(player)
	pushInventory(player)
end)

-- === Player lifecycle ===
-- Offline earnings computed at join, delivered once the client asks for state (so
-- the "welcome back" popup can't be lost to the join race).
local pendingWelcome: { [number]: { earned: number, elapsed: number } } = {}

-- Send every per-player state snapshot to a client (on join AND when the client
-- signals it's ready via RequestState — the latter fixes the "server pushed before
-- the client's handlers connected" race).
local function pushAllState(player: Player)
	StealService.pushStats(player)
	pushInventory(player)
	pushCookStats(player)
	pushProgression(player)
	DailyService.onJoin(player)
	ShopService.pushShop(player)
	-- New initial-state pushes MUST live here too (they ride the RequestState
	-- handshake past the join race) — see the handoff notes.
	PrestigeShopService.pushShop(player)
	EventService.pushEvent(player)
	LeaderboardService.pushLeaderboard(player)
	AchievementService.pushAchievements(player)
	CosmeticService.pushCosmetics(player)
	PurchaseService.pushStatus(player)
	AutoCookerService.pushState(player)
	BuildService.pushState(player)
	WeaponService.pushState(player)
	UpgraderService.pushState(player)
	ZoneService.pushState(player)
	syncPads(player) -- reveal the walk-on pads + render the stove for this player
	local welcome = pendingWelcome[player.UserId]
	if welcome then
		pendingWelcome[player.UserId] = nil
		welcomeBack:FireClient(player, welcome.earned, welcome.elapsed)
	end
end

requestState.OnServerEvent:Connect(pushAllState)

local function onPlayerAdded(player: Player)
	local data = DataManager.load(player)
	setupLeaderstats(player, data)
	PlotManager.assign(player)
	DefenseService.applyLoadedDefenses(player)
	BuildService.applyLoaded(player) -- re-raise built structures (+ wall hold bonus)
	ZoneService.applyLoaded(player) -- re-apply the expanded pad size
	StealService.pushStats(player)

	-- Capped offline earnings (item 7): pay out income for time away since last save.
	-- Includes the passive stove (un-stealable coin floor) alongside owned-dog income.
	local elapsed = math.clamp(os.time() - data.lastSeen, 0, GameConfig.OfflineCapSeconds)
	local perSec = incomePerSecond(data) + AutoCookerService.coinsPerSecond(data)
	if elapsed > 0 and perSec > 0 then
		local earned = math.floor(perSec * elapsed * incomeMultiplier(data))
		if earned > 0 then
			data.coins += earned
			updateLeaderstats(player)
			pendingWelcome[player.UserId] = { earned = earned, elapsed = elapsed }
		end
	end

	-- Initial pushes (also re-sent on the client's RequestState once its handlers exist).
	pushAllState(player)

	-- Spawn the player beside their own stand (plot is assigned above). Covers both
	-- future respawns and a character that already exists (Studio solo test).
	local function placeAtStand(character: Model)
		local spawnCFrame = PlotManager.getSpawnCFrame(player)
		if not spawnCFrame then
			return
		end
		-- Wait for the root so PivotTo lands the whole character, not a stale model.
		character:WaitForChild("HumanoidRootPart", 5)
		character:PivotTo(spawnCFrame)
	end
	player.CharacterAdded:Connect(placeAtStand)
	if player.Character then
		placeAtStand(player.Character)
	end

	-- Passive income loop: earn coins from owned hot dogs each tick.
	task.spawn(function()
		while player.Parent ~= nil do
			task.wait(GameConfig.TickInterval)
			local live = DataManager.get(player)
			if live then
				-- Keep the walk-on pads' green/red affordability colours live as coins tick.
				syncPads(player)
				local income = incomePerSecond(live) + AutoCookerService.coinsPerSecond(live)
				if income > 0 then
					local gain = math.floor(income * incomeMultiplier(live))
					live.coins += gain
					updateLeaderstats(player)
					DailyService.progress(player, "earn", gain)
				end
			end
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
-- Handle any players who joined before this script ran (e.g. Studio solo test).
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- === Cook handlers ===
-- The on-screen Cook button and the physical cook station share cookOne (defined above).
cookHotDog.OnServerEvent:Connect(function(player: Player)
	cookOne(player)
end)

-- Cook-ten (item 9): pay 10× cost up front, roll 10, send a summary of the results.
cookTen.OnServerEvent:Connect(function(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local n = GameConfig.CookTenCount
	local totalCost = GameConfig.CookCost * n
	if data.coins < totalCost then
		stealFeedback:FireClient(
			player,
			false,
			"Need " .. totalCost .. " coins to cook " .. n .. "."
		)
		return
	end

	data.coins -= totalCost
	local results: { { name: string, rarity: HotDogDex.Rarity, variant: Variants.Variant } } = {}
	local bestRarity: HotDogDex.Rarity = "Common"
	for _ = 1, n do
		local dog, key = doCook(player, data)
		local _, variant = Variants.decode(key)
		table.insert(results, { name = dog.name, rarity = dog.rarity, variant = variant })
		if HotDogDex.rarityRank(dog.rarity) > HotDogDex.rarityRank(bestRarity) then
			bestRarity = dog.rarity
		end
	end

	updateLeaderstats(player)
	PlotManager.syncDisplay(player)
	pushInventory(player)
	pushCookStats(player)
	cookTenResult:FireClient(player, results)
	-- One burst for the whole batch, colored by the best pull.
	local station = PlotManager.cookStationOf(player)
	if station then
		celebrate:FireAllClients("cook", station, bestRarity)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	pendingWelcome[player.UserId] = nil
	DataManager.release(player)
end)

-- Save everyone when the server shuts down (also fires on Studio "Stop").
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		DataManager.save(player)
	end
end)
