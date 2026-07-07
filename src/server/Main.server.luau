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

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local StealService = require(ServerScriptService.Server.StealService)
local DefenseService = require(ServerScriptService.Server.DefenseService)
local UpgradeService = require(ServerScriptService.Server.UpgradeService)
local RebirthService = require(ServerScriptService.Server.RebirthService)
local DailyService = require(ServerScriptService.Server.DailyService)

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
remotes.Parent = ReplicatedStorage

-- === Pure helpers ===
local function incomePerSecond(data: DataManager.PlayerData): number
	local total = 0
	for name, count in data.hotDogs do
		local dog = HotDogDex.get(name)
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

-- Permanent income multiplier earned from rebirths (item 6).
local function incomeMultiplier(data: DataManager.PlayerData): number
	return 1 + data.rebirths * GameConfig.RebirthIncomeBonus
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
	for _, dog in HotDogDex.all() do
		if (data.hotDogs[dog.name] or 0) <= 0 then
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
local function doCook(player: Player, data: DataManager.PlayerData): HotDogDex.HotDog
	data.cooksSinceRare += 1
	local guaranteeRare = data.cooksSinceRare >= GameConfig.PityCooks
	local dog = HotDogDex.roll(data.grillLvl, guaranteeRare)
	if HotDogDex.rarityRank(dog.rarity) >= 3 then
		data.cooksSinceRare = 0 -- pity satisfied by a Rare-or-better
	end
	data.hotDogs[dog.name] = (data.hotDogs[dog.name] or 0) + 1
	DailyService.progress(player, "cook", 1)
	return dog
end

-- === Build the world & init services ===
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
	StealService.pushStats(player)

	-- Capped offline earnings (item 7): pay out income for time away since last save.
	local elapsed = math.clamp(os.time() - data.lastSeen, 0, GameConfig.OfflineCapSeconds)
	local perSec = incomePerSecond(data)
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
				local income = incomePerSecond(live)
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
cookHotDog.OnServerEvent:Connect(function(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	if data.coins < GameConfig.CookCost then
		return -- Not enough coins; silently ignore.
	end

	data.coins -= GameConfig.CookCost
	local dog = doCook(player, data)

	updateLeaderstats(player)
	PlotManager.syncDisplay(player)
	pushInventory(player)
	pushCookStats(player)
	cookResult:FireClient(player, dog.name, dog.rarity)
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
	local results: { { name: string, rarity: HotDogDex.Rarity } } = {}
	for _ = 1, n do
		local dog = doCook(player, data)
		table.insert(results, { name = dog.name, rarity = dog.rarity })
	end

	updateLeaderstats(player)
	PlotManager.syncDisplay(player)
	pushInventory(player)
	pushCookStats(player)
	cookTenResult:FireClient(player, results)
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
