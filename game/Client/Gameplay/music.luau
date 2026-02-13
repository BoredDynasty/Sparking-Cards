--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local _SoundService = game:GetService("SoundService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local audio = require(ReplicatedStorage.Modules.audio)

local future = require(ReplicatedStorage.Packages.future)
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local random = require(ReplicatedStorage.Utility.random)
local trove = require(ReplicatedStorage.Packages.trove)

-- music.luau

local module = {
	biomes = {},
	Playing = observer.new() :: observer.Observer<Track?>,
	_trove = trove.new(),
	current_biome = "" :: string?,
	current_track = nil :: Track?,
	added_music = {}, -- Track which music IDs have been added to audio
}

export type Track = {
	id: number,
	name: string,
	length: number?,
	artist: string?,
	album: string?,
	genre: string?,
}

--[[
	Example usage
	```luau
	local module = require(path.to.music)

	-- Create some biomes
	module.new("forest", {
	    {
	        id = "rbxassetid://123456789",
	        name = "Forest Theme",
	        artist = "Composer"
	    }
	}, vector.create(0, 0, 0), vector.create(100, 50, 100))

	-- Start tracking
	module:Start()

	-- When done
	module:Destroy()
	```
]]
function module.new(name: string, tracks: { Track }, position: vector, size: vector)
	local box = Instance.new("Part")
	hydration(box) {
		Anchored = true,
		CanCollide = false,
		Transparency = 1,
		Position = position,
		Size = size,
	}

	module.biomes[name] = {
		tracks = tracks,
		bounding_box = box,
	}
end

function module:GetTracks(biomeName: string): { Track }?
	local biome = select(
		2,
		future
			.Try(function()
				return module.biomes[biomeName]
			end)
			:Unwrap()
	)

	if biome then
		return biome.tracks
	else
		return nil
	end
end

function module:Start()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart

	-- Track position and check biomes less frequently
	local last_check: number = 0.0
	local check_interval = 1 / 2 -- 0.5
	local last_postion = Vector3.zero

	module._trove:Connect(RunService.Heartbeat, function(dt: number)
		debug.profilebegin("music-track")

		last_check += dt :: number
		if last_check < check_interval then
			debug.profileend()

			return
		end
		last_check = 0

		local position = hrp.Position
		if last_postion and (position - last_postion).Magnitude < 1 then
			debug.profileend()

			return
		end
		last_postion = position

		-- Check if player is in any biome
		local inAnyBiome = false
		for biomeName, biomeData in pairs(module.biomes) do
			local box = biomeData.bounding_box
			if
				box
				and (position.X >= box.Position.X - box.Size.X / 2)
				and (position.X <= box.Position.X + box.Size.X / 2)
				and (position.Y >= box.Position.Y - box.Size.Y / 2)
				and (position.Y <= box.Position.Y + box.Size.Y / 2)
				and (position.Z >= box.Position.Z - box.Size.Z / 2)
				and (position.Z <= box.Position.Z + box.Size.Z / 2)
			then
				-- Player is in this biome
				inAnyBiome = true

				-- If this is a new biome, play a random track
				if module.current_biome ~= biomeName then
					module.current_biome = biomeName

					module:PlayRandomTrack(biomeName)
				end

				break
			end
		end

		-- Stop module if player left the current biome
		if not inAnyBiome and module.current_biome ~= nil and module.current_biome ~= "" then
			module:StopCurrentTrack()
			module.current_biome = ""
		end

		debug.profileend()
	end)
end

function module:SetPlaying(track: Track?)
	module.Playing:Set(track)
end

function module:GetBiome()
	return module.current_biome
end

function module:GetCurrentTrack()
	return module.current_track
end

function module:GetPlaying()
	return module.Playing
end

function module:PlayRandomTrack(biomeName: string)
	local tracks = module:GetTracks(biomeName)
	if not tracks or #tracks == 0 then
		return
	end

	-- Select random track
	local track = tracks[random.integer(1, #tracks)] :: Track

	-- Stop any currently Playing track
	if module.current_track then
		module:StopCurrentTrack()
	end

	-- Add the new track to the audio system if not already present (track locally)
	local trackName = tostring(track.id)
	if not module.added_music[trackName] then
		audio:AddMusic(trackName, track.id, {
			volume = 1 / 8,
			looped = true,
		})
		module.added_music[trackName] = true
	end

	-- Play the new track
	module.current_track = track
	audio:PlayMusic(trackName)
	module:SetPlaying(track)
end

function module:StopCurrentTrack()
	local current_track = module.current_track
	if current_track then
		local trackName = tostring(current_track.id)
		audio:StopMusic(trackName)
		module.current_track = nil
		module:SetPlaying(nil)
	end
end

function module:Destroy()
	module:StopCurrentTrack()

	module.current_biome = ""

	module._trove:Clean()
end

return module
