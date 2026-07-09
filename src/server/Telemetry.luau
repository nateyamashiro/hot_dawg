--!strict
-- Deployment telemetry (launch readiness). Two jobs:
--   1. Onboarding funnel — Roblox AnalyticsService funnel steps, so the Creator
--      dashboard shows exactly where new players fall off:
--      Joined → FirstCook → StoveBuilt → FirstBuild → FirstSteal → FirstRebirth.
--      Roblox dedupes steps per user server-side; we also dedupe per session to
--      spare the call budget (doCook fires every cook, for example).
--   2. Error visibility — ScriptContext.Error logging with per-message dedupe so
--      live server errors are actually SEEN instead of dying with the server.
-- Every external call is pcall-guarded: telemetry must never break gameplay.

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ScriptContext = game:GetService("ScriptContext")

local Telemetry = {}

-- Funnel steps report with STABLE step numbers — never renumber, only append
-- (dashboard history is keyed on them).
local FUNNEL_STEPS: { [string]: number } = {
	Joined = 1,
	FirstCook = 2,
	StoveBuilt = 3,
	FirstBuild = 4,
	FirstSteal = 5,
	FirstRebirth = 6,
}

-- Per-session dedupe (Roblox dedupes across sessions; this saves the budget).
local reported: { [number]: { [string]: boolean } } = {}

function Telemetry.funnelStep(player: Player, stepName: string)
	local step = FUNNEL_STEPS[stepName]
	if not step then
		return
	end
	local byPlayer = reported[player.UserId]
	if not byPlayer then
		byPlayer = {}
		reported[player.UserId] = byPlayer
	end
	if byPlayer[stepName] then
		return
	end
	byPlayer[stepName] = true
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

-- Free-form counter for tuning questions ("how often are dogs hand-snatched?").
function Telemetry.event(player: Player, name: string)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, name)
	end)
end

-- Server errors: tag + dedupe (a hot-loop error must not flood the log). The
-- first few occurrences keep their trace; after that just the counter grows.
local errorCounts: { [string]: number } = {}
function Telemetry.init()
	ScriptContext.Error:Connect(function(message: string, trace: string)
		local key = string.sub(message, 1, 80)
		local count = (errorCounts[key] or 0) + 1
		errorCounts[key] = count
		if count <= 3 then
			warn("[Telemetry] Server error (x" .. count .. "): " .. message .. "\n" .. trace)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		reported[player.UserId] = nil
	end)
end

return Telemetry
