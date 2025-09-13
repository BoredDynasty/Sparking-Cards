--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local TweenPlus = require(script.Parent.TweenPlus)

local Audio = {}
Audio.SoundEffects = {}
Audio.Playlists = {}

-- Private variables
local currentMusic: Sound? = nil
local currentSFX: Sound? = nil
local assetPrefix = "rbxassetid://"

local soundFolder = Instance.new("Folder")
soundFolder.Name = "GameSounds"
soundFolder.Parent = SoundService

function Audio._getSoundById(id: number | string): Sound?
	local sound = nil

	for _, sounds in ReplicatedStorage.Audio:GetChildren() do
		if sounds:IsA("Sound") and (sounds.SoundId == assetPrefix .. tostring(id) or sounds.Name == id) then
			sound = sounds:Clone()
			break
		end
	end

	return sound
end

--[=[
    Plays background music with optional fade
    @param soundId number
    @param options table?
]=]
function Audio:PlayMusic(
	soundId: number,
	options: {
		volume: number?,
		loop: boolean?,
		fade: boolean?,
		fadeTime: number?,
	}
)
	if currentMusic then
		self:StopMusic(options and options.fade)
	end

	local music = Instance.new("Sound")
	music.SoundId = assetPrefix .. tostring(soundId)
	music.Volume = options and options.volume or 1
	music.Looped = options and options.loop or false
	music.Parent = soundFolder

	if options and options.fade then
		music.Volume = 0
		local fadeTime = options.fadeTime or 1
		local tween = TweenPlus(music, { Volume = options.volume or 1 }, fadeTime)
		tween:Start()
	end

	music:Play()
	currentMusic = music
end

--[=[
    Stops the current background music
    @param fade boolean?
]=]
function Audio:StopMusic(fade: boolean?)
	if currentMusic then
		if fade then
			local tween = TweenPlus(currentMusic, { Volume = 0 }, 1)
			tween.Completed:Connect(function()
				currentMusic:Destroy()
				currentMusic = nil
			end)
			tween:Start()
		else
			currentMusic:Destroy()
			currentMusic = nil
		end
	end
end

--[=[
    Plays a sound effect
    @param soundId number | string
    @param options table?
]=]
function Audio:SFX(
	soundId: number | string,
	options: {
		volume: number?,
		pitch: number?,
	}?
)
	if type(soundId) == "string" then
		local id = Audio._getSoundById(soundId)
		if id then
			soundId = id
		else
			warn("Sound effect not found: " .. soundId)
			return
		end
	end

	local sfx = Instance.new("Sound")
	sfx.SoundId = assetPrefix .. tostring(soundId :: number)
	sfx.Volume = options and options.volume or 1
	sfx.PlaybackSpeed = options and options.pitch or 1
	sfx.Parent = soundFolder

	sfx:Play()
	sfx.Ended:Once(function()
		sfx:Destroy()
	end)

	currentSFX = sfx
end

--[=[
    Sets the volume of the current music
    @param volume number
    @param fade boolean?
]=]
function Audio:SetMusicVolume(volume: number, fade: boolean?)
	if currentMusic then
		if fade then
			local tween = TweenPlus(currentMusic, { Volume = volume }, 1)
			tween:Start()
		else
			currentMusic.Volume = volume
		end
	end
end

--[=[
    Pauses the current music
]=]
function Audio:PauseMusic()
	if currentMusic then
		currentMusic:Pause()
	end
end

--[=[
    Resumes the current music
]=]
function Audio:ResumeMusic()
	if currentMusic then
		currentMusic:Resume()
	end
end

--[=[
    Cleans up all audio
]=]
function Audio:Cleanup()
	if currentMusic then
		currentMusic:Destroy()
		currentMusic = nil
	end
	if currentSFX then
		currentSFX:Destroy()
		currentSFX = nil
	end
end

return Audio
