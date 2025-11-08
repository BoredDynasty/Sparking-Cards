--!nonstrict

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local TweenPlus = require(script.Parent.TweenPlus)
local promise = require(ReplicatedStorage.Packages.promise)

local Audio = {}
Audio.SoundEffects = {}
Audio.Playlists = {}

-- Private variables
local currentMusic: AudioPlayer? = nil
local currentSFX: AudioPlayer? = nil
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

		print("initialized audio listeners! : ", wire, audioOut, listener)
	end
end

function Audio._getSoundById(id: number | string): AudioPlayer?
	local sound = nil

	if type(sound) == "number" then
		local ok, product_info = promise
			.new(function(resolve, reject)
				local ok, result = pcall(function()
					return MarketplaceService:GetProductInfo(id)
				end)

				if ok then
					resolve(result)
				else
					reject(result)
				end
			end)
			:await()

		if not ok then
			return nil
		end

		sound = ReplicatedStorage.Audio:FindFirstChild(product_info.Name) :: AudioPlayer
	elseif type(sound) == "string" then
		sound = ReplicatedStorage.Audio:FindFirstChild(sound)
	end

	if sound and sound:IsA("AudioPlayer") then
		return sound:Clone()
	else
		local player = Instance.new("AudioPlayer")
		player.Name = tostring(id)
		player.Parent = ReplicatedStorage.Audio
		if type(id) == "number" then
			player.AssetId = assetPrefix .. tostring(id)
		else
			warn("id is not a number: ", id, typeof(id))

			return nil
		end
		return player
	end
end

--[=[
    Plays background music with optional fade
    @param soundId number
    @param options table?

	 @return Promise
]=]
function Audio:PlayMusic(
	soundId: number,
	options: {
		volume: number?,
		loop: boolean?,
		fade: boolean?,
		fadeTime: number?,
		analyzer: AudioAnalyzer?,
	}?
)
	self:Init()
	if currentMusic then
		self:StopMusic(options and options.fade)
	end

	local music = self._getSoundById(soundId) :: AudioPlayer
	if not music then
		warn("couldn't get audio player!!!")
	end

	music.Parent = soundFolder
	local emitter = Instance.new("AudioEmitter")
	emitter.Parent = music

	currentMusic = music

	local wire = Instance.new("Wire")
	wire.SourceInstance = music
	wire.TargetInstance = emitter
	wire.Parent = music

	pcall(function()
		if options.analyzer then
			local wire_analyzer = Instance.new("Wire")
			wire_analyzer.SourceInstance = music
			wire_analyzer.TargetInstance = options.analyzer
			wire_analyzer.Parent = music
		end
	end)

	music.Looping = options and options.loop or false
	music.Volume = options and options.volume or 1
	--emitter.Volume = options and options.volume or 1

	if options and options.fade then
		--emitter.Volume = 0
		music.Volume = 0
		local fadeTime = options.fadeTime or 1
		local tween = TweenPlus(music, { Volume = options.volume or 1 }, { Time = fadeTime })
		tween:Start()
	end

	music:Play()
	print("playing music: ", music.Asset)
end

--[=[
    Stops the current background music
    @param fade boolean?
]=]
function Audio:StopMusic(fade: boolean?)
	if currentMusic then
		local emitter = currentMusic:FindFirstChildOfClass("AudioEmitter")
		if fade then
			--local tween = TweenPlus(emitter, { Volume = 0 }, 1)
			local tween = TweenPlus(currentMusic, { Volume = 0 }, { Time = 1 })
			tween.Completed:Connect(function()
				if currentMusic then
					currentMusic:Destroy()
					currentMusic = nil
				end
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
		analyzer: AudioAnalyzer?,
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

		pcall(function()
			if options.analyzer then
				local wire_analyzer = Instance.new("Wire")
				wire_analyzer.SourceInstance = sfx
				wire_analyzer.TargetInstance = options.analyzer
				wire_analyzer.Parent = sfx
			end
		end)

		--emitter.Volume = options and options.volume or 1
		currentSFX.Volume = options and options.volume or 0.9
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
				local tween = TweenPlus(currentMusic, { Volume = volume }, { Time = 1 })
				tween:Start()
			else
				--emitter.Volume = volume
				currentMusic.Volume = volume
			end
		end
	end
end

--[=[
    Pauses the current music
]=]
function Audio:PauseMusic()
	if currentMusic then
		currentMusic:Stop()
	end
end

--[=[
    Resumes the current music
]=]
function Audio:ResumeMusic()
	if currentMusic then
		currentMusic:Play()
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
