--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local audio = require(ReplicatedStorage.Modules.audio)

local observer = require(ReplicatedStorage.Utility.observer)
local random = require(ReplicatedStorage.Utility.random)
local trove = require(ReplicatedStorage.Packages.trove)

-- music.luau

local module = {}

local biomes = {}
local Playing = observer.new(nil) :: observer.Observer<Track?>
local _trove = trove.new()
local current_biome = "" :: string?
local current_track = nil :: Track?
local added_music = {}

local events = ReplicatedStorage.Events

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
	}, Vector3.new(0, 0, 0), Vector3.new(100, 50, 100))

	-- Start tracking
	module:Start()

	-- When done
	module:Destroy()
	```
]]
function module.new(name: string, tracks: { Track }, position: Vector3, size: Vector3)
	local box = Instance.new("Part")

	box.Anchored = true
	box.CanCollide = false
	box.Transparency = 1
	box.Position = position
	box.Size = size

	biomes[name] = {
		tracks = tracks,
		bounding_box = box,
	}
end

function module:GetTracks(biome_name: string): { Track }?
	local biome = biomes[biome_name]

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

	_trove:Connect(RunService.Heartbeat, function(dt: number)
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
		local in_any_biome = false
		for biome_name, biome_data in pairs(biomes) do
			local box = biome_data.bounding_box
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
				in_any_biome = true

				-- If this is a new biome, play a random track
				if current_biome ~= biome_name then
					current_biome = biome_name

					module:PlayRandomTrack(biome_name)
				end

				break
			end
		end

		-- Stop module if player left the current biome
		if not in_any_biome and current_biome ~= nil and current_biome ~= "" then
			module:StopCurrentTrack()
			current_biome = ""
		end

		debug.profileend()
	end)
end

function module:SetPlaying(track: Track?)
	Playing:Set(track)
end

function module:GetBiome()
	return current_biome
end

function module:GetCurrentTrack()
	return current_track
end

function module:GetPlaying()
	return Playing
end

function module:PlayRandomTrack(biome_name: string)
	local tracks = module:GetTracks(biome_name)
	if not tracks or #tracks == 0 then
		return
	end

	-- Select random track
	local track = tracks[random.integer(1, #tracks)] :: Track

	-- Stop any currently Playing track
	if current_track then
		module:StopCurrentTrack()
	end

	-- Add the new track to the audio system if not already present (track locally)
	local trackName = tostring(track.id)
	if not added_music[trackName] then
		audio:AddMusic(trackName, track.id, {
			volume = 1 / 8,
			looped = true,
		})
		added_music[trackName] = true
	end

	-- Play the new track
	current_track = track
	audio:PlayMusic(trackName)
	module:SetPlaying(track)
end

function module:StopCurrentTrack()
	local current_track = current_track
	if current_track then
		local trackName = tostring(current_track.id)
		audio:StopMusic(trackName)
		current_track = nil
		module:SetPlaying(nil)
	end
end

function module:Destroy()
	module:StopCurrentTrack()

	current_biome = ""

	_trove:Clean()
end

events.SetMusicVolume.OnClientEvent:Connect(function(volume: number)
	for name, data in pairs(biomes) do
		for _, track in ipairs(data.tracks) do
			local trackName = tostring(track.id)
			audio:ConfigureMusic(trackName, {
				volume = volume,
			})
		end
	end
end)

events.ToggleMusic.OnClientEvent:Connect(function(enabled: boolean)
	if not enabled then
		module:StopCurrentTrack()
		audio:SetMusicEnabled(false)
	else
		audio:SetMusicEnabled(true)
		-- Re-play current track if music is enabled again
		if current_biome and current_biome ~= "" then
			module:PlayRandomTrack(current_biome)
		end
	end
end)

events.ToggleGUISound.OnClientEvent:Connect(function(enabled: boolean)
	audio:SetSFXEnabled(enabled)
end)

return module
