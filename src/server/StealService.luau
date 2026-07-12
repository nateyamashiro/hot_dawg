--!strict
-- The RULES of stealing (PlotManager owns the physical prompts/parts). Handles
-- grabbing a rival's displayed dog, carrying it (slowed + glowing + owner alerted),
-- depositing it at your own stand for a PERMANENT transfer, and every abort path
-- (death, leaving, getting netted). Also owns steal energy, per-target cooldowns,
-- and the newbie-shield check. Server-authoritative throughout.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GlizzyModel = require(ReplicatedStorage.Shared.GlizzyModel)
local Telemetry = require(ServerScriptService.Server.Telemetry)
local HotDogDex = require(ReplicatedStorage.Shared.HotDogDex)
local Sfx = require(ReplicatedStorage.Shared.Sfx)
local Variants = require(ReplicatedStorage.Shared.Variants)
local DataManager = require(ServerScriptService.Server.DataManager)
local MutationService = require(ServerScriptService.Server.MutationService)
local PlotManager = require(ServerScriptService.Server.PlotManager)

type Carry = {
	dogName: string, -- inventory KEY (may encode a variant, e.g. "Chicago Dog#Gold")
	victimUserId: number,
	folder: Folder,
	highlight: Highlight,
}

type CarryVisuals = { folder: Folder, highlight: Highlight }

type Cooldown = { untilTime: number, raids: number, lastRaidAt: number }

local StealService = {}

local carrying: { [number]: Carry } = {}
-- recentSteals[thiefUserId][victimUserId] -> Cooldown
local recentSteals: { [number]: { [number]: Cooldown } } = {}

-- === Vault-breach state (additions #7) ===
type Drill = { victimUserId: number, token: number }
local drilling: { [number]: Drill } = {} -- thiefUserId -> active drill
local drillOnVault: { [number]: boolean } = {} -- victimUserId -> a drill is running
-- recentBreaches[thiefUserId][victimUserId] -> os.time the pair unlocks again
local recentBreaches: { [number]: { [number]: number } } = {}
local drillToken = 0

local updateLeaderstats: (player: Player) -> ()
-- Notify callbacks wired by Main: inventory changed (dex/snapshot push) and a
-- successful permanent steal (daily-mission progress).
local onInventoryChanged: (player: Player) -> ()
local onSteal: (player: Player) -> ()
-- Resolved from the Remotes folder in init(). Held as locals (not looked up
-- inline) so no statement ever starts with `(`, which Lua would otherwise parse
-- as a call on the previous line.
local remFeedback: RemoteEvent
local remStats: RemoteEvent
local remCarryUpdate: RemoteEvent
local remStealAlert: RemoteEvent
local remVaultBreach: RemoteEvent
local remCelebrate: RemoteEvent

-- === Helpers ===
local function feedback(player: Player, ok: boolean, message: string)
	remFeedback:FireClient(player, ok, message)
end

local function pushStats(player: Player)
	local data = DataManager.get(player)
	if not data then
		return
	end
	remStats:FireClient(
		player,
		data.stealCharges,
		GameConfig.MaxStealCharges,
		data.shieldUntil,
		data.vaultBreakers
	)
end
StealService.pushStats = pushStats

function StealService.isCarrying(player: Player): boolean
	return carrying[player.UserId] ~= nil
end

-- Attach the carried-dog visuals to the thief and slow them down.
local function attachCarry(thief: Player, dogName: string): CarryVisuals?
	local char = thief.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not (char and hrp and humanoid) then
		return nil
	end

	-- Carry rig: a real glizzy at 0.85× (Giant carries big at 1.28×), welded above the
	-- thief's head. Rarity fx stay ON for carries — the aura is a thief beacon.
	local baseName, variant = Variants.decode(dogName)
	local dog = HotDogDex.get(baseName)
	local rarity: HotDogDex.Rarity = if dog then dog.rarity else "Common"

	local folder = Instance.new("Folder")
	folder.Name = "CarriedDog"

	local unit = GlizzyModel.build(baseName, {
		rarity = rarity,
		variant = variant,
		scale = if variant == "Giant" then 1.28 else 0.85,
		anchored = false,
	})
	unit:SetAttribute("DogName", baseName)
	unit:SetAttribute("DogKey", dogName)
	unit:PivotTo(hrp.CFrame * CFrame.new(0, 3, 0))
	local part = unit.PrimaryPart :: BasePart

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = hrp
	weld.Parent = part
	unit.Parent = folder

	-- Visible marker for everyone chasing (GDD §4.1: "visible marker/glow").
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, 50)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Text = "🚨 THIEF!"
	label.Parent = bb

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 60, 60)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(255, 200, 0)
	highlight.Parent = char

	folder.Parent = char
	humanoid.WalkSpeed = GameConfig.CarryWalkSpeed

	return { folder = folder, highlight = highlight }
