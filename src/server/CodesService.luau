--!strict
-- Codes system (M4, GDD §4.7). A creator-marketing lever: players redeem a code
-- from GameConfig.Codes for a one-time reward, tracked per player in
-- data.redeemedCodes so each code pays once. Untrusted client only submits a string;
-- the server validates + charges nothing (pure grant). Mirrors DailyService claims.
-- A code's reward is a plain number (coins) or a table:
--   { coins?, dogs? (inventory KEYS — may encode variants like "Plain Dog#Gold"),
--     prestige?, mutationLuck? }
-- Each component reuses its normal grant path's post-grant pushes (dogs →
-- syncDisplay + inventory push, prestige → progression push).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local Variants = require(ReplicatedStorage.Shared.Variants)
local DataManager = require(ServerScriptService.Server.DataManager)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local CodesService = {}

type CodeReward = {
	coins: number?,
	dogs: { string }?,
	prestige: number?,
	mutationLuck: number?,
}

local updateLeaderstats: (player: Player) -> ()
local onInventoryChanged: (player: Player) -> ()
local pushProgression: (player: Player) -> ()
local remRedeemCode: RemoteEvent
local remFeedback: RemoteEvent

local function onRedeem(player: Player, code: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	local normalized = string.upper(code)
	local raw = (GameConfig.Codes :: { [string]: any })[normalized]
	if not raw then
		remFeedback:FireClient(player, false, "Invalid code.")
		return
	end
	if data.redeemedCodes[normalized] then
		remFeedback:FireClient(player, false, "You already redeemed that code.")
		return
	end
	local reward: CodeReward = if type(raw) == "number" then { coins = raw } else raw
	data.redeemedCodes[normalized] = true

	local parts: { string } = {}
	if reward.coins and reward.coins > 0 then
		data.coins += reward.coins
		table.insert(parts, "+" .. Format.comma(reward.coins) .. " coins")
	end
	local grantedDog = false
	for _, key in reward.dogs or {} do
		-- Composite-key rule: never assume a key is a bare dog name — getByKey
		-- validates base + variant in one shot. Mis-authored keys are skipped.
		if HotDogDex.getByKey(key) then
			data.hotDogs[key] = (data.hotDogs[key] or 0) + 1
			grantedDog = true
			table.insert(parts, "+1 " .. Variants.displayName(key))
		end
	end
	if grantedDog then
		PlotManager.syncDisplay(player)
		onInventoryChanged(player)
	end
	if reward.prestige and reward.prestige > 0 then
		data.prestige += reward.prestige
		pushProgression(player)
		table.insert(parts, "+" .. reward.prestige .. " prestige")
	end
	if reward.mutationLuck and reward.mutationLuck > 0 then
		data.mutationLuck += reward.mutationLuck
		table.insert(parts, "+" .. (reward.mutationLuck * 100) .. "% mutation luck")
	end

	if #parts == 0 then
		-- A mis-authored (empty/invalid) reward shouldn't burn the redemption.
		data.redeemedCodes[normalized] = nil
		remFeedback:FireClient(player, false, "Invalid code.")
		return
	end
	updateLeaderstats(player)
	remFeedback:FireClient(player, true, "🎁 Code redeemed: " .. table.concat(parts, ", ") .. "!")
end

function CodesService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	onInventoryChanged: (player: Player) -> (),
	pushProgression: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	onInventoryChanged = deps.onInventoryChanged
	pushProgression = deps.pushProgression
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
