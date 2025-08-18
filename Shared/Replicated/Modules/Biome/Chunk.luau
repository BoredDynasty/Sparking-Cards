--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local random = require(ReplicatedStorage.Utility.random)

-- Constants
local BIOME_STORAGE = ServerStorage:WaitForChild("BiomeStorage") :: Folder & any
local DENSITY_MULTIPLIER = 6

-- Types
type ChunkSettings = {
	density: number,
	biomeFolder: Folder,
	biomeName: string,
	tintIndex: number,
	grassColor: Color3,
	sizeVariation: number,
	downsizing: number,
	grassThickness: number,
}

local Chunk = {}

--[[ 
   Handles chunk generation with specified biome settings

   @param chunkHolder: Folder containing the chunk
   @param settings: ChunkSettings for biome configuration

   ```luau
   local settings = {
    density = 10,
    biomeFolder = biomeFolder,
    biomeName = "Forest",
    tintIndex = 1,
    grassColor = Color3.fromRGB(0, 255, 0),
    sizeVariation = 0.5,
    downsizing = 1,
    grassThickness = 0.1
   }

   Chunk:HandleChunk(chunkHolder, settings)
   ```
]]
function Chunk:HandleChunk(chunkHolder: Folder, settings: ChunkSettings)
	-- Setup chunk handle
	local handle = chunkHolder:FindFirstChild("Handle")
	handle.CanCollide = false
	handle.Transparency = 1
	handle.Anchored = true

	-- Calculate chunk boundaries
	local chunkSize = handle.Size
	local chunkPosition = handle.Position
	local boundaryMin = chunkPosition - (chunkSize / 2)
	local boundaryMax = chunkPosition + (chunkSize / 2)

	-- Apply density settings
	local finalDensity = settings.density
	if chunkHolder.OverrideDensity.Value and chunkHolder.OverrideDensity.Value > 0 then
		finalDensity = chunkHolder.OverrideDensity.Value
	end
	finalDensity *= DENSITY_MULTIPLIER

	-- Generate grass
	for _ = 0, finalDensity do
		local grassPosition = Vector3.new(
			random.integer(boundaryMin.X, boundaryMax.X),
			handle.Position.Y,
			random.integer(boundaryMin.Z, boundaryMax.Z)
		)

		local grassTemplate = BIOME_STORAGE.Grass.Hitbox
		local grass = grassTemplate:Clone()
		grass.Parent = chunkHolder
		grass.Position = grassPosition

		--[[
        biome:SetFoliageSettings(
            grass,
            settings.biomeFolder,
            settings.biomeName,
            settings.tintIndex,
            settings.grassColor,
            settings.sizeVariation,
            settings.downsizing,
            settings.grassThickness,
            finalDensity
        )
        --]]
	end
end

return Chunk
