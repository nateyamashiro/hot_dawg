--!strict
-- Codes system (M4, GDD §4.7). A creator-marketing lever: players redeem a code
-- from GameConfig.Codes for a one-time coin reward, tracked per player in
-- data.redeemedCodes so each code pays once. Untrusted client only submits a string;
-- the server validates + charges nothing (pure grant). Mirrors DailyService claims.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local CodesService = {}

local updateLeaderstats: (player: Player) -> ()
local remRedeemCode: RemoteEvent
local remFeedback: RemoteEvent

local function onRedeem(player: Player, code: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local normalized = string.upper(code)
	local reward = GameConfig.Codes[normalized]
	if not reward then
		remFeedback:FireClient(player, false, "Invalid code.")
		return
	end
	if data.redeemedCodes[normalized] then
		remFeedback:FireClient(player, false, "You already redeemed that code.")
		return
	end
	-- TODO(M4-codes): support non-coin rewards (dogs/prestige/cosmetics) + expiry.
	data.redeemedCodes[normalized] = true
	data.coins += reward
	updateLeaderstats(player)
	remFeedback:FireClient(player, true, "🎁 Code redeemed: +" .. reward .. " coins!")
end

function CodesService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	remRedeemCode = deps.remotes:WaitForChild("RedeemCode") :: RemoteEvent
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent

	remRedeemCode.OnServerEvent:Connect(function(player, code)
		if not RateLimit.check(player, "RedeemCode", 3, 5) then
			return
		end
		if type(code) == "string" and #code <= 32 then
			onRedeem(player, code)
		end
	end)
end

return CodesService
