--!strict
-- Anti-exploit spine (GDD §4.11). A tiny server-side rate limiter + arg guards
-- that new remote handlers call so a spamming/forged client can't hammer the
-- economy. Landed as a foundation now; the FULL hardening pass (wrap EVERY
-- OnServerEvent, add anomaly logging) is scheduled before trading (M6) and before
-- soft launch — see the plan. Server-only; never trust the client.

local RateLimit = {}

-- buckets[userId][key] = { count, windowStart }
local buckets: { [number]: { [string]: { count: number, windowStart: number } } } = {}

-- Allow at most `perWindow` calls to `key` per `windowSeconds` for this player.
-- Returns true if the call is allowed (and records it), false if it should be
-- dropped. Default window is 1 second.
function RateLimit.check(
	player: Player,
	key: string,
	perWindow: number,
	windowSeconds: number?
): boolean
	local window = windowSeconds or 1
	local now = os.clock()
	local userBuckets = buckets[player.UserId]
	if not userBuckets then
		userBuckets = {}
		buckets[player.UserId] = userBuckets
	end
	local bucket = userBuckets[key]
	if not bucket or now - bucket.windowStart >= window then
		userBuckets[key] = { count = 1, windowStart = now }
		return true
	end
	if bucket.count >= perWindow then
		-- TODO(hardening): log an anomaly counter here for exploit monitoring.
		return false
	end
	bucket.count += 1
	return true
end

-- Convenience type guards used at the top of remote handlers.
function RateLimit.isString(v: any): boolean
	return type(v) == "string"
end

function RateLimit.isFiniteNumber(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- Drop a player's buckets when they leave.
game:GetService("Players").PlayerRemoving:Connect(function(player)
	buckets[player.UserId] = nil
end)

return RateLimit
