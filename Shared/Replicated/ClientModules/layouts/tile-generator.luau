--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- tile-generator
-- wip

local module = {}
module.__index = module

type Shapes = "Square" | "Circle"

export type LayerConfig = {
	layer: number,
	tile_shape: Shapes?,
	tile_size: number,
	tile_rotation: number?,
	tile_thickness: number?,
	tile_circle_size: number?,
	foreground_color: Color3?,
	foreground_gradient: { a: Color3, b: Color3, rotation: number }?,
	foreground_opacity: number?,
	grid_offset_x: number?,
	grid_offset_y: number?,
	tile_rows: number | string?,
	tile_columns: number | string?,
}

export type Config = {
	parent: Instance,
	layers: { LayerConfig },
}

-- to snake-case
local default_config = {
	grid_offset_x = 0,
	grid_offset_y = 0,
	tiles = true,
	tile_shape = "Square",
	tile_rows = "@calc",
	tile_columns = "@calc",
	tile_size = 256,
	tile_rotation = 0,
	tile_thickness = 2.5,
	tile_circle_size = 32,
	background_color = Color3.fromRGB(30, 31, 36),
	background_opacity = 0,
	foreground_color = Color3.fromRGB(57, 58, 65),
	foreground_opacity = 0,
	performance_mode = false, -- Only needed when going under 24 (prevents crash)
	minimum_tile_size = 24,
}

type TileGenerator = typeof(module.new(default_config))

function module.new(config: Config)
	local self = setmetatable({}, module)

	self.parent = config.parent

	self.layers = config.layers

	for i, layer in ipairs(self.layers) do
		self.layers[i] = tablekit.Reconcile(layer :: any, default_config) :: LayerConfig
	end

	return self
end

function module:CreateBackground(self: TileGenerator, layer_config: LayerConfig)
	local background = Instance.new("Frame")
	hydration(background, {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = layer_config.background_color or Color3.fromRGB(30, 31, 36),
		BackgroundTransparency = 1 - (layer_config.background_opacity or 0),
		BorderSizePixel = 0,
		ZIndex = 0,
	})
end

function module:Generate()
	--
end
