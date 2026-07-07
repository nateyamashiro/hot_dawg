--!strict
-- Trading (M6, GDD §4.8). Baseline-safeguard model: a request → both sides add
-- composite-key stacks → BOTH must confirm → atomic transfer → post-trade cooldown
-- (data.tradeCooldownUntil) → append to a server-side trade log. Any change to an
-- offer clears both confirmations (classic anti-swap-scam). Server authoritative and
-- validates ownership on every step. Ships AFTER the anti-exploit hardening pass —
-- trading is the highest-value exploit target. Mirrors StealService's per-pair state
-- + atomic inventory transfer.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- GameConfig (TradeCooldownSeconds / TradeMaxItems) gets required when the transfer
-- logic lands — see the TODOs below.
local DataManager = require(ServerScriptService.Server.DataManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local TradeService = {}

-- One live trade session between two players.
type Session = {
	a: number, -- initiator UserId
	b: number, -- target UserId
	offerA: { [string]: number }, -- key -> qty A is offering
	offerB: { [string]: number },
	confirmA: boolean,
	confirmB: boolean,
}

-- sessionByUser[userId] -> the session they're in (both parties point to the same).
local sessionByUser: { [number]: Session } = {}

local remTradeRequest: RemoteEvent
local remTradeUpdate: RemoteEvent
local remTradeConfirm: RemoteEvent
local remTradeCancel: RemoteEvent

-- Push the current session state to both parties.
local function pushSession(session: Session)
	for _, uid in { session.a, session.b } do
		local player = Players:GetPlayerByUserId(uid)
		if player then
			remTradeUpdate:FireClient(player, session)
		end
	end
end

local function onRequest(player: Player, targetUserId: number)
	local data = DataManager.get(player)
	if not data then
		return
	end
	if os.time() < data.tradeCooldownUntil then
		return -- still cooling down from a recent trade
	end
	-- TODO(M6-trade): validate the target is nearby/consenting, create a Session,
	-- register both users in sessionByUser, and pushSession.
	local _ = targetUserId
end

local function onConfirm(player: Player)
	local session = sessionByUser[player.UserId]
	if not session then
		return
	end
	-- TODO(M6-trade): mark this side confirmed; when BOTH are confirmed, re-validate
	-- ownership of every offered stack, transfer atomically, stamp
	-- tradeCooldownUntil, append to the trade-log DataStore, then clear the session.
	pushSession(session)
end

local function onCancel(player: Player)
	local session = sessionByUser[player.UserId]
	if not session then
		return
	end
	-- TODO(M6-trade): tear down the session for both parties + pushSession(cleared).
	sessionByUser[session.a] = nil
	sessionByUser[session.b] = nil
end

function TradeService.init(deps: { remotes: Folder })
	remTradeRequest = deps.remotes:WaitForChild("TradeRequest") :: RemoteEvent
	remTradeUpdate = deps.remotes:WaitForChild("TradeUpdate") :: RemoteEvent
	remTradeConfirm = deps.remotes:WaitForChild("TradeConfirm") :: RemoteEvent
	remTradeCancel = deps.remotes:WaitForChild("TradeCancel") :: RemoteEvent

	remTradeRequest.OnServerEvent:Connect(function(player, targetUserId)
		if not RateLimit.check(player, "TradeRequest", 5) then
			return
		end
		if type(targetUserId) == "number" then
			onRequest(player, targetUserId)
		end
	end)

	remTradeUpdate.OnServerEvent:Connect(function(player, offer)
		if not RateLimit.check(player, "TradeUpdate", 20) then
			return
		end
		local session = sessionByUser[player.UserId]
		if not (session and type(offer) == "table") then
			return
		end
		-- TODO(M6-trade): replace this side's offer with `offer` (validating each key
		-- is owned + within GameConfig.TradeMaxItems), CLEAR both confirmations, push.
		session.confirmA = false
		session.confirmB = false
		pushSession(session)
	end)

	remTradeConfirm.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "TradeConfirm", 10) then
			return
		end
		onConfirm(player)
	end)

	remTradeCancel.OnServerEvent:Connect(function(player)
		if not RateLimit.check(player, "TradeCancel", 10) then
			return
		end
		onCancel(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		onCancel(player) -- abort any open trade so the other side is freed
	end)
end

return TradeService
