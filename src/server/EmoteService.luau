--!strict
-- Preset emotes / taunts (M6, GDD §4.8). No free-text (moderation-safe): the client
-- picks an emote id from GameConfig.Emotes; the server validates it's a real id and
-- broadcasts to nearby players so steals/pulls can be celebrated or ribbed. Untrusted
-- client only requests. Tiny, so no data/state — just a validated relay.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local RateLimit = require(ServerScriptService.Server.RateLimit)

local EmoteService = {}

local remPlayEmote: RemoteEvent

-- Whether `id` is a configured emote.
local function isValidEmote(id: string): boolean
	for _, name in GameConfig.Emotes do
		if name == id then
			return true
		end
	end
	return false
end

function EmoteService.init(deps: { remotes: Folder })
	remPlayEmote = deps.remotes:WaitForChild("PlayEmote") :: RemoteEvent

	remPlayEmote.OnServerEvent:Connect(function(player, id)
		if not RateLimit.check(player, "PlayEmote", 3, 3) then
			return -- throttle emote spam
		end
		if type(id) ~= "string" or not isValidEmote(id) then
			return
		end
		-- TODO(M6-emote): scope the broadcast to nearby players only (distance check)
		-- and play the animation on `player`'s character, not just a UI popup.
		for _, other in Players:GetPlayers() do
			if other ~= player then
				remPlayEmote:FireClient(other, player.UserId, id)
			end
		end
	end)
end

return EmoteService
