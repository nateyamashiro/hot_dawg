--!strict
-- Trading (M6, GDD §4.8). Baseline-safeguard model: a request handshake (invite →
-- accept) → both sides set composite-key stack offers → BOTH must confirm → the
-- server re-validates ownership and transfers atomically → post-trade cooldown
-- (data.tradeCooldownUntil) → append to a server-side trade log. Any change to an
-- offer clears both confirmations (classic anti-swap-scam). Items only, NEVER
-- coins. Server authoritative throughout: the client only requests; every offer is
-- validated against live inventory both when set and again at the moment of
-- transfer, so nothing mid-air (steals, fusions, cooks) can duplicate a stack.
--
-- Interactions with the rest of the game are already safe by construction:
-- steal/break prompts guard `(hotDogs[key] or 0) <= 0` (stale prompts no-op), and
-- a hand-held dog whose stack was traded away is force-returned via PickupService.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local DataManager = require(ServerScriptService.Server.DataManager)
local PickupService = require(ServerScriptService.Server.PickupService)
local PlotManager = require(ServerScriptService.Server.PlotManager)
local RateLimit = require(ServerScriptService.Server.RateLimit)
local Telemetry = require(ServerScriptService.Server.Telemetry)

local TradeService = {}

-- One live trade session between two players. Names ride along so the client can
-- caption both columns without lookups.
type Session = {
	a: number, -- initiator UserId
	b: number, -- target UserId
	nameA: string,
	nameB: string,
	offerA: { [string]: number }, -- key -> qty A is offering
	offerB: { [string]: number },
	confirmA: boolean,
	confirmB: boolean,
}

-- sessionByUser[userId] -> the session they're in (both parties point to the same).
local sessionByUser: { [number]: Session } = {}
-- Pending invites keyed by the TARGET's UserId (accept = request back within the
-- expiry window — the mutual handshake needs no extra remote).
local invites: { [number]: { from: number, at: number } } = {}

local remTradeRequest: RemoteEvent
local remTradeUpdate: RemoteEvent
local remTradeConfirm: RemoteEvent
local remTradeCancel: RemoteEvent
local remFeedback: RemoteEvent
local onInventoryChanged: (player: Player) -> ()

local function feedback(player: Player, ok: boolean, message: string)
	remFeedback:FireClient(player, ok, message)
end

-- Push the current session state to both parties (nil session = cleared).
local function pushSession(session: Session)
	for _, uid in { session.a, session.b } do
		local player = Players:GetPlayerByUserId(uid)
		if player then
			remTradeUpdate:FireClient(player, session)
		end
	end
end

-- Tear a session down for both parties and tell their clients.
local function endSession(session: Session)
	sessionByUser[session.a] = nil
	sessionByUser[session.b] = nil
	for _, uid in { session.a, session.b } do
		local player = Players:GetPlayerByUserId(uid)
		if player then
			remTradeUpdate:FireClient(player, nil)
		end
	end
end

local function distanceBetween(p1: Player, p2: Player): number?
	local c1, c2 = p1.Character, p2.Character
	local r1 = c1 and c1:FindFirstChild("HumanoidRootPart")
	local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
	if r1 and r1:IsA("BasePart") and r2 and r2:IsA("BasePart") then
		return (r1.Position - r2.Position).Magnitude
	end
	return nil
end

