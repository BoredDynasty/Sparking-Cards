--!nonstrict

--[=[
	@class Audio
	An advanced audio module for managing playlists and sound effects.
]=]
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Signal = require(script.Parent.Parent.Utility.SignalPlus)
local TweenPlus = require(script.Parent.Parent.Utility.TweenPlus)
local dictionary = require(script.Parent.Parent.Utility.dictionary)
local random = require(script.Parent.Parent.Utility.random)

local Audio = {}
Audio.SoundEffects = {}
Audio.Playlists = {}

-- Private variables
local currentPlaylist: Tracks? = nil
local currentTrack: Sound? = nil
local currentTrackIndex = -1
local isPaused = false
local isShuffling = false
local isLooping = false
local originalPlaylist = nil
local assetPrefix = "rbxassetid://"

local musicFolder = Instance.new("Folder")
musicFolder.Name = "Music"
musicFolder.Parent = SoundService

local sfxFolder = Instance.new("Folder")
sfxFolder.Name = "SoundEffects"
sfxFolder.Parent = SoundService

export type Tracks = {
	[string]: {
		identification: number,
	},
}

--[=[
	Starts a playlist with the given tracks.
	@param playlistName string
	@param tracks table<string>
	@param fade boolean
]=]
function Audio:StartPlaylist(playlistName: string, tracks: Tracks, fade: boolean)
	if currentPlaylist then
		self:Cleanup()
	end

	currentPlaylist = tracks
	originalPlaylist = tracks
	local currentTrackIndex = 1

	if isShuffling then
		self:_ShufflePlaylist()
	end

	local sound = Instance.new("Sound")
	sound.SoundId = `{assetPrefix}{tracks[currentTrackIndex].identification}`
	sound.Parent = musicFolder

	local function playNextTrack()
		currentTrackIndex += 1
		if currentTrackIndex > (#currentPlaylist) :: number then
			if isLooping then
				currentTrackIndex = 1
				if isShuffling then
					self:_ShufflePlaylist()
				end
			else
				self:Cleanup()
				return
			end
		end
		sound.SoundId = `{assetPrefix}{tracks[currentTrackIndex].identification}`
		sound:Play()
	end

	sound.Ended:Connect(function()
		if fade then
			local fadeOutTween = TweenPlus(sound, {
				Volume = 0,
			}, {
				Time = 1,
			})
			fadeOutTween:Start()
			fadeOutTween.Completed:Connect(function()
				playNextTrack()
				local fadeInTween = TweenPlus(sound, {
					Volume = 1,
				}, {
					Time = 1,
				})
				fadeInTween:Start()
			end)
		else
			playNextTrack()
		end
	end)

	if fade then
		sound.Volume = 0
		TweenPlus(sound, {
			Volume = 1,
		}, {
			Time = 1,
		}):Start()
	end

	sound:Play()
	currentTrack = sound
end

function Audio:_ShufflePlaylist()
	random.shuffle(currentPlaylist)
end

function Audio:writePlaylist(tracks: Tracks)
	self:Stop()
end

--[=[
	Plays a sound effect.
	@param soundName string?
	@param soundId number?
]=]
function Audio:SFX(soundName, soundId: number)
	local sound = Instance.new("Sound")
	sound.Name = soundName or "Sound"
	sound.Parent = sfxFolder
	sound:Play()
	if soundName and table.find(Audio.SoundEffects, soundName) then
		sound.SoundId = `{assetPrefix}{Audio.SoundEffects[soundName]}`
	elseif not table.find(Audio.Playlists, soundName) then
		sound.SoundId = `{assetPrefix}{soundId}`
	end
	sound.Ended:Once(function()
		task.defer(sound.Destroy, sound)
	end)
end

function Audio:writeSFX(dict: { [string]: number })
	for key, value in pairs(dict) do
		if not table.find(Audio.SoundEffects, key) then
			Audio.SoundEffects[key] = value
		end
	end
end

--[=[
	Gets information about the current playing track.
	@return table
]=]
function Audio:GetCurrentTrackInfo(): {}?
	if not currentTrack then
		return nil
	end

	return {
		Name = currentTrack.Name,
		SoundId = currentTrack.SoundId,
		TimePosition = currentTrack.TimePosition,
		TimeLength = currentTrack.TimeLength,
		Volume = currentTrack.Volume,
		IsPaused = isPaused,
		IsLooping = isLooping,
		IsShuffling = isShuffling,
	}
end

--[=[
	Sets the time position of the current playing track.
	@param position number
]=]
function Audio:SetTimePosition(position: number)
	if currentTrack then
		if position > currentTrack.TimeLength then
			warn("Time position cannot be longer than the song itself.")
			return
		end
		currentTrack.TimePosition = position
	end
end

--[=[
	Pauses the current playlist.
]=]
function Audio:Pause()
	if currentTrack and not isPaused then
		isPaused = true
		currentTrack:Pause()
	end
end

--[=[
	Plays the current playlist.
]=]
function Audio:Play()
	if currentTrack and isPaused then
		isPaused = false
		currentTrack:Play()
	end
end

--[=[
	Skips to the next track in the playlist.
]=]
function Audio:SkipForward()
	if not currentTrack then
		return
	end

	local fadeOutTween = TweenPlus(currentTrack, {
		Volume = 1,
	}, {
		Time = 0.5,
	})
	fadeOutTween.Completed:Connect(function()
		currentTrackIndex += 1
		if currentTrackIndex > #currentPlaylist then
			if isLooping then
				currentTrackIndex = 1
			else
				self:Cleanup()
				return
			end
		end
		currentTrack.SoundId = `{assetPrefix}{currentPlaylist[currentTrackIndex].identification}`
		currentTrack.Volume = 1
		currentTrack:Play()
	end)
	fadeOutTween:Start()
end

--[=[
	Skips to the previous track in the playlist.
]=]
function Audio:SkipBackward()
	if not currentTrack then
		return
	end

	local fadeOutTween = TweenPlus(currentTrack, {
		Volume = 0,
	}, {
		Time = 0.5,
	})
	fadeOutTween.Completed:Connect(function()
		currentTrackIndex -= 1
		if currentTrackIndex < 1 then
			currentTrackIndex = #currentPlaylist
		end
		currentTrack.SoundId = `{assetPrefix}{currentPlaylist[currentTrackIndex].identification}`
		currentTrack.Volume = 1
		currentTrack:Play()
	end)
	fadeOutTween:Start()
end

--[=[
	Restarts the current playlist.
]=]
function Audio:Restart()
	if not currentTrack then
		return
	end

	local fadeOutTween = TweenPlus(currentTrack, {
		Volume = 0,
	}, {
		Time = 0.5,
	})
	fadeOutTween.Completed:Connect(function()
		currentTrackIndex = 1
		currentTrack.SoundId = `{assetPrefix}{currentPlaylist[currentTrackIndex].identification}`
		currentTrack.Volume = 1
		currentTrack:Play()
	end)
	fadeOutTween:Start()
end

--[=[
	Sets the volume of the music.
	@param volume number
]=]
function Audio:SetVolume(volume: number)
	if currentTrack then
		currentTrack.Volume = volume
		TweenPlus(currentTrack, {
			Volume = volume,
		}, {
			0.2,
		})
	end
end

--[=[
	Toggles shuffle for the current playlist.
]=]
function Audio:ToggleShuffle()
	isShuffling = not isShuffling
	if isShuffling then
		self:_ShufflePlaylist()
	else
		currentPlaylist = originalPlaylist
	end
end

--[=[
	Toggles looping for the current playlist.
]=]
function Audio:ToggleLoop()
	isLooping = not isLooping
end

--[=[
	Cleans up the audio module.
]=]
function Audio:Cleanup()
	if currentTrack then
		currentTrack:Stop()
		currentTrack:Destroy()
		currentTrack = nil
	end

	currentPlaylist = nil
	originalPlaylist = nil
	currentTrackIndex = -1
	isPaused = false
end

return Audio
