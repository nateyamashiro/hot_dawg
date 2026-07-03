--!strict
-- Server entry point. This is the AUTHORITATIVE side: all coin, cooking, and
-- inventory logic lives here so exploiters on the client can't fake coins or
-- spawn rare hot dogs. The client only ever *requests* things via RemoteEvents.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local DataManager = require(ServerScriptService.Server.DataManager)

-- === Set up remotes ===
-- Created in code so there's nothing to wire up by hand in Studio. The client
-- waits for these same paths.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

-- Client -> server: "please cook a hot dog for me".
local cookHotDog = Instance.new("RemoteEvent")
cookHotDog.Name = "CookHotDog"
cookHotDog.Parent = remotes

-- Server -> client: "here's the hot dog you just got" (for the reveal popup).
local cookResult = Instance.new("RemoteEvent")
cookResult.Name = "CookResult"
cookResult.Parent = remotes

-- === Pure helpers ===
-- Total coins/second this player earns from every hot dog they own.
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

-- Total number of hot dogs owned (across all types).
local function totalDogs(data: DataManager.PlayerData): number
	local total = 0
	for _, count in data.hotDogs do
		total += count
	end
	return total
end

-- Push the authoritative numbers into leaderstats so they replicate to the
-- client (and show on the player list).
local function updateLeaderstats(player: Player, data: DataManager.PlayerData)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local coinsValue = leaderstats:FindFirstChild("Coins") :: IntValue
	local dogsValue = leaderstats:FindFirstChild("Dogs") :: IntValue
	coinsValue.Value = data.coins
	dogsValue.Value = totalDogs(data)
end

-- Create the leaderstats folder (Coins + Dogs) shown on the leaderboard and
-- read by the client UI.
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

	leaderstats.Parent = player
end

Players.PlayerAdded:Connect(function(player)
	local data = DataManager.load(player)
	setupLeaderstats(player, data)

	-- Passive income loop: earn coins from owned hot dogs each tick.
	task.spawn(function()
		while player.Parent ~= nil do
			task.wait(GameConfig.TickInterval)
			local income = incomePerSecond(data)
			if income > 0 then
				data.coins += income
				updateLeaderstats(player, data)
			end
		end
	end)
end)

-- Handle a cook request. The server charges the cost, rolls the hot dog, adds
-- it to the inventory, and tells the client what they got.
cookHotDog.OnServerEvent:Connect(function(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	if data.coins < GameConfig.CookCost then
		return -- Not enough coins; silently ignore.
	end

	data.coins -= GameConfig.CookCost

	local dog = HotDogDex.roll()
	data.hotDogs[dog.name] = (data.hotDogs[dog.name] or 0) + 1

	updateLeaderstats(player, data)
	cookResult:FireClient(player, dog.name, dog.rarity)
end)

Players.PlayerRemoving:Connect(function(player)
	DataManager.release(player)
end)

-- Save everyone when the server shuts down (also fires on Studio "Stop").
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		DataManager.save(player)
	end
end)
