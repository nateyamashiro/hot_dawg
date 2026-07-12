--!strict
-- Leaderboards (M4, GDD §4.7). Global top-N for richest (coins), most steals, and
-- rarest collection — backed by OrderedDataStore (see docs/roblox-reference for
-- GetSortedAsync). Each player's stats are submitted on an interval; the top-N is
-- fetched, cached, and pushed to clients. Untrusted client only asks which board to
-- show. Mirrors DataManager's DataStore usage for the store wiring.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GlizzyModel = require(ReplicatedStorage.Shared.GlizzyModel)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local Theme = require(ReplicatedStorage.Shared.Theme)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local LeaderboardService = {}

local remLeaderboardUpdate: RemoteEvent
local remRequestLeaderboard: RemoteEvent

-- One OrderedDataStore per board.
local boards = {
	coins = DataStoreService:GetOrderedDataStore("StealAGlizzy_LB_Coins_v1"),
	steals = DataStoreService:GetOrderedDataStore("StealAGlizzy_LB_Steals_v1"),
	rarest = DataStoreService:GetOrderedDataStore("StealAGlizzy_LB_Rarest_v1"),
}

-- Cached top-N per board (list of { name, value }), refreshed on an interval.
local cachedTops: { [string]: { { name: string, value: number } } } = {
	coins = {},
	steals = {},
	rarest = {},
}

-- A single numeric "rarest" score derived from a player's inventory: the income/sec
-- of their single best unit (variant-scaled, so a Gold dog outranks its plain twin),
-- ×100 because OrderedDataStore only takes integers. sortedUnits sorts descending.
local function rarestScore(data: DataManager.PlayerData): number
	local units = HotDogDex.sortedUnits(data.hotDogs)
	local best = units[1]
	return if best then math.floor(best.income * 100) else 0
end

-- UserId -> display name, cached for the server's lifetime (the web lookup is slow
-- and rate-limited; a stale name for a session is fine for a leaderboard).
local nameCache: { [number]: string } = {}
local function nameForUserId(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local resolved = if ok and type(name) == "string" then name else "Player " .. userId
	nameCache[userId] = resolved
	return resolved
end

-- Write everyone's current stats into the ordered stores (pcall-guarded like saves).
local function submitScores()
	for _, player in Players:GetPlayers() do
		local data = DataManager.get(player)
		if data then
			local key = "player_" .. player.UserId
			pcall(function()
				boards.coins:SetAsync(key, data.coins)
				boards.steals:SetAsync(key, data.totalSteals)
				boards.rarest:SetAsync(key, rarestScore(data))
			end)
		end
	end
end

-- Refresh cachedTops for each board from its ordered store.
local function refreshTops()
	for boardName, store in boards do
		local ok, page = pcall(function()
			return store:GetSortedAsync(false, GameConfig.LeaderboardTopN)
		end)
		if ok and page then
			local out: { { name: string, value: number } } = {}
			for _, entry in page:GetCurrentPage() do
				-- Keys are "player_<UserId>" (see submitScores).
				local userId = tonumber(string.match(tostring(entry.key), "^player_(%d+)$"))
				local name = if userId then nameForUserId(userId) else tostring(entry.key)
				table.insert(out, { name = name, value = entry.value })
			end
			cachedTops[boardName] = out
		end
	end
end

function LeaderboardService.pushLeaderboard(player: Player)
	remLeaderboardUpdate:FireClient(player, cachedTops)
end

-- === World podium (genre-standard flex): the coins top-3, at the street's EAST ===
-- === end plaza (the belt spans ±560 now — additions #11; the obby bookends the ===
-- === west end), rebuilt only when the top-3 changes ===
local PODIUM_X = 660
local PODIUM_TIERS = {
	{ dx = 0, height = 3.4, color = Theme.Palette.VaultGold, scale = 2.2, medal = "🥇" },
	{ dx = -8, height = 2.4, color = Theme.Palette.Steel, scale = 1.7, medal = "🥈" },
	{ dx = 8, height = 1.6, color = Theme.Palette.CharBrown, scale = 1.4, medal = "🥉" },
}
local podiumModel: Model? = nil
local podiumSignature: string? = nil

local function podiumPart(props: { [string]: any }): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic -- matte (Theme rule: no big neon)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(part :: any)[k] = v
	end
	return part
end

local function podiumPlate(parent: BasePart, text: string)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 36)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 90 -- a landmark reads a little farther than stand labels
	bb.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Theme.UI.TitleFont
	label.Text = text
	label.Parent = bb
end

local function rebuildPodium()
	local top = cachedTops.coins
	local signature = ""
	for i = 1, 3 do
		local entry = top[i]
		signature ..= if entry then entry.name .. "=" .. entry.value .. ";" else ";"
	end
	if signature == podiumSignature then
		return -- top-3 unchanged; don't churn parts every refresh
	end
	podiumSignature = signature

	if podiumModel then
		podiumModel:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "GlizzyPodium"

	for rank, tier in PODIUM_TIERS do
		local block = podiumPart({
			Name = "PodiumTier" .. rank,
			Size = Vector3.new(6, tier.height, 6),
			Color = tier.color,
			CFrame = CFrame.new(PODIUM_X + tier.dx, 0.4 + tier.height / 2, 0),
		})
		block.Parent = model

		local entry = top[rank]
		if entry then
			-- A glizzy statue for the champ (random dog each rebuild = variety;
			-- fx off — the podium isn't a particle source).
			local dog = HotDogDex.randomOfRarity("Common")
			if dog then
				local statue = GlizzyModel.build(dog.name, {
					rarity = dog.rarity,
					scale = tier.scale,
					anchored = true,
					fx = false,
				})
				statue.Name = "PodiumStatue"
				local statueY = 0.4 + tier.height + (1.15 * tier.scale) / 2 + 0.05
				statue:PivotTo(
					CFrame.new(PODIUM_X + tier.dx, statueY, 0) * CFrame.Angles(0, math.rad(90), 0)
				)
				statue.Parent = model
			end
			podiumPlate(
				block,
				tier.medal .. " " .. entry.name .. "\n💰 " .. Format.comma(entry.value)
			)
		else
			podiumPlate(block, tier.medal .. " Unclaimed!")
		end
	end

	model.Parent = Workspace
	podiumModel = model
end

function LeaderboardService.init(deps: { remotes: Folder })
	remLeaderboardUpdate = deps.remotes:WaitForChild("LeaderboardUpdate") :: RemoteEvent
	remRequestLeaderboard = deps.remotes:WaitForChild("RequestLeaderboard") :: RemoteEvent

	remRequestLeaderboard.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "RequestLeaderboard", 5) then
			return
		end
		LeaderboardService.pushLeaderboard(player)
	end)

	rebuildPodium() -- empty "Unclaimed!" podium immediately; real names on refresh

	task.spawn(function()
		while true do
			submitScores()
			refreshTops()
			rebuildPodium()
			for _, player in Players:GetPlayers() do
				LeaderboardService.pushLeaderboard(player)
			end
			task.wait(GameConfig.LeaderboardRefreshSeconds)
		end
	end)
end

return LeaderboardService