end

local function clearCarryVisuals(thief: Player, carry: Carry)
	carry.folder:Destroy()
	carry.highlight:Destroy()
	local char = thief.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = GameConfig.NormalWalkSpeed
	end
	PlotManager.setDepositEnabled(thief, false)
	remCarryUpdate:FireClient(thief, false, "")
end

-- Give a dog unit to a player's inventory and refresh their stand + leaderstats.
local function grantDog(player: Player, dogName: string)
	local data = DataManager.get(player)
	if not data then
		return
	end
	data.hotDogs[dogName] = (data.hotDogs[dogName] or 0) + 1
	updateLeaderstats(player)
	PlotManager.syncDisplay(player)
	onInventoryChanged(player)
end

-- === Public: abort a carry (return dog to victim if possible) ===
function StealService.dropCarry(thief: Player)
	local carry = carrying[thief.UserId]
	if not carry then
		return
	end
	carrying[thief.UserId] = nil
	clearCarryVisuals(thief, carry)

	local label = Variants.displayName(carry.dogName)
	local victim = Players:GetPlayerByUserId(carry.victimUserId)
	if victim then
		grantDog(victim, carry.dogName) -- back to its rightful owner
		feedback(victim, true, "You recovered your " .. label .. "!")
	end
	feedback(thief, false, "You dropped the " .. label .. "!")
end

