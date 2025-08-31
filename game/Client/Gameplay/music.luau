--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local audio = require(ReplicatedStorage.Modules.audio)
local boundingbox = require(ReplicatedStorage.Classes.boundingbox)
local observer = require(ReplicatedStorage.Utility.observer)

-- music.luau

local music = {
	biomes = {},
	playing = observer.new({}),
}

export type trackData = {
	id: string,
	name: string,
	length: number?,
	artist: string?,
	album: string?,
	genre: string?,
}

function music.newBiome(name: string, tracks: { trackData }, position: Vector3, size: Vector3)
	local box = boundingbox.new(position, size)
	music.biomes[name] = {
		tracks = tracks,
		boundingBox = box,
	}
end

function music.getBiome(position: Vector3): string?
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

function music:start()
	print("Music system started")
	-- Implementation for tracking player position and changing music would go here
	for name, biome in pairs(music.biomes) do
		local entered = biome.boundingBox.OnEnter

		entered:Connect(function(position)
			--
		end)
	end
end
