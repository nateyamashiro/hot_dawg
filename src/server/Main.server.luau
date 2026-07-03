--!strict
-- Server entry point. This is the AUTHORITATIVE side: all coin and economy
-- logic lives here so exploiters on the client can't fake purchases or coins.
-- The client only ever *requests* things via RemoteEvents; the server decides.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)

-- === Set up remotes ===
-- We create the RemoteEvent in code so there's nothing to wire up by hand in
-- Studio. The client waits for this same path.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local buyUpgrade = Instance.new("RemoteEvent")
buyUpgrade.Name = "BuyUpgrade"
buyUpgrade.Parent = remotes

-- === Pure helpers ===
-- Coins earned per tick at a given upgrade level.
local function coinsPerTick(upgradeLevel: number): number
	return GameConfig.CoinsPerTick + upgradeLevel * GameConfig.Upgrade.CoinsPerTickBonus
end

-- Cost of the NEXT upgrade when you're currently at `upgradeLevel`.
local function upgradeCost(upgradeLevel: number): number
	return math.floor(GameConfig.Upgrade.BaseCost * (GameConfig.Upgrade.CostGrowth ^ upgradeLevel))
end

-- Create the leaderstats folder so Coins/Upgrade appear on the player list,
-- and so the client has replicated values to read.
local function setupLeaderstats(player: Player, data: DataManager.PlayerData)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.coins
	coins.Parent = leaderstats

	local level = Instance.new("IntValue")
	level.Name = "Upgrade"
	level.Value = data.upgradeLevel
	level.Parent = leaderstats

	leaderstats.Parent = player
	return leaderstats
end

Players.PlayerAdded:Connect(function(player)
	local data = DataManager.load(player)
	local leaderstats = setupLeaderstats(player, data)
	local coinsValue = leaderstats:FindFirstChild("Coins") :: IntValue

	-- Passive income loop: tick coins while the player is in the game.
	task.spawn(function()
		while player.Parent ~= nil do
			task.wait(GameConfig.TickInterval)
			data.coins += coinsPerTick(data.upgradeLevel)
			coinsValue.Value = data.coins
		end
	end)
end)

-- Handle upgrade purchase requests. The server re-checks everything: never
-- trust the client to have "already paid" or to send a valid amount.
buyUpgrade.OnServerEvent:Connect(function(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end

	local cost = upgradeCost(data.upgradeLevel)
	if data.coins < cost then
		return -- Not enough coins; silently ignore.
	end

	data.coins -= cost
	data.upgradeLevel += 1

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins") :: IntValue
		local levelValue = leaderstats:FindFirstChild("Upgrade") :: IntValue
		coinsValue.Value = data.coins
		levelValue.Value = data.upgradeLevel
	end
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
