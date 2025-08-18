--!strict

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local ChunkModule = require(script.Chunk)
local random = require(ReplicatedStorage.Utility.random)

-- Constants
local TWEEN_TIME = 0.4
local COOLDOWN_DIVISION = 8
local BEND_MULTIPLIER = 8

-- Types
export type GrassBlade = BasePart & {
	Top: Attachment,
	Bottom: Attachment,
	Grass: Beam,
}

type BiomeSettings = {
	biomeFolder: Folder,
	biomeName: string,
	tintIndex: Color3,
	grassColor: Color3,
	sizeVariation: number,
	downsizing: number,
	grassThickness: number,
	chunkDensity: number,
}

-- Module
local Biome = {
	BiomeTable = {},
}

--[[
	 Sets visual and behavioral properties for grass foliage
	 
	@param grass: GrassBlade - The grass instance to configure
   @param settings: BiomeSettings - Configuration settings for the grass
]]
function Biome:SetFoliageSettings(grass: GrassBlade, settings: BiomeSettings)
	if grass.Name ~= "Hitbox" then
		return
	end

	local hitbox = grass
	local primary = grass.Top
	local beam = grass.Grass

	-- Configure appearance
	beam.Color = ColorSequence.new(settings.grassColor, settings.tintIndex)
	beam.Width0 = settings.grassThickness

	-- Apply size variation
	if settings.sizeVariation and settings.sizeVariation ~= 0 then
		local downsizeFactor = settings.downsizing > 0 and settings.downsizing or 1
		local heightVariation = random.integer(
			primary.Position.Y - settings.sizeVariation / downsizeFactor,
			primary.Position.Y + settings.sizeVariation / downsizeFactor
		)
		primary.Position =
			Vector3.new(primary.Position.X, primary.Position.Y + heightVariation, primary.Position.Z)
	end

	-- Setup touch events
	hitbox.Touched:Connect(function(otherPart: BasePart)
		if not otherPart.Parent then
			return
		end

		local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
		if humanoid then
			grass:SetAttribute("Touching", true)
		end
	end)

	hitbox.TouchEnded:Connect(function()
		grass:SetAttribute("Touching", false)
	end)
end

--[[
	 Registers a new biome with the specified settings

    @param settings: BiomeSettings - Configuration settings for the biome
]]
function Biome:RegisterBiome(settings: BiomeSettings)
	-- Update biome registry
	local existingIndex = table.find(self.BiomeTable, settings.biomeName)
	if existingIndex then
		table.insert(self.BiomeTable, existingIndex, settings.biomeName)
	else
		table.insert(self.BiomeTable, settings.biomeName)
	end

	-- Configure biome elements
	for _, grass: GrassBlade in pairs(settings.biomeFolder:GetChildren()) do
		if grass:IsA("Folder") then
			ChunkModule:HandleChunk(grass, settings)
		end

		self:SetFoliageSettings(grass, settings)
	end
end

--[[ 
	Configures a biome with the specified settings

   @param settings - Configuration settings for the biome
	 
	 ```luau
	 local settings = {
    biomeFolder = biomeFolder,
    biomeName = "Forest",
    tintIndex = 1,
    grassColor = Color3.fromRGB(0, 255, 0),
    sizeVariation = 0.5,
    downsizing = 1,
    grassThickness = 0.1,
    chunkDensity = 10
	}

	Biome:ConfigureBiome(settings)
	```
]]
function Biome:ConfigureBiome(settings: BiomeSettings)
	self:RegisterBiome(settings)
end

return Biome