-- Append a completed trade to the server-side log store (locked safeguard #3).
-- Fire-and-forget in its own thread; a DataStore hiccup must never block a trade.
local function appendLog(session: Session)
	task.spawn(function()
		pcall(function()
			local store = DataStoreService:GetDataStore("tradeLog_v1")
			store:SetAsync(os.time() .. "_" .. HttpService:GenerateGUID(false), {
				t = os.time(),
				a = session.a,
				b = session.b,
				offerA = session.offerA,
				offerB = session.offerB,
			})
		end)
	end)
end

local function onRequest(player: Player, targetUserId: number)
	local data = DataManager.get(player)
	if not data then
		return
	end
	if targetUserId ~= math.floor(targetUserId) or targetUserId <= 0 then
		return
	end
	if sessionByUser[player.UserId] then
		feedback(player, false, "Finish your current trade first.")
		return
	end
	if os.time() < data.tradeCooldownUntil then
		feedback(player, false, "Catch your breath — trade cooldown active.")
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		return
	end
	local targetData = DataManager.get(target)
	if not targetData then
		return
	end
	if sessionByUser[target.UserId] then
		feedback(player, false, target.DisplayName .. " is already trading.")
		return
	end
	if os.time() < targetData.tradeCooldownUntil then
		feedback(player, false, target.DisplayName .. " just traded — try again shortly.")
		return
	end
	local dist = distanceBetween(player, target)
	if not dist or dist > GameConfig.TradeMaxDistance then
		feedback(player, false, "Get closer to " .. target.DisplayName .. " to trade.")
		return
	end

	-- Accept path: they already invited ME and it hasn't expired → open the session.
	local invite = invites[player.UserId]
	if
		invite
		and invite.from == targetUserId
		and os.time() - invite.at <= GameConfig.TradeInviteSeconds
	then
		invites[player.UserId] = nil
		invites[targetUserId] = nil
		local session: Session = {
			a = targetUserId,
			b = player.UserId,
			nameA = target.DisplayName,
			nameB = player.DisplayName,
			offerA = {},
			offerB = {},
			confirmA = false,
			confirmB = false,
		}
		sessionByUser[player.UserId] = session
		sessionByUser[target.UserId] = session
		pushSession(session)
		feedback(player, true, "🤝 Trading with " .. target.DisplayName .. "!")
		feedback(target, true, "🤝 Trading with " .. player.DisplayName .. "!")
		return
	end

	-- Invite path: park the invite on the target and nudge their panel.
	invites[target.UserId] = { from = player.UserId, at = os.time() }
	remTradeUpdate:FireClient(
		target,
		{ invite = { from = player.UserId, name = player.DisplayName } }
	)
	feedback(player, true, "Trade request sent to " .. target.DisplayName .. ".")
	feedback(target, true, "🤝 " .. player.DisplayName .. " wants to trade — open 🤝 Trade!")
end

-- Replace one side's offer after validating every stack against live inventory.
-- A junk payload rejects silently; an over-claim rejects with a toast. Any accepted
-- change clears BOTH confirmations (anti-swap-scam).
local function setOffer(player: Player, offer: { [any]: any })
	local session = sessionByUser[player.UserId]
	local data = DataManager.get(player)
	if not session or not data then
		return
	end
	local cleaned: { [string]: number } = {}
	local stacks = 0
	for key, qty in offer do
		if type(key) ~= "string" or #key > 64 or type(qty) ~= "number" then
			return
		end
		local q = math.floor(qty)
		if q < 0 or q ~= q then
			return
		end
		if q > 0 then
			if (data.hotDogs[key] or 0) < q then
				feedback(player, false, "You don't own that many of those.")
				return
			end
			stacks += 1
			if stacks > GameConfig.TradeMaxItems then
				feedback(player, false, "Max " .. GameConfig.TradeMaxItems .. " stacks per side.")
				return
			end
			cleaned[key] = q
		end
	end
	if player.UserId == session.a then
		session.offerA = cleaned
	else
		session.offerB = cleaned
	end
	session.confirmA = false
	session.confirmB = false
	pushSession(session)
end

-- Both sides confirmed: the atomic gate. Re-validate EVERYTHING against live data
-- (offers were validated when set, but steals/fusions/cooks may have happened
-- since), then move the stacks, stamp cooldowns, log, and tear down.
local function completeTrade(session: Session)
	local playerA = Players:GetPlayerByUserId(session.a)
	local playerB = Players:GetPlayerByUserId(session.b)
	if not playerA or not playerB then
		endSession(session)
		return
	end
	local dataA = DataManager.get(playerA)
	local dataB = DataManager.get(playerB)
	if not dataA or not dataB then
		endSession(session)
		return
	end
	if next(session.offerA) == nil and next(session.offerB) == nil then
		session.confirmA = false
		session.confirmB = false
		feedback(playerA, false, "Add at least one glizzy to trade.")
		feedback(playerB, false, "Add at least one glizzy to trade.")
		pushSession(session)
		return
	end
	for key, qty in session.offerA do
		if (dataA.hotDogs[key] or 0) < qty then
			session.confirmA = false
			session.confirmB = false
			feedback(playerA, false, "Your offer changed — check it and re-confirm.")
			feedback(playerB, false, "Their offer changed — re-confirm.")
			pushSession(session)
			return
		end
	end
	for key, qty in session.offerB do
		if (dataB.hotDogs[key] or 0) < qty then
			session.confirmA = false
			session.confirmB = false
			feedback(playerB, false, "Your offer changed — check it and re-confirm.")
			feedback(playerA, false, "Their offer changed — re-confirm.")
			pushSession(session)
			return
		end
	end

	-- Transfer. Both sides validated above; this block must not yield or bail.
	local function move(
		from: DataManager.PlayerData,
		to: DataManager.PlayerData,
		offer: { [string]: number }
	)
		for key, qty in offer do
			from.hotDogs[key] = (from.hotDogs[key] or 0) - qty
			if from.hotDogs[key] <= 0 then
				from.hotDogs[key] = nil
			end
			to.hotDogs[key] = (to.hotDogs[key] or 0) + qty
		end
	end
	move(dataA, dataB, session.offerA)
	move(dataB, dataA, session.offerB)

	local until_ = os.time() + GameConfig.TradeCooldownSeconds
	dataA.tradeCooldownUntil = until_
	dataB.tradeCooldownUntil = until_

	appendLog(session)
	endSession(session)

	for _, pair in { { playerA, dataA }, { playerB, dataB } } do
		local plr = pair[1] :: Player
		local dat = pair[2] :: DataManager.PlayerData
		-- A traded-away stack can't linger as a hand Tool (cosmetic orphan).
		local heldKey = PickupService.heldKeyOf(plr)
		if heldKey and (dat.hotDogs[heldKey] or 0) <= 0 then
			PickupService.forceReturn(plr)
		end
		PlotManager.syncDisplay(plr)
		onInventoryChanged(plr)
		Telemetry.event(plr, "TradeCompleted")
		feedback(plr, true, "✅ Trade complete!")
	end
end

local function onConfirm(player: Player)
	local session = sessionByUser[player.UserId]
	if not session then
		return
	end
	if player.UserId == session.a then
		session.confirmA = true
	else
		session.confirmB = true
	end
	if session.confirmA and session.confirmB then
		completeTrade(session)
	else
		pushSession(session)
	end
end

local function onCancel(player: Player)
	local session = sessionByUser[player.UserId]
	if not session then
		return
	end
	endSession(session)
	for _, uid in { session.a, session.b } do
		local other = Players:GetPlayerByUserId(uid)
		if other then
			feedback(other, false, "Trade cancelled.")
		end
	end
end

function TradeService.init(deps: {
	remotes: Folder,
	onInventoryChanged: (player: Player) -> (),
})
	onInventoryChanged = deps.onInventoryChanged
	remTradeRequest = deps.remotes:WaitForChild("TradeRequest") :: RemoteEvent
	remTradeUpdate = deps.remotes:WaitForChild("TradeUpdate") :: RemoteEvent
	remTradeConfirm = deps.remotes:WaitForChild("TradeConfirm") :: RemoteEvent
	remTradeCancel = deps.remotes:WaitForChild("TradeCancel") :: RemoteEvent
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent

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
		if type(offer) == "table" then
			setOffer(player, offer)
		end
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
		invites[player.UserId] = nil
		for target, invite in invites do
			if invite.from == player.UserId then
				invites[target] = nil
			end
		end
	end)
end

return TradeService
