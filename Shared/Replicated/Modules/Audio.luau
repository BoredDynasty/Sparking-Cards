--[=[
	@class Audio
	An advanced audio module for managing playlists and sound effects.
]=]
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Signal = require(script.Parent.Parent.Utility.SignalPlus)

local Audio = {}
Audio.SoundEffects = {}
Audio.Playlists = {}

-- Private variables
local currentPlaylist = nil
local currentTrack = nil
local currentTrackIndex = -1
local isPaused = false
local isShuffling = false
local isLooping = false
local originalPlaylist = nil

local musicFolder = Instance.new("Folder")
musicFolder.Name = "Music"
musicFolder.Parent = SoundService

local sfxFolder = Instance.new("Folder")
sfxFolder.Name = "SoundEffects"
sfxFolder.Parent = SoundService

--[=[
	Starts a playlist with the given tracks.
	@param playlistName string
	@param tracks table<string>
	@param fade boolean
]=]
function Audio:StartPlaylist(playlistName, tracks, fade)
	if currentPlaylist then
		self:Cleanup()
	end

	currentPlaylist = tracks
	originalPlaylist = tracks
	currentTrackIndex = 1

	if isShuffling then
		self:_ShufflePlaylist()
	end

	local sound = Instance.new("Sound")
	sound.SoundId = tracks[currentTrackIndex]
	sound.Parent = musicFolder

	local function playNextTrack()
		currentTrackIndex = currentTrackIndex + 1
		if currentTrackIndex > #currentPlaylist then
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
		sound.SoundId = currentPlaylist[currentTrackIndex]
		sound:Play()
	end

	sound.Ended:Connect(function()
		if fade then
			local fadeOutTween = TweenService:Create(sound, TweenInfo.new(1), { Volume = 0 })
			fadeOutTween.Completed:Connect(function()
				playNextTrack()
				local fadeInTween = TweenService:Create(sound, TweenInfo.new(1), { Volume = 1 })
				fadeInTween:Play()
			end)
			fadeOutTween:Play()
		else
			playNextTrack()
		end
	end)

	if fade then
		sound.Volume = 0
		local fadeInTween = TweenService:Create(sound, TweenInfo.new(1), { Volume = 1 })
		fadeInTween:Play()
	end

	sound:Play()
	currentTrack = sound
end

function Audio:_ShufflePlaylist()
	local shuffledPlaylist = {}
	local originalPlaylistCopy = table.clone(originalPlaylist)

	for i = #originalPlaylistCopy, 1, -1 do
		local randomIndex = math.random(i)
		table.insert(shuffledPlaylist, originalPlaylistCopy[randomIndex])
		table.remove(originalPlaylistCopy, randomIndex)
	end

	currentPlaylist = shuffledPlaylist
end

--[=[
	Plays a sound effect.
	@param soundName string
	@param soundId string
]=]
function Audio:PlaySoundEffect(soundName, soundId)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Name = soundName
	sound.Parent = sfxFolder
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

--[=[
	Gets information about the current playing track.
	@return table
]=]
function Audio:GetCurrentTrackInfo()
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
function Audio:SetTimePosition(position)
	if currentTrack then
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

	local fadeOutTween = TweenService:Create(currentTrack, TweenInfo.new(0.5), { Volume = 0 })
	fadeOutTween.Completed:Connect(function()
		currentTrackIndex = currentTrackIndex + 1
		if currentTrackIndex > #currentPlaylist then
			if isLooping then
				currentTrackIndex = 1
			else
				self:Cleanup()
				return
			end
		end
		currentTrack.SoundId = currentPlaylist[currentTrackIndex]
		currentTrack.Volume = 1
		currentTrack:Play()
	end)
	fadeOutTween:Play()
end

--[=[
	Skips to the previous track in the playlist.
]=]
function Audio:SkipBackward()
	if not currentTrack then
		return
	end

	local fadeOutTween = TweenService:Create(currentTrack, TweenInfo.new(0.5), { Volume = 0 })
	fadeOutTween.Completed:Connect(function()
		currentTrackIndex = currentTrackIndex - 1
		if currentTrackIndex < 1 then
			currentTrackIndex = #currentPlaylist
		end
		currentTrack.SoundId = currentPlaylist[currentTrackIndex]
		currentTrack.Volume = 1
		currentTrack:Play()
	end)
	fadeOutTween:Play()
end

--[=[
	Restarts the current playlist.
]=]
function Audio:Restart()
	if not currentTrack then
		return
	end

	local fadeOutTween = TweenService:Create(currentTrack, TweenInfo.new(0.5), { Volume = 0 })
	fadeOutTween.Completed:Connect(function()
		currentTrackIndex = 1
		currentTrack.SoundId = currentPlaylist[currentTrackIndex]
		currentTrack.Volume = 1
		currentTrack:Play()
	end)
	fadeOutTween:Play()
end

--[=[
	Sets the volume of the music.
	@param volume number
]=]
function Audio:SetVolume(volume)
	if currentTrack then
		currentTrack.Volume = volume
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
