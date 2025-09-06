--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local boundingbox = require(ReplicatedStorage.Classes.boundingbox)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local observer = require(ReplicatedStorage.Utility.observer)
local random = require(ReplicatedStorage.Utility.random)
local space = require(ReplicatedStorage.Modules.Serialization.space)
local trove = require(ReplicatedStorage.Packages.trove)

-- music.luau

--[[
	Example usage
	```luau
	local music = require(path.to.music)

	-- Create some biomes
	music.newBiome("forest", {
	    {
	        id = "rbxassetid://123456789",
	        name = "Forest Theme",
	        artist = "Composer"
	    }
	}, Vector3.new(0, 0, 0), Vector3.new(100, 50, 100))

	-- Start tracking
	music.startTracking()

	-- When done
	music.cleanup()
	```
]]
local music = {
	biomes = {},
	playing = observer.new({}),
	_trove = trove.new(),
	_currentBiome = "",
	_currentTrack = nil,
}

export type trackData = {
	id: string,
	name: string,
	length: number?,
	artist: string?,
	album: string?,
	genre: string?,
}

function music.newBiome(name: string, tracks: { trackData }, position: vector, size: vector)
	local box = boundingbox.new(position, size)

	music.biomes[name] = {
		tracks = tracks,
		boundingBox = box,
	}
end

function music.getBiome(position: vector): string?
	for name, biome in pairs(music.biomes) do
		if boundingbox.isPointInside(biome.boundingBox, position) then
			return name
		end
	end
	return nil
end

function music.getTracks(biomeName: string): { trackData }?
	local biome = music.biomes[biomeName]
	if biome then
		return biome.tracks
	end
	return nil
end

function music.startTracking()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart

	-- Track character changes
	music._trove:Connect(player.CharacterAdded, function(newCharacter)
		character = newCharacter
		hrp = character:WaitForChild("HumanoidRootPart")
	end)

	-- Track position and check biomes
	music._trove:Connect(RunService.Heartbeat, function()
		local position = space.toVec(hrp.Position)

		-- Check if player is in any biome
		local inAnyBiome = false
		for name, biome in pairs(music.biomes) do
			if boundingbox.isPointInside(biome.boundingBox, position) then
				inAnyBiome = true
				-- Only start music if we're not already playing something
				if music._currentBiome == "" then
					music._currentBiome = name
					music:playRandomTrack(name)
				end
				break
			end
		end

		-- Stop music if player left all biomes
		if not inAnyBiome and music._currentBiome ~= "" then
			music:stopCurrentTrack()
			music._currentBiome = nil
		end
	end)
end

function music:playRandomTrack(biomeName: string)
	local tracks = music.getTracks(biomeName)
	if not tracks or #tracks == 0 then
		return
	end

	-- Select random track
	local track = tracks[random.integer(1, #tracks)]

	-- Stop any currently playing track
	if music._currentTrack then
		music:stopCurrentTrack()
	end

	-- Play the new track
	music._currentTrack = audio:PlayMusic(tonumber(track.id) :: number, {
		fade = true,
		fadeTime = 1,
		loop = true,
	})
	music.playing:Set(track)
end

function music:stopCurrentTrack()
	if music._currentTrack then
		audio:StopMusic(true)
		music._currentTrack = nil
		music.playing:Set({})
	end
end

function music.cleanup()
	music:stopCurrentTrack()
	music._currentBiome = ""
	music._trove:Clean()
end

return music
