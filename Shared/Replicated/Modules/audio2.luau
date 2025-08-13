--!nonstrict
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(script.Parent.TweenPlus)
local dictionary = require(ReplicatedStorage.Utility.dictionary)
local promise = require(ReplicatedStorage.Packages.promise)

--[=[
	@class Audio
	An advanced audio module for managing playlists and sound effects.
]=]

local audio = {
	profiles = {},
	soundClass = {},
}

export type soundProfile = {
	RollOffMaxDistance: number,
	RollOffMinDistance: number,
	RollOffMode: Enum.RollOffMode,
	Looped: boolean,
	PlaybackSpeed: number,
	Playing: boolean,
	TimePosition: number,
	Volume: number,
	Parent: Instance,
}

function audio.getDefaultProfile(): soundProfile
	return {
		RollOffMaxDistance = 100,
		RollOffMinDistance = 1,
		RollOffMode = Enum.RollOffMode.Linear,
		Looped = false,
		PlaybackSpeed = 1,
		Playing = false,
		TimePosition = 0,
		Volume = 1,
		Parent = workspace,
	}
end

function audio.soundClass.new(addEffect: boolean)
	local sound = Instance.new("Sound")
	local metatable = {
		__index = audio.soundClass,
		Start = function()
			if addEffect and not sound.IsPlaying then
				sound.Volume = 0
				TweenPlus(sound, { Volume = 1 }, {
					Time = 0.5,
					EasingStyle = "Quad",
					EasingDirection = "Out",
				})
				sound:Play()
			elseif not addEffect and not sound.IsPlaying then
				sound:Play()
			end
		end,
		Stop = function()
			if sound.IsPlaying and addEffect then
				TweenPlus(sound, { Volume = 0 }, {
					Time = 0.5,
					EasingStyle = "Quad",
					EasingDirection = "Out",
				})
				sound:Stop()
			elseif not addEffect and not sound.IsPlaying then
				sound:Stop()
			end
		end,
	}
	function metatable.__call()
		return sound
	end
	function metatable.__tostring()
		-- get the sound name from the marketplace
		local identification = sound.SoundId
		return promise.retry(function()
			local productInfo = MarketplaceService:GetProductInfo(identification)
			if productInfo and productInfo.Name then
				return productInfo.Name :: string
			else
				return "unknown"
			end
		end, 5)
	end
	function metatable:modifyProperties(key: string, value)
		if key:lower() == "id" then
			sound.SoundId = value
		elseif key:lower() == "volume" then
			sound.Volume = value
		elseif key:lower() == "speed" then
			sound.PlaybackSpeed = value
		elseif key:lower() == "looped" then
			sound.Looped = value
		elseif key:lower() == "time" then
			sound.TimePosition = value
		else
			error(`Invalid property {key} for sound class`)
		end
		return metatable.modifyProperties -- chainable
	end
	function metatable:adjustVolume(amount: number)
		local volume = math.clamp(sound.Volume + amount, 0, 10)
		TweenPlus(sound, { Volume = volume }, {
			Time = 0.5,
			EasingStyle = "Quad",
			EasingDirection = "Out",
		})
		return metatable
	end
	function metatable:rewrite(id: number)
		metatable.Stop()
		sound.SoundId = `rbxassetid://{id}`
		return metatable.Start, metatable.modifyProperties
	end
	return setmetatable({}, metatable)
end

function audio.writeNewProfile(name: string, profile: soundProfile)
	-- For example, you can have a UI sound profile which only plays UI sounds.
	if audio.profiles[name] then
		error(`Profile {name} already exists. Please choose a different name.`)
	end
	profile = dictionary.reconcile(profile, audio.getDefaultProfile())
	audio.profiles[name] = profile
end

function audio.create(profile: string | soundProfile, addEffect: boolean?)
	-- Create a new sound instance
	local sound = audio.soundClass.new()

	-- Apply the configuration to the sound instance
	for key, value in pairs(profile) do
		sound:modifyProperties(key, value)
	end

	-- Return the configured sound instance
	return sound
end
