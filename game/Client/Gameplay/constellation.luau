--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local hydration = require(ReplicatedStorage.Utility.hydration)
local input = require(ReplicatedStorage.Packages.input)
local random = require(ReplicatedStorage.Utility.random)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- constellation.luau
-- makes a constellation trail effect,
-- following the mouse

local module = {}
module.__index = module

local default_config = {
	max_stars = 80,
	star_size = UDim2.fromOffset(3, 3),
	star_color = Color3.fromHex("#FFFFFF"),
	star_transparency = 0.3,

	line_color = Color3.fromRGB(100, 150, 255),
	line_transparency = 0.7,
	line_thickness = 1,
	connection_distance = 150,

	trail_length = 50,
	spawn_rate = 0.02,
	fade_speed = 2,
	spread_radius = 30,

	mouse_star_color = Color3.fromRGB(255, 200, 100),
}

export type ConstellationConfig = typeof(default_config)
type Constellation = typeof(module.new(Instance.new("ScreenGui")))
type StarData = {
	frame: Frame,
	x: number,
	y: number,
	life: number,
	creation_time: number,
}

function module.new(ancestor: LayerCollector, config: ConstellationConfig?)
	local self = setmetatable({}, module)

	self.config = config or default_config
	tablekit.Reconcile(self.config, default_config)

	self.parent = ancestor
	self.stars = {} :: { StarData } -- currently visible stars
	self.star_cache = {} :: { Frame } -- pooled star objects for reuse
	self.lines = {} :: { Frame }
	self.line_cache = {} :: { Frame }
	self.active = false
	self._connections = {} :: { RBXScriptConnection }
	self.last_spawn_time = 0
	self.mouse = input.Mouse.new()

	self.container = Instance.new("Frame")
	hydration(self.container) {
		Name = "ConstellationContainer",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.new(),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Parent = ancestor,
	}

	-- initialize star cache
	self:InitializeCache()

	return self
end

function module:InitializeCache(self: Constellation)
	for i = 1, self.config.max_stars do
		local star = self:CreateStar(self)
		star.Visible = false

		table.insert(self.star_cache, star)
	end

	for i = 2, self.config.max_stars * 2 do
		local line = self:CreateLine(self)
		line.Visible = false

		table.insert(self.line_cache, line)
	end
end

function module:CreateStar(self: Constellation)
	local star = Instance.new("Frame")
	hydration(star) {
		Name = "Star",
		Size = self.config.star_size,
		AnchorPoint = (Vector2.one / 2),
		BackgroundColor3 = self.config.star_color,
		BackgroundTransparency = self.config.star_transparency,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = self.container,
	}

	local corner = Instance.new("UICorner")
	hydration(corner) {
		CornerRadius = UDim.new(1),
		Parent = star,
	}

	return star
end

function module:CreateLine(self: Constellation)
	local line = Instance.new("Frame")
	hydration(line) {
		Name = "ConnectionLine",
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = self.container,
	}

	return line
end

function module:GetStarFromCache(self: Constellation)
	if #self.star_cache > 0 then
		return table.remove(self.star_cache)
	else
		return self:CreateStar(self)
	end
end

function module:ReturnStarToCache(self: Constellation, star: Frame)
	star.Visible = false

	table.insert(self.star_cache, star)
end

function module:GetLineFromCache(self: Constellation)
	if #self.line_cache > 0 then
		return table.remove(self.line_cache)
	else
		return self:CreateLine(self)
	end
end

function module:ReturnLineToCache(self: Constellation, line: Frame)
	line.Visible = false

	table.insert(self.line_cache, line)
end

function module:SpawnStar(self: Constellation, x: number, y: number)
	local spread_x = (random.float() - 0.5) * self.config.spread_radius
	local spread_y = (random.float() - 0.5) * self.config.spread_radius

	local star = self:GetStarFromCache(self) :: Frame

	local star_data = {
		frame = star,
		x = x + spread_x,
		y = y + spread_y,
		life = 1,
		creation_time = os.time(),
	}

	hydration(star_data.frame) {
		Position = UDim2.fromOffset(star_data.x, star_data.y),
		BackgroundColor3 = self.config.star_color,
		BackgroundTransparency = self.config.star_transparency,
		Visible = true,
	}

	table.insert(self.stars, star_data)

	if #self.stars > self.config.trail_length then
		local old_star = table.remove(self.stars, 1)

		if old_star then
			self:ReturnStarToCache(self, old_star.frame)
		end
	end
end

function module:UpdateStars(self: Constellation, deltaTime: number)
	local stars_to_remove = {}

	for i, star in ipairs(self.stars) do
		star.life -= (deltaTime * self.config.fade_speed)

		if star.life <= 0 then
			table.insert(stars_to_remove, i)
		else
			local transparency = 1 - star.life
			local star_transparency = self.config.star_transparency

			star.frame.BackgroundTransparency = star_transparency + transparency * (1 - star_transparency)
		end
	end

	for i = #stars_to_remove, 1, -1 do
		local index = stars_to_remove[i]
		local dead_star = table.remove(self.stars, index)

		if dead_star then
			self:ReturnStarToCache(self, dead_star.frame)
		end
	end
end

function module:DrawConnections(self: Constellation)
	for i, line in ipairs(self.lines) do
		self:ReturnLineToCache(self, line)
	end

	self.lines = {}

	for i = 1, #self.stars do
		for j = i + 1, #self.stars do
			local star_1 = self.stars[i]
			local star_2 = self.stars[j]

			local distance_x = star_2.x - star_1.x
			local distance_y = star_2.y - star_1.y

			-- pythag?
			local distance = math.sqrt((distance_x * distance_x) + (distance_y * distance_y))

			if distance < self.config.connection_distance then
				self:DrawLine(self, star_1, star_2, distance)
			end
		end
	end
end

function module:DrawLine(self: Constellation, star_1: StarData, star_2: StarData, distance: number)
	local distance_x = star_2.x - star_1.x
	local distance_y = star_2.y - star_1.y

	local length = math.sqrt((distance_x * distance_x) + (distance_y + distance_y))
	local angle = math.atan2(distance_y, distance_x) -- arc tanget 2

	local opacity = 1 - (distance / self.config.connection_distance)
	local average_life = (star_1.life + star_2.life) / 2 -- finds the mean

	local transparency = 1 - (opacity * average_life * (1 - self.config.line_transparency))

	local line = self:GetLineFromCache(self) :: Frame
	hydration(line) {
		Size = UDim2.fromOffset(length, self.config.line_thickness),
		Position = UDim2.fromOffset(star_1.x, star_1.y),
		AnchorPoint = Vector2.new(0, 0.5),
		Rotation = math.deg(angle),
		BackgroundColor3 = self.config.line_color,
		BackgroundTranspency = transparency,
		Visible = true,
	}

	table.insert(self.lines, line)
end

function module:On(self: Constellation)
	if self.active then
		return
	end

	self.active = true

	local last_update = os.time()

	local conn = nil

	conn = RunService.Heartbeat:Connect(function(deltaTime)
		if not self.active then
			return
		end

		local now = os.time()

		last_update = now

		local mouse_position: Vector2 = self.mouse:GetPosition()

		if mouse_position and (now - self.last_spawn_time) >= self.config.spawn_rate then
			self:SpawnStar(self, mouse_position.X, mouse_position.Y)
			self.last_spawn_time = now
		end

		self:UpdateStars(self, deltaTime)
		self:DrawConnections(self)
	end)

	table.insert(self._connections, conn)
end

function module:Off(self: Constellation)
	self.active = false

	table.remove(self._connections)
end

return module
