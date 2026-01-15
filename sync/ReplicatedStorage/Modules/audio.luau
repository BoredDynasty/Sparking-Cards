--!strict
-- audio.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local hydration = require(ReplicatedStorage.Utility.hydration)

local module = {}

-- internal storage
local music_tracks = {} :: { [string]: Sound }
local sound_effects = {} :: { [string]: Sound }

-- utility
local function create_sound(sound_id: string, parent: Instance, config)
	local sound = Instance.new("Sound")
	hydration(sound) {
		SoundId = sound_id,
		Volume = config.volume or 1,
		PlaybackSpeed = config.pitch or 1,
		Looped = config.looped or false,
		Parent = parent,
	}

	return sound
end

function module:AddMusic(name: string, sound_id: string, config)
	assert(not music_tracks[name], "Music already exists: " .. name)

	music_tracks[name] = create_sound(sound_id, SoundService, config or {})
end

function module:PlayMusic(name: string)
	local track = music_tracks[name]
	if track then
		track:Play()
	end
end

function module:StopMusic(name: string)
	local track = music_tracks[name]
	if track then
		track:Stop()
	end
end

function module:ConfigureMusic(name: string, config)
	local track = music_tracks[name]
	if not track then
		return
	end

	if config.volume then
		track.Volume = config.volume
	end

	if config.pitch then
		track.PlaybackSpeed = config.pitch
	end
end

function module:AddSFX(name: string, sound_id: string, config)
	assert(not sound_effects[name], "Sound effect already exists: " .. name)

	sound_effects[name] = create_sound(sound_id, SoundService, config or {})
end

function module:PlaySFX(name: string)
	local sfx = sound_effects[name]
	if sfx then
		sfx:Play()
	end
end

function module:ConfigureSFX(name: string, config)
	local sfx = sound_effects[name]
	if not sfx then
		return
	end

	if config.volume then
		sfx.Volume = config.volume
	end

	if config.pitch then
		sfx.PlaybackSpeed = config.pitch
	end
end

-- GLOBAL CONTROLS (optional but useful)

function module:StopAll()
	for _, track in pairs(music_tracks) do
		track:Stop()
	end
	for _, sfx in pairs(sound_effects) do
		sfx:Stop()
	end
end

return module
