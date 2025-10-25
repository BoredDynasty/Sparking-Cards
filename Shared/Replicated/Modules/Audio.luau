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

function Audio:Init()
	local camera = workspace.CurrentCamera

	if not camera:FindFirstChild("AudioListener") then
		local listener = Instance.new("AudioListener", camera)
		local audioOut = Instance.new("AudioDeviceOutput", listener)
		local wire = Instance.new("Wire", listener)

		wire.SourceInstance = listener
		wire.TargetInstance = audioOut
	end
end

function Audio._getSoundById(id: number | string): AudioPlayer
	local sound = ReplicatedStorage.Audio:FindFirstChild(tostring(id))

	if sound and sound:IsA("AudioPlayer") then
		return sound:Clone()
	else
		local player = Instance.new("AudioPlayer")
		player.AssetId = assetPrefix .. tostring(id)
		player.Name = tostring(id)
		player.Parent = ReplicatedStorage.Audio
		return player
	end
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
	}?
)
	self:Init()
	if currentMusic then
		self:StopMusic(options and options.fade)
	end

	local music = self._getSoundById(soundId)
	music.Parent = soundFolder
	local emitter = Instance.new("AudioEmitter")
	emitter.Parent = music
	currentMusic = music

	local wire = Instance.new("Wire")
	wire.SourceInstance = music
	wire.TargetInstance = emitter
	wire.Parent = music

	music.Looped = options and options.loop or false
	emitter.Volume = options and options.volume or 1

	if options and options.fade then
		emitter.Volume = 0
		local fadeTime = options.fadeTime or 1
		local tween = TweenPlus(emitter, { Volume = options.volume or 1 }, fadeTime)
		tween:Start()
	end

	music:Play()
end

--[=[
    Stops the current background music
    @param fade boolean?
]=]
function Audio:StopMusic(fade: boolean?)
	if currentMusic then
		local emitter = currentMusic:FindFirstChildOfClass("AudioEmitter")
		if fade then
			local tween = TweenPlus(emitter, { Volume = 0 }, 1)
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
	self:Init()
	task.spawn(function()
		local sfx = self._getSoundById(soundId)
		sfx.Parent = soundFolder
		local emitter = Instance.new("AudioEmitter")
		emitter.Parent = sfx
		currentSFX = sfx

		local wire = Instance.new("Wire")
		wire.SourceInstance = sfx
		wire.TargetInstance = emitter
		wire.Parent = sfx

		emitter.Volume = options and options.volume or 1
		sfx.PlaybackSpeed = options and options.pitch or 1

		sfx:Play()
		sfx.Ended:Once(function()
			sfx:Destroy()
			emitter:Destroy()
		end)
	end)
end

--[=[
    Sets the volume of the current music
    @param volume number
    @param fade boolean?
]=]
function Audio:SetMusicVolume(volume: number, fade: boolean?)
	if currentMusic then
		local emitter = currentMusic:FindFirstChildOfClass("AudioEmitter")
		if emitter then
			if fade then
				local tween = TweenPlus(emitter, { Volume = volume }, 1)
				tween:Start()
			else
				emitter.Volume = volume
			end
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
