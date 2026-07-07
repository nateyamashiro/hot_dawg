--!strict
-- Achievements / milestones (M4, GDD §4.7). Non-RNG goals (collect N dogs, 100
-- steals, rebirth X) that grant one-time coin rewards. Progress is read off existing
-- counters/inventory; claimed ids persist in data.achievements so each pays once.
-- Untrusted client only requests a claim. Mirrors DailyService's progress/claim.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local AchievementService = {}

local updateLeaderstats: (player: Player) -> ()
local remAchievementUpdate: RemoteEvent
local remClaimAchievement: RemoteEvent

-- Current value of a tracked metric for the player (dogs owned, steals, rebirths).
local function metricValue(data: DataManager.PlayerData, metric: string): number
	if metric == "steals" then
		return data.totalSteals
	elseif metric == "rebirths" then
		return data.rebirths
	elseif metric == "dogs" then
		local n = 0
		for _, count in data.hotDogs do
			n += count
		end
		return n
	end
	return 0
end

-- Push each achievement's progress + claimed state (handshake: also from pushAllState).
function AchievementService.pushAchievements(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local out = {}
	for _, ach in GameConfig.Achievements do
		table.insert(out, {
			id = ach.id,
			label = ach.label,
			target = ach.target,
			reward = ach.reward,
			progress = metricValue(data, ach.metric),
			claimed = data.achievements[ach.id] == true,
		})
	end
	remAchievementUpdate:FireClient(player, out)
end

local function onClaim(player: Player, id: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	-- TODO(M4-ach): find the achievement by id; if not already claimed AND
	-- metricValue >= target, mark claimed, grant reward coins, updateLeaderstats.
	local _ = id
	updateLeaderstats(player)
	AchievementService.pushAchievements(player)
end

function AchievementService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remAchievementUpdate = deps.remotes:WaitForChild("AchievementUpdate") :: RemoteEvent
	remClaimAchievement = deps.remotes:WaitForChild("ClaimAchievement") :: RemoteEvent

	remClaimAchievement.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "ClaimAchievement", 10) then
			return
		end
		if type(id) == "string" then
			onClaim(player, id)
		end
	end)
end

return AchievementService
