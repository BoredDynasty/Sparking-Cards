--!strict
-- audio.lua

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local module = {}

-- internal storage
local music_tracks = {} :: { [string]: Sound }
local sound_effects = {} :: { [string]: Sound }

-- utility
local function create_sound(sound_id: number, parent: Instance, config)
	local sound = Instance.new("Sound")
	sound.AudioContent = Content.fromAssetId(sound_id)
	sound.Volume = config.volume or 1
	sound.PlaybackSpeed = config.pitch or 1
	sound.Looped = config.looped or false
	sound.Parent = parent

	return sound
end

function module:AddMusic(name: string, sound_id: number, config)
	assert(not music_tracks[name], "Music already exists: " .. name)

	music_tracks[name] = create_sound(sound_id, SoundService, config or {})
end

function module:PlayMusic(name: string)
	local track = music_tracks[name]
	if track then
		-- smoothly play the sound

		local fade_in_time = 0.5
		local track_volume = track.Volume

		track.Volume = 0 -- reset volume

		TweenService:Create(track, TweenInfo.new(fade_in_time), {
			Volume = track_volume,
		}):Play()

		track:Play()
	end
end

function module:PlayVariation(prefix: string, variation: number)
	local track = music_tracks[`{prefix}-{variation}`]
	if track then
		track:Play()
	end
end

function module:StopMusic(name: string)
	local track = music_tracks[name]
	if track then
		-- smoothly stop the sound

		local track_volume = track.Volume

		local fade_out_time = 0.5
		TweenService:Create(track, TweenInfo.new(fade_out_time), {
			Volume = 0,
		}):Play()
		track:Stop()
		track.Volume = track_volume -- reset volume for next time
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

function module:AddSFX(name: string, sound_id: number, config)
	assert(not sound_effects[name], "Sound effect already exists: " .. name)

	sound_effects[name] = create_sound(sound_id, SoundService, config or {})
end

--[[
	@param name The SFX name
]]
function module:PlaySFX(name: string)
	local sfx = sound_effects[name]
	if sfx then
		sfx.Parent = SoundService

		sfx:Play()
	end
end

function module:ConfigureSFX(
	name: string,
	config: { read looped: boolean, read pitch: number, read volume: number }
)
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

	if config.looped then
		sfx.Looped = config.looped
	end
end

function module:SetMusicEnabled(enabled: boolean)
	for _, track in pairs(music_tracks) do
		track.Playing = enabled and track.Playing or false
	end
end

function module:SetSFXEnabled(enabled: boolean)
	for _, sfx in pairs(sound_effects) do
		sfx.Playing = enabled and sfx.Playing or false
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
