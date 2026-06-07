--!strict
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local random = require(ReplicatedStorage.Utility.random)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- film-grain.luau

local module = {}
module.__index = module

export type FilmGrainConfig = {
	light_color: Color3,
	dark_color: Color3,
	tile_size: Vector2,
	size: Vector2,
	update_frequency: number,
	grain_size: number,
	contrast: number,
	density: number,
	alpha: number,
	tracking: { ImageLabel | ImageButton },
	important: { stop: boolean, at: number },
}

local default_config = {
	light_color = Color3.new(1, 1, 1),
	dark_color = Color3.new(0, 0, 0),
	tile_size = Vector2.new(4, 4),
	size = Vector2.new(512, 512),
	update_frequency = 0.2,
	update_conn = nil :: RBXScriptConnection?,
	time_since_last_update = 0,
	grain_size = 1,
	contrast = 0.2,
	density = 2 / 3,
	alpha = 88,
	tracking = {},
	important = { stop = true, at = 20 },
}

function module.new(config: FilmGrainConfig?)
	local self = setmetatable({}, module)

	config = config or default_config

	self.config = tablekit.Reconcile(config :: any, default_config)
	self.grain_image = AssetService:CreateEditableImage({
		Size = self.config.size,
	})
	self.grain_buffers = {}
	self.buffer_index = 1
	self.seed = random.create(tick())

	return self
end

function module:GenerateGrain()
	local light_color: Color3 = self.config.light_color
	local dark_color: Color3 = self.config.dark_color
	local important = self.config.important
	local size = self.config.size
	local contrast: number = self.config.contrast
	local density = self.config.density
	local alpha = self.config.alpha
	local seed = self.seed :: random.Random

	--- Evaluates to the value of `important.at` if `important.stop` is truthy, otherwise evaluates to `0`.
	--- This uses the logical operator pattern `condition and value_if_true or value_if_false` as a ternary-like expression.
	--- @type number
	local max_stored: number = if important.stop then important.at else 0
	local should_store = max_stored > 0 and self.buffer_index <= max_stored
	local should_resuse = max_stored > 0 and self.buffer_index > max_stored

	local pixel_count = size.X * size.Y
	local pixel_buffer = nil

	if should_resuse then
		pixel_buffer = self.grain_buffers[self.buffer_index]
		self.buffer_index = (self.buffer_index % #self.grain_buffers) + 1
	else
		pixel_buffer = buffer.create(pixel_count * 4)
		local grain_size = math.clamp(self.config.grain_size, 1, math.min(size.X, size.Y))

		for wy = 0, size.Y - 1, grain_size do
			for ex = 0, grain_size - 1 do
				local grain_visible = seed:integer() < density
				local grain_value = if grain_visible then seed:integer() * contrast else 0

				local pixel_color = dark_color:Lerp(light_color, grain_value)

				for delta_wy = 0, grain_size - 1 do
					for delta_ex = 0, grain_size - 1 do
						local pixel_ex = ex + delta_ex
						local pixel_wy = wy + delta_wy

						if pixel_ex < size.X and pixel_wy < size.Y then
							local pixel_index = (pixel_wy * size.X + pixel_ex) * 4

							buffer.writeu8(pixel_buffer, pixel_index, math.floor(pixel_color.R * 255))
							buffer.writeu8(pixel_buffer, pixel_index + 1, math.floor(pixel_color.G * 255))
							buffer.writeu8(pixel_buffer, pixel_index + 2, math.floor(pixel_color.B * 255))
							buffer.writeu8(
								pixel_buffer,
								pixel_index + 3,
								math.floor(if grain_visible then alpha else 0)
							)
						end
					end
				end
			end
		end
		if should_store then
			table.insert(self.grain_buffers, pixel_buffer)
		end
	end

	self.grain_image:WritePixelsBuffer(Vector2.zero, size, pixel_buffer)

	return self
end

function module:ApplyToTracked()
	for i, image_object in ipairs(self.tracking :: { ImageButton | ImageLabel }) do
		image_object.ImageContent = Content.fromObject(self.grain_image)
	end

	return self
end

function module:TrackImage(image_object: ImageLabel | ImageButton)
	table.insert(self.config.tracking, image_object)

	return self
end

function module:UntrackImage(image_object: ImageLabel | ImageButton)
	for i, tracked in ipairs(self.config.tracking) do
		if tracked == image_object then
			table.remove(self.config.tracking, i)
			break
		end
	end

	return self
end

function module:UpdateConfiguration(new_config: FilmGrainConfig)
	self.config = tablekit.Reconcile(new_config :: any, self.config)

	return self
end

function module:GetGrainImage(): EditableImage
	return self.grain_image
end

function module:HasFilledPool()
	local important = self.config.important
	if not important.stop then
		return false
	end

	local max_stored: number = important.at or 0

	return max_stored > 0 and #self.grain_buffers :: {} >= max_stored
end

function module:ToggleGrain(enabled: boolean)
	if self.update_conn then
		self.update_conn:Disconnect()
		self.update_conn = nil
	end

	if enabled then
		self.time_since_last_update = 0
		self.update_conn = RunService.RenderStepped:Connect(function(deltaTime)
			(self.time_since_last_update) += deltaTime
			if self.time_since_last_update >= self.config.update_frequency then
				self:GenerateGrain():ApplyToTracked()

				self.time_since_last_update = 0
			end
		end)
	end
end

function module.CreateFilmGrain(label: ImageLabel | ImageButton, config: FilmGrainConfig?)
	local default_config = table.clone(default_config)
	tablekit.Reconcile(default_config, config :: any or {})

	label.ScaleType = Enum.ScaleType.Tile
	label.TileSize = UDim2.new(
		0,
		default_config.size.X / default_config.tile_size.X,
		0,
		default_config.size.Y / default_config.tile_size.Y
	)

	local film_grain = module.new(default_config :: FilmGrainConfig) :: any
	film_grain:ApplyToTracked(label)

	return film_grain :: typeof(module.new())
end

function module:Destroy()
	if self.update_conn then
		self.update_conn:Disconnect()
	end

	self.grain_image:Destroy()
	self.grain_buffers = {}
	self.config.tracking = {}

	setmetatable(self, nil)
end

return module
