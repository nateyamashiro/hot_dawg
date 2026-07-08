--!strict
-- Tiny sound helper (P-C juice pass). `Sfx.play(name, parent?)` looks up
-- GameConfig.Sounds[name] and plays a one-shot Sound parented to `parent` (3D when
-- parented to a part; UI/flat when parented to a ScreenGui or omitted).
-- SILENCE-SAFE: no-ops while the id is "" — Nate fills GameConfig.Sounds later and
-- everything starts sounding without code changes.

local GameConfig = require(script.Parent.GameConfig)

local Sfx = {}

local sounds: { [string]: string } = GameConfig.Sounds :: any

function Sfx.play(name: string, parent: Instance?)
	local id = sounds[name]
	if id == nil or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 0.6
	sound.Parent = parent or workspace
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	-- Safety net: a bad/moderated id never fires Ended; don't leak the instance.
	task.delay(10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

-- Start the looping world-ambience bed (call once, client-side). No-op on "".
function Sfx.startAmbient(parent: Instance?)
	local id = sounds.Ambient
	if id == nil or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "GlizzyAmbient"
	sound.SoundId = id
	sound.Volume = 0.25
	sound.Looped = true
	sound.Parent = parent or workspace
	sound:Play()
end

return Sfx