-- === Public: steal prompt triggered (registered with PlotManager) ===
local function onStealTriggered(
	thief: Player,
	victimUserId: number,
	dogName: string,
	unitPart: BasePart
)
	if thief.UserId == victimUserId then
		return -- can't steal from yourself
	end
	if carrying[thief.UserId] then
		feedback(thief, false, "You're already carrying a dog!")
		return
	end

	local thiefData = DataManager.get(thief)
	local victim = Players:GetPlayerByUserId(victimUserId)
	local victimData = victim and DataManager.get(victim)
	if not (thiefData and victim and victimData) then
		return
	end

	local now = os.time()
	if now < victimData.shieldUntil then
		feedback(thief, false, victim.DisplayName .. " is shielded — can't steal yet.")
		return
	end
	if thiefData.stealCharges <= 0 then
		feedback(thief, false, "Out of steal charges — wait for a recharge.")
		return
	end
	local cd = recentSteals[thief.UserId] and recentSteals[thief.UserId][victimUserId]
	if cd and now < cd.untilTime then
		feedback(thief, false, "Too soon to raid " .. victim.DisplayName .. " again.")
		return
	end
	if (victimData.hotDogs[dogName] or 0) <= 0 then
		return -- already gone (stale prompt)
	end
	if not unitPart.Parent then
		return -- unit was destroyed mid-attempt
	end
	-- Captured before syncDisplay destroys the unit (the Giant shake needs it below).
	local unitPos = unitPart.Position

	-- Commit: remove from victim NOW; the dog belongs to nobody until deposit/abort.
	victimData.hotDogs[dogName] -= 1
	if victimData.hotDogs[dogName] <= 0 then
		victimData.hotDogs[dogName] = nil
	end
	thiefData.stealCharges -= 1
	updateLeaderstats(victim)
	PlotManager.syncDisplay(victim)
	onInventoryChanged(victim)
	pushStats(thief)

	local visuals = attachCarry(thief, dogName)
	if not visuals then
		-- No character to attach to; refund the dog to the victim and bail.
		grantDog(victim, dogName)
		return
	end
	carrying[thief.UserId] = {
		dogName = dogName,
		victimUserId = victimUserId,
		folder = visuals.folder,
		highlight = visuals.highlight,
	}
	local dogLabel = Variants.displayName(dogName)
	PlotManager.setDepositEnabled(thief, true)
	remCarryUpdate:FireClient(thief, true, dogLabel)
	remStealAlert:FireClient(victim, thief.UserId, thief.DisplayName, dogLabel)

	-- Juice (P-C): alarm flashes on the victim's sign post for everyone watching;
	-- grabbing a Giant shakes nearby cameras (it's a GIANT).
	local signPost = PlotManager.signPostOf(victim)
	if signPost then
		remCelebrate:FireAllClients("stealAlarm", signPost)
	end
	local _, variant = Variants.decode(dogName)
	if variant == "Giant" then
		remCelebrate:FireAllClients("giantShake", unitPos)
	end
end

-- Also exported for hand-steals: PickupService routes its "snatch it out of their
-- hand" prompt through this exact same pipeline, so charges/shield/cooldowns/the
-- carry rig all apply no matter where the dog was grabbed from.
StealService.triggerSteal = onStealTriggered

-- === Vault Breaker (additions #7 — the CONSCIOUS "vault = safe" override, GDD §7) ===
-- A coin consumable starts a LOUD drill on one vault dog: the victim gets an alarm +
-- countdown, everyone nearby sees it, and any net/trap/blaster-stun/death/leave (or
-- just stepping away) cancels it. Surviving the full drill detaches that ONE dog
-- into the normal carry pipeline — the thief still has to run it home. The breaker
-- is consumed at drill START, no refund: defending pays. No steal charge is spent
-- (the breaker replaces it); the per-pair breach cooldown replaces the per-target
-- steal cooldown.
local function endDrill(thief: Player, victimUserId: number)
	drilling[thief.UserId] = nil
	drillOnVault[victimUserId] = nil
end

local function onBreakTriggered(
	thief: Player,
	victimUserId: number,
	dogKey: string,
	unitPart: BasePart
)
	if thief.UserId == victimUserId then
		return
	end
	if carrying[thief.UserId] then
		feedback(thief, false, "You're already carrying a dog!")
		return
	end
	if drilling[thief.UserId] then
		return
	end

	local thiefData = DataManager.get(thief)
	local victim = Players:GetPlayerByUserId(victimUserId)
	local victimData = victim and DataManager.get(victim)
	if not (thiefData and victim and victimData) then
		return
	end

	local now = os.time()
	if now < victimData.shieldUntil then
		feedback(thief, false, victim.DisplayName .. " is shielded — can't break in yet.")
		return
	end
	if thiefData.vaultBreakers <= 0 then
		feedback(thief, false, "You need a 🔓 Vault Breaker — buy one on the defense bar.")
		return
	end
	if drillOnVault[victimUserId] then
		feedback(thief, false, "Someone is already drilling that vault!")
		return
	end
	local pairUnlock = recentBreaches[thief.UserId] and recentBreaches[thief.UserId][victimUserId]
	if pairUnlock and now < pairUnlock then
		feedback(thief, false, "That vault's been cracked recently — give it time.")
		return
	end
	if (victimData.hotDogs[dogKey] or 0) <= 0 or not unitPart.Parent then
		return -- stale prompt
	end

	-- Consume at drill START (no refund) + arm the per-pair cooldown immediately so
	-- a cancelled drill can't be instantly retried against the same victim.
	thiefData.vaultBreakers -= 1
	pushStats(thief)
	recentBreaches[thief.UserId] = recentBreaches[thief.UserId] or {}
	recentBreaches[thief.UserId][victimUserId] = now + GameConfig.VaultBreachCooldownSeconds
	drillToken += 1
	local myToken = drillToken
	drilling[thief.UserId] = { victimUserId = victimUserId, token = myToken }
	drillOnVault[victimUserId] = true

	-- The alarm: victim banner + arrow (VaultBreach mirrors StealAlert), the plot's
	-- sign flashes for everyone, and the drill itself makes noise at the vault.
	remVaultBreach:FireClient(
		victim,
		thief.UserId,
		thief.DisplayName,
		GameConfig.VaultBreakerDrillSeconds
	)
	local signPost = PlotManager.signPostOf(victim)
	if signPost then
		remCelebrate:FireAllClients("stealAlarm", signPost)
	end
	Sfx.play("VaultDrill", unitPart)
	feedback(thief, true, "🔓 Drilling the vault — hold your ground!")

	-- World countdown on the vault dog (the victim's counterplay timer).
	local bb = Instance.new("BillboardGui")
	bb.Name = "DrillLabel"
	bb.Size = UDim2.fromOffset(150, 34)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 90
	bb.Parent = unitPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = bb

	task.spawn(function()
		for t = GameConfig.VaultBreakerDrillSeconds, 1, -1 do
			local drill = drilling[thief.UserId]
			if not drill or drill.token ~= myToken then
				bb:Destroy()
				return
			end
			local char = thief.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			local holding = hrp
				and humanoid
				and humanoid.Health > 0
				and humanoid.WalkSpeed > 0 -- any stun (net/trap/blaster) breaks the drill
				and unitPart.Parent ~= nil
				and thief.Parent ~= nil
				and victim.Parent ~= nil
				and (hrp.Position - unitPart.Position).Magnitude <= GameConfig.VaultBreakerRange
			if not holding then
				endDrill(thief, victimUserId)
				bb:Destroy()
				feedback(thief, false, "The drill was interrupted — breaker wasted!")
				if victim.Parent then
					feedback(victim, true, "🛡️ You stopped the vault break-in!")
				end
				return
			end
			label.Text = "💥 BREAK-IN " .. t .. "s"
			task.wait(1)
		end
		endDrill(thief, victimUserId)
		bb:Destroy()

		-- Success — re-validate, then commit through the NORMAL carry pipeline.
		local vData = DataManager.get(victim)
		if not vData or (vData.hotDogs[dogKey] or 0) <= 0 then
			feedback(thief, false, "The vault emptied mid-drill!")
			return
		end
		if carrying[thief.UserId] then
			return -- grabbed something else mid-drill; no double-carry
		end
		vData.hotDogs[dogKey] -= 1
		if vData.hotDogs[dogKey] <= 0 then
			vData.hotDogs[dogKey] = nil
		end
		updateLeaderstats(victim)
		PlotManager.syncDisplay(victim)
		onInventoryChanged(victim)

		local visuals = attachCarry(thief, dogKey)
		if not visuals then
			grantDog(victim, dogKey) -- no character to attach to; refund the victim
			return
		end
		carrying[thief.UserId] = {
			dogName = dogKey,
			victimUserId = victimUserId,
			folder = visuals.folder,
			highlight = visuals.highlight,
		}
		local dogLabel = Variants.displayName(dogKey)
		PlotManager.setDepositEnabled(thief, true)
		remCarryUpdate:FireClient(thief, true, dogLabel)
		remStealAlert:FireClient(victim, thief.UserId, thief.DisplayName, dogLabel)
		Telemetry.event("VaultBreach")
		feedback(thief, true, "🔓 Vault cracked — now RUN it home!")
	end)
end
StealService.triggerBreak = onBreakTriggered

-- === Public: deposit at own stand (registered with PlotManager) ===
local function onDeposit(thief: Player)
	local carry = carrying[thief.UserId]
	if not carry then
		return
	end
	carrying[thief.UserId] = nil
	clearCarryVisuals(thief, carry)

	-- Steal-path mutation (GDD §4.4, MutateOnSteal): a stolen BASE dog can mint a
	-- variant on the way into the thief's stand — already-mutated loot transfers
	-- as-is, and the victim lost exactly the carried key either way. The THIEF's
	-- banked mutation luck applies, same as their own cooks.
	local thiefData = DataManager.get(thief)
	local bankKey = carry.dogName
	local baseName, variant = Variants.decode(carry.dogName)
	if GameConfig.MutateOnSteal and variant == "base" and thiefData then
		bankKey = MutationService.maybeMint(baseName, thiefData.mutationLuck)
	end
	local minted = bankKey ~= carry.dogName

	grantDog(thief, bankKey)
	-- 3D "banked it!" sting at the thief's stand (silence-safe until ids land).
	local depositPart = PlotManager.signPostOf(thief)
	if depositPart then
		Sfx.play("Deposit", depositPart)
	end

	if thiefData then
		thiefData.totalSteals += 1
		updateLeaderstats(thief)
	end
	onSteal(thief) -- daily-mission progress ("steal Y")
	Telemetry.funnelStep(thief, "FirstSteal")

	-- Per-target cooldown + diminishing returns (repeat raids cost longer waits).
	local now = os.time()
	recentSteals[thief.UserId] = recentSteals[thief.UserId] or {}
	local prev = recentSteals[thief.UserId][carry.victimUserId]
	local raids = 1
	if prev and now - prev.lastRaidAt < GameConfig.PerTargetCooldownSeconds * 3 then
		raids = prev.raids + 1
	end
	local cd = GameConfig.PerTargetCooldownSeconds
		* (1 + (raids - 1) * (GameConfig.DiminishingPenaltyPerRaid - 1))
	recentSteals[thief.UserId][carry.victimUserId] =
		{ untilTime = now + cd, raids = raids, lastRaidAt = now }

	if minted then
		feedback(
			thief,
			true,
			"Stole a "
				.. baseName
				.. "… and it turned ✨ "
				.. Variants.displayName(bankKey)
				.. "!"
		)
	else
		feedback(
			thief,
			true,
			"Stole a " .. Variants.displayName(carry.dogName) .. "! It's yours now."
		)
	end
end

-- Charge recharge loop: tops up every player's steal energy over time.
local function startChargeLoop()
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.time()
			for _, player in Players:GetPlayers() do
				local data = DataManager.get(player)
				if data then
					if data.stealCharges >= GameConfig.MaxStealCharges then
						-- Keep the timer fresh while full so spending doesn't refill instantly.
						data.lastChargeAt = now
					elseif now - data.lastChargeAt >= GameConfig.ChargeRechargeSeconds then
						data.stealCharges += 1
						data.lastChargeAt = now
						pushStats(player)
					end
				end
			end
		end
	end)
end

function StealService.init(deps: {
	remotes: Folder,
	updateLeaderstats: (player: Player) -> (),
	onInventoryChanged: (player: Player) -> (),
	onSteal: (player: Player) -> (),
})
	updateLeaderstats = deps.updateLeaderstats
	onInventoryChanged = deps.onInventoryChanged
	onSteal = deps.onSteal
	remFeedback = deps.remotes:WaitForChild("StealFeedback") :: RemoteEvent
	remStats = deps.remotes:WaitForChild("StatsUpdate") :: RemoteEvent
	remCarryUpdate = deps.remotes:WaitForChild("CarryUpdate") :: RemoteEvent
	remStealAlert = deps.remotes:WaitForChild("StealAlert") :: RemoteEvent
	remVaultBreach = deps.remotes:WaitForChild("VaultBreach") :: RemoteEvent
	remCelebrate = deps.remotes:WaitForChild("Celebrate") :: RemoteEvent

	PlotManager.setStealHandler(onStealTriggered)
	PlotManager.setBreakHandler(onBreakTriggered)
	PlotManager.setDepositHandler(onDeposit)

	-- Drop any carry if the thief dies mid-run. Wire both future spawns and the
	-- current character (so a Studio solo tester, already present, is covered too).
	local function hookDeath(player: Player)
		local function connectDied(char: Model)
			local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid");
			(humanoid :: Humanoid).Died:Connect(function()
				StealService.dropCarry(player)
			end)
		end
		player.CharacterAdded:Connect(connectDied)
		if player.Character then
			connectDied(player.Character)
		end
	end
	Players.PlayerAdded:Connect(hookDeath)
	for _, player in Players:GetPlayers() do
		hookDeath(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		-- Return a carried dog to its owner before the thief disconnects.
		StealService.dropCarry(player)
		recentSteals[player.UserId] = nil
		-- A drill dies with its driller (the loop also self-cancels on thief.Parent).
		local drill = drilling[player.UserId]
		if drill then
			endDrill(player, drill.victimUserId)
		end
		recentBreaches[player.UserId] = nil
		drillOnVault[player.UserId] = nil -- and any drill running ON their vault ends
	end)

	startChargeLoop()
end

return StealService
