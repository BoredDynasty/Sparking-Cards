--[=[
	coolTransitions by @boshy_z

	local coolTransitions = require(path.to.coolTransitions)
	local manager = coolTransitions.TransitionManager.new(playerGui)

	manager:Play("In", 1, "Center", "Hexagon")

	manager:PlayInOut(2, function()
		-- load your scene here
	end, "Center", "Hexagon", 0.5)

	manager:Destroy()
]=]

local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

-- Read shape images from ImageLabel children (set via instance properties, not code)
local SHAPE_IMAGES = {}
do
	-- a rather tedious syncing fix
	local Instances = {
		Circle = Instance.new("ImageLabel"),
		Diamond = Instance.new("ImageLabel"),
		Hexagon = Instance.new("ImageLabel"),
		Triangle = Instance.new("ImageLabel"),
	}

	Instances.Circle.Name = "Circle"
	Instances.Circle.Visible = false
	Instances.Circle.BackgroundTransparency = 1
	Instances.Circle.Image = "rbxassetid://124367192934018"
	Instances.Circle.Parent = script

	Instances.Diamond.Name = "Diamond"
	Instances.Diamond.Visible = false
	Instances.Diamond.BackgroundTransparency = 1
	Instances.Diamond.Image = "rbxassetid://127066116771610"
	Instances.Diamond.Parent = script

	Instances.Hexagon.Name = "Hexagon"
	Instances.Hexagon.Visible = false
	Instances.Hexagon.BackgroundTransparency = 1
	Instances.Hexagon.Image = "rbxassetid://85599636784586"
	Instances.Hexagon.Parent = script

	Instances.Triangle.Name = "Triangle"
	Instances.Triangle.Visible = false
	Instances.Triangle.BackgroundTransparency = 1
	Instances.Triangle.Image = "rbxassetid://122383304460748"
	Instances.Triangle.Parent = script
end

for _, child in script:GetChildren() do
	if child:IsA("ImageLabel") then
		SHAPE_IMAGES[child.Name] = child.Image
	end
end

ContentProvider:PreloadAsync(script:GetChildren())

local RENDER_STEP_NAME = "coolTransitions_render"
local DEFAULT_COLOR = Color3.fromRGB(20, 20, 20)
local DEFAULT_SCREEN_WIDTH = 1920
local DEFAULT_SCREEN_HEIGHT = 1080
local BG_FADE_START = 0.95
local BG_FADE_RANGE = 1 - BG_FADE_START

-- ── Easing ─────────────────────────────────────────────────────

local function easeInOutSine(t: number): number
	return -(math.cos(math.pi * t) - 1) / 2
end

local function easeOutQuad(t: number): number
	return 1 - (1 - t) * (1 - t)
end

local function easeInQuad(t: number): number
	return t * t
end

-- ── GridEffect ─────────────────────────────────────────────────

local GridEffect = {}
GridEffect.__index = GridEffect

function GridEffect.new(config)
	return setmetatable({
		_config = config,
		_cells = {},
		_background = nil :: Frame?,
		_screenWidth = 0,
		_screenHeight = 0,
	}, GridEffect)
end

function GridEffect:Build(gui: ScreenGui, screenWidth: number, screenHeight: number, color: Color3)
	self._screenWidth = screenWidth
	self._screenHeight = screenHeight

	local bg = Instance.new("Frame")
	bg.Name = "GridBackground"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = color
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.ZIndex = 0
	bg.Visible = false
	bg.Parent = gui
	self._background = bg

	local specs = self._config.cells(screenWidth, screenHeight)
	local hasContent = self._config.content ~= nil
	local cellCount = #specs
	local cells = table.create(cellCount)

	for i, spec in specs do
		local element: GuiObject
		if hasContent then
			local image = Instance.new("ImageLabel")
			image.Image = self._config.content
			image.ImageColor3 = color
			image.BackgroundTransparency = 1
			image.ScaleType = Enum.ScaleType.Stretch
			image.AnchorPoint = Vector2.new(0.5, 0.5)
			image.Position = UDim2.fromOffset(spec.x, spec.y)
			image.Size = UDim2.fromOffset(spec.width, spec.height)
			image.Visible = false
			if spec.rotation then
				image.Rotation = spec.rotation
			end
			element = image
		else
			local frame = Instance.new("Frame")
			frame.BackgroundColor3 = color
			frame.BorderSizePixel = 0
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position = UDim2.fromOffset(spec.x, spec.y)
			frame.Size = UDim2.fromOffset(spec.width, spec.height)
			frame.Visible = false
			element = frame
		end

		element.ZIndex = 1
		element.Parent = gui
		cells[i] = {
			element = element,
			x = spec.x,
			y = spec.y,
			fullWidth = spec.width,
			fullHeight = spec.height,
			threshold = 0,
			lastSize = -1,
		}
	end

	self._cells = cells
end

function GridEffect:Prepare(origin: string)
	if self._config.randomThreshold then
		for _, cell in self._cells do
			cell.threshold = math.random()
		end
		return
	end

	local ox, oy = self:_getOriginPoint(origin)
	local maxDist = 0
	for _, cell in self._cells do
		local dx = cell.x - ox
		local dy = cell.y - oy
		local dist = math.sqrt(dx * dx + dy * dy)
		if dist > maxDist then
			maxDist = dist
		end
	end
	if maxDist == 0 then
		return
	end
	local invMax = 1 / maxDist
	for _, cell in self._cells do
		local dx = cell.x - ox
		local dy = cell.y - oy
		cell.threshold = math.sqrt(dx * dx + dy * dy) * invMax
	end
end

function GridEffect:Update(progress: number, direction: string)
	local isIn = direction == "In"
	local adjusted = if isIn then progress else 1 - progress
	local spread = self._config.spread
	local invRange = 1 / (1 - spread)
	local scaleUniform = self._config.scaleUniform

	local bgAlpha = math.clamp((adjusted - BG_FADE_START) / BG_FADE_RANGE, 0, 1)
	self._background.BackgroundTransparency = 1 - bgAlpha
	self._background.Visible = bgAlpha > 0

	for _, cell in self._cells do
		local linearT = math.clamp((adjusted - cell.threshold * spread) * invRange, 0, 1)
		local easedT = if isIn then easeOutQuad(linearT) else 1 - easeInQuad(1 - linearT)

		local pixelSize =
			math.floor(if scaleUniform then cell.fullWidth * easedT else cell.fullHeight * easedT)
		if pixelSize ~= cell.lastSize then
			cell.lastSize = pixelSize
			if scaleUniform then
				cell.element.Size = UDim2.fromOffset(pixelSize, pixelSize)
			else
				cell.element.Size = UDim2.fromOffset(cell.fullWidth, pixelSize)
			end
		end
		cell.element.Visible = easedT > 0.01
	end
end

function GridEffect:Show()
	self._background.BackgroundTransparency = 0
	self._background.Visible = true
	for _, cell in self._cells do
		cell.element.Size = UDim2.fromOffset(cell.fullWidth, cell.fullHeight)
		cell.element.Visible = true
		cell.lastSize = cell.fullHeight
	end
end

function GridEffect:Hide()
	self._background.BackgroundTransparency = 1
	self._background.Visible = false
	for _, cell in self._cells do
		cell.element.Visible = false
		cell.lastSize = -1
	end
end

function GridEffect:Destroy()
	if self._background then
		self._background:Destroy()
		self._background = nil
	end
	for _, cell in self._cells do
		cell.element:Destroy()
	end
	self._cells = {}
end

function GridEffect:_getOriginPoint(origin: string): (number, number)
	if origin == "Center" then
		return self._screenWidth / 2, self._screenHeight / 2
	elseif origin == "TopLeft" then
		return 0, 0
	end
	return self._screenWidth, self._screenHeight
end

-- ── Grid helpers ───────────────────────────────────────────────

local function rectGrid(
	screenWidth: number,
	screenHeight: number,
	cellSize: number,
	overflow: number,
	offsetRows: boolean?,
	checkerboard: boolean?,
	displaySize: number?
)
	local size = displaySize or cellSize
	local totalW = screenWidth + overflow * 2
	local totalH = screenHeight + overflow * 2
	local cols = math.ceil(totalW / cellSize) + 1
	local rows = math.ceil(totalH / cellSize) + 1

	local count = cols * rows
	if checkerboard then
		count = math.ceil(count / 2)
	end
	local specs = table.create(count)
	local idx = 0

	for col = 0, cols - 1 do
		for row = 0, rows - 1 do
			if checkerboard and (col + row) % 2 ~= 0 then
				continue
			end
			local x = col * cellSize - overflow + (if offsetRows and row % 2 == 1 then cellSize / 2 else 0)
			local y = row * cellSize - overflow
			idx += 1
			specs[idx] = { x = x, y = y, width = size, height = size }
		end
	end
	return specs
end

-- ── Grid configs ───────────────────────────────────────────────

local HEX_RADIUS = 55
local HEX_DISPLAY = 2 * HEX_RADIUS
local TRI_RADIUS = 50
local TRI_DISPLAY = math.ceil(2 * TRI_RADIUS * 1.45)
local TILE_SIZE = 80
local DOT_SPACING = 70
local DOT_DISPLAY = math.ceil(DOT_SPACING * 1.5)
local STRIPE_HEIGHT = 60
local CHECKER_DISPLAY = TILE_SIZE * 2

local GRID_CONFIGS = {}

GRID_CONFIGS.HEXAGON = {
	content = SHAPE_IMAGES.Hexagon,
	scaleUniform = true,
	spread = 0.65,
	randomThreshold = false,
	cells = function(sw, sh)
		local colSpacing = 1.5 * HEX_RADIUS
		local rowSpacing = math.sqrt(3) * HEX_RADIUS
		local oddOffset = rowSpacing / 2
		local ov = HEX_DISPLAY
		local cols = math.ceil((sw + ov * 2) / colSpacing) + 1
		local rows = math.ceil((sh + ov * 2) / rowSpacing) + 1
		local specs = table.create(cols * rows)
		local idx = 0
		for c = 0, cols - 1 do
			for r = 0, rows - 1 do
				idx += 1
				specs[idx] = {
					x = c * colSpacing - ov,
					y = r * rowSpacing + (if c % 2 == 1 then oddOffset else 0) - ov,
					width = HEX_DISPLAY,
					height = HEX_DISPLAY,
				}
			end
		end
		return specs
	end,
}

GRID_CONFIGS.TRIANGLE = {
	content = SHAPE_IMAGES.Triangle,
	scaleUniform = true,
	spread = 0.65,
	randomThreshold = false,
	cells = function(sw, sh)
		local colSpacing = TRI_RADIUS * math.sqrt(3) / 2
		local rowSpacing = TRI_RADIUS * 1.5
		local ov = TRI_DISPLAY
		local cols = math.ceil((sw + ov * 2) / colSpacing) + 1
		local rows = math.ceil((sh + ov * 2) / rowSpacing) + 1
		local specs = table.create(cols * rows)
		local idx = 0
		for c = 0, cols - 1 do
			for r = 0, rows - 1 do
				local pointsDown = (c + r) % 2 == 1
				idx += 1
				specs[idx] = {
					x = c * colSpacing - ov,
					y = r * rowSpacing - ov,
					width = TRI_DISPLAY,
					height = TRI_DISPLAY,
					rotation = if pointsDown then 180 else 0,
				}
			end
		end
		return specs
	end,
}

GRID_CONFIGS.TILES = {
	scaleUniform = true,
	spread = 0.65,
	randomThreshold = false,
	cells = function(sw, sh)
		return rectGrid(sw, sh, TILE_SIZE, TILE_SIZE)
	end,
}

GRID_CONFIGS.POLKA_DOTS = {
	content = SHAPE_IMAGES.Circle,
	scaleUniform = true,
	spread = 0.55,
	randomThreshold = false,
	cells = function(sw, sh)
		return rectGrid(sw, sh, DOT_SPACING, DOT_SPACING, true, false, DOT_DISPLAY)
	end,
}

GRID_CONFIGS.BLINDS = {
	scaleUniform = false,
	spread = 0.4,
	randomThreshold = false,
	cells = function(sw, sh)
		local fullWidth = sw + 200
		local rows = math.ceil((sh + STRIPE_HEIGHT * 2) / STRIPE_HEIGHT) + 1
		local specs = table.create(rows)
		for r = 0, rows - 1 do
			specs[r + 1] = {
				x = sw / 2,
				y = r * STRIPE_HEIGHT - STRIPE_HEIGHT,
				width = fullWidth,
				height = STRIPE_HEIGHT,
			}
		end
		return specs
	end,
}

GRID_CONFIGS.CHECKERBOARD = {
	scaleUniform = true,
	spread = 0.6,
	randomThreshold = false,
	cells = function(sw, sh)
		return rectGrid(sw, sh, TILE_SIZE, TILE_SIZE, false, true, CHECKER_DISPLAY)
	end,
}

GRID_CONFIGS.RANDOM_TILES = {
	scaleUniform = true,
	spread = 0.85,
	randomThreshold = true,
	cells = function(sw, sh)
		return rectGrid(sw, sh, TILE_SIZE, TILE_SIZE)
	end,
}

-- ── Overlay effects ────────────────────────────────────────────

local FadeEffect = {}
FadeEffect.__index = FadeEffect

function FadeEffect.new()
	return setmetatable({ _frame = nil :: Frame? }, FadeEffect)
end

function FadeEffect:Build(gui: ScreenGui, _sw: number, _sh: number, color: Color3)
	local frame = Instance.new("Frame")
	frame.Name = "Fade"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = gui
	self._frame = frame
end

function FadeEffect:Prepare(_origin: string) end

function FadeEffect:Update(progress: number, direction: string)
	local alpha = if direction == "In" then progress else 1 - progress
	self._frame.BackgroundTransparency = 1 - alpha
	self._frame.Visible = alpha > 0.01
end

function FadeEffect:Show()
	self._frame.BackgroundTransparency = 0
	self._frame.Visible = true
end

function FadeEffect:Hide()
	self._frame.BackgroundTransparency = 1
	self._frame.Visible = false
end

function FadeEffect:Destroy()
	self._frame:Destroy()
end

local ShapeEffect = {}
ShapeEffect.__index = ShapeEffect

function ShapeEffect.new(mode: string)
	return setmetatable({
		_mode = mode,
		_element = nil :: GuiObject?,
		_maxSize = 0,
		_originX = 0,
		_originY = 0,
		_screenWidth = 0,
		_screenHeight = 0,
	}, ShapeEffect)
end

function ShapeEffect:Build(gui: ScreenGui, screenWidth: number, screenHeight: number, color: Color3)
	self._screenWidth = screenWidth
	self._screenHeight = screenHeight
	local diagonal = math.sqrt(screenWidth * screenWidth + screenHeight * screenHeight)

	if self._mode == "box" then
		self._maxSize = math.max(screenWidth, screenHeight)
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = color
		frame.BorderSizePixel = 0
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Visible = false
		frame.Parent = gui
		self._element = frame
	elseif self._mode == "diamond" then
		self._maxSize = diagonal
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = color
		frame.BorderSizePixel = 0
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Rotation = 45
		frame.Visible = false
		frame.Parent = gui
		self._element = frame
	else
		self._maxSize = diagonal
		local image = Instance.new("ImageLabel")
		image.Image = SHAPE_IMAGES.Circle or ""
		image.ImageColor3 = color
		image.BackgroundTransparency = 1
		image.ScaleType = Enum.ScaleType.Stretch
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Visible = false
		image.Parent = gui
		self._element = image
	end
end

function ShapeEffect:Prepare(origin: string)
	if origin == "Center" then
		self._originX = self._screenWidth / 2
		self._originY = self._screenHeight / 2
	elseif origin == "TopLeft" then
		self._originX = 0
		self._originY = 0
	else
		self._originX = self._screenWidth
		self._originY = self._screenHeight
	end
	self._element.Position = UDim2.fromOffset(self._originX, self._originY)
end

function ShapeEffect:Update(progress: number, direction: string)
	local t = if direction == "In" then progress else 1 - progress
	if self._mode == "box" then
		self._element.Size =
			UDim2.fromOffset(math.floor(self._screenWidth * t), math.floor(self._screenHeight * t))
	else
		local size = math.floor(self._maxSize * t)
		self._element.Size = UDim2.fromOffset(size, size)
	end
	self._element.Visible = t > 0.01
end

function ShapeEffect:Show()
	if self._mode == "box" then
		self._element.Size = UDim2.fromOffset(self._screenWidth, self._screenHeight)
	else
		self._element.Size = UDim2.fromOffset(self._maxSize, self._maxSize)
	end
	self._element.Visible = true
end

function ShapeEffect:Hide()
	self._element.Visible = false
end

function ShapeEffect:Destroy()
	self._element:Destroy()
end

local LinearWipeEffect = {}
LinearWipeEffect.__index = LinearWipeEffect

function LinearWipeEffect.new()
	return setmetatable({
		_frame = nil :: Frame?,
		_screenWidth = 0,
		_wipeFromLeft = true,
	}, LinearWipeEffect)
end

function LinearWipeEffect:Build(gui: ScreenGui, screenWidth: number, _sh: number, color: Color3)
	self._screenWidth = screenWidth
	local frame = Instance.new("Frame")
	frame.Name = "LinearWipe"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Visible = false
	frame.Parent = gui
	self._frame = frame
end

function LinearWipeEffect:Prepare(origin: string)
	self._wipeFromLeft = origin ~= "BottomRight"
end

function LinearWipeEffect:Update(progress: number, direction: string)
	local t = if direction == "In" then progress else 1 - progress
	local offset = if self._wipeFromLeft
		then math.floor(-self._screenWidth * (1 - t))
		else math.floor(self._screenWidth * (1 - t))
	self._frame.Position = UDim2.fromOffset(offset, 0)
	self._frame.Visible = t > 0.01
end

function LinearWipeEffect:Show()
	self._frame.Position = UDim2.fromOffset(0, 0)
	self._frame.Visible = true
end

function LinearWipeEffect:Hide()
	self._frame.Visible = false
end

function LinearWipeEffect:Destroy()
	self._frame:Destroy()
end

local SplitEffect = {}
SplitEffect.__index = SplitEffect

function SplitEffect.new()
	return setmetatable({
		_left = nil :: Frame?,
		_right = nil :: Frame?,
		_screenWidth = 0,
		_screenHeight = 0,
	}, SplitEffect)
end

function SplitEffect:Build(gui: ScreenGui, screenWidth: number, screenHeight: number, color: Color3)
	self._screenWidth = screenWidth
	self._screenHeight = screenHeight

	local left = Instance.new("Frame")
	left.BackgroundColor3 = color
	left.BorderSizePixel = 0
	left.AnchorPoint = Vector2.new(1, 0)
	left.Size = UDim2.fromOffset(0, screenHeight)
	left.Visible = false
	left.Parent = gui
	self._left = left

	local right = Instance.new("Frame")
	right.BackgroundColor3 = color
	right.BorderSizePixel = 0
	right.AnchorPoint = Vector2.new(0, 0)
	right.Size = UDim2.fromOffset(0, screenHeight)
	right.Visible = false
	right.Parent = gui
	self._right = right
end

function SplitEffect:Prepare(_origin: string)
	local mid = math.floor(self._screenWidth / 2)
	self._left.Position = UDim2.fromOffset(mid, 0)
	self._right.Position = UDim2.fromOffset(mid, 0)
end

function SplitEffect:Update(progress: number, direction: string)
	local t = if direction == "In" then progress else 1 - progress
	local halfWidth = math.ceil(self._screenWidth / 2) + 2
	local w = math.floor(halfWidth * t)
	self._left.Size = UDim2.fromOffset(w, self._screenHeight)
	self._right.Size = UDim2.fromOffset(w, self._screenHeight)
	local visible = t > 0.01
	self._left.Visible = visible
	self._right.Visible = visible
end

function SplitEffect:Show()
	local halfWidth = math.ceil(self._screenWidth / 2) + 2
	self._left.Size = UDim2.fromOffset(halfWidth, self._screenHeight)
	self._right.Size = UDim2.fromOffset(halfWidth, self._screenHeight)
	self._left.Visible = true
	self._right.Visible = true
end

function SplitEffect:Hide()
	self._left.Visible = false
	self._right.Visible = false
end

function SplitEffect:Destroy()
	self._left:Destroy()
	self._right:Destroy()
end

local CrossWipeEffect = {}
CrossWipeEffect.__index = CrossWipeEffect

function CrossWipeEffect.new()
	return setmetatable({
		_horizontal = nil :: Frame?,
		_vertical = nil :: Frame?,
		_screenWidth = 0,
		_screenHeight = 0,
	}, CrossWipeEffect)
end

function CrossWipeEffect:Build(gui: ScreenGui, screenWidth: number, screenHeight: number, color: Color3)
	self._screenWidth = screenWidth
	self._screenHeight = screenHeight

	local h = Instance.new("Frame")
	h.BackgroundColor3 = color
	h.BorderSizePixel = 0
	h.AnchorPoint = Vector2.new(0.5, 0.5)
	h.Position = UDim2.fromOffset(screenWidth / 2, screenHeight / 2)
	h.Visible = false
	h.Parent = gui
	self._horizontal = h

	local v = Instance.new("Frame")
	v.BackgroundColor3 = color
	v.BorderSizePixel = 0
	v.AnchorPoint = Vector2.new(0.5, 0.5)
	v.Position = UDim2.fromOffset(screenWidth / 2, screenHeight / 2)
	v.Visible = false
	v.Parent = gui
	self._vertical = v
end

function CrossWipeEffect:Prepare(_origin: string) end

function CrossWipeEffect:Update(progress: number, direction: string)
	local t = if direction == "In" then progress else 1 - progress
	local w = math.floor(self._screenWidth * t)
	local h = math.floor(self._screenHeight * t)
	self._horizontal.Size = UDim2.fromOffset(self._screenWidth + 4, h)
	self._vertical.Size = UDim2.fromOffset(w, self._screenHeight + 4)
	local visible = t > 0.01
	self._horizontal.Visible = visible
	self._vertical.Visible = visible
end

function CrossWipeEffect:Show()
	self._horizontal.Size = UDim2.fromOffset(self._screenWidth + 4, self._screenHeight)
	self._vertical.Size = UDim2.fromOffset(self._screenWidth, self._screenHeight + 4)
	self._horizontal.Visible = true
	self._vertical.Visible = true
end

function CrossWipeEffect:Hide()
	self._horizontal.Visible = false
	self._vertical.Visible = false
end

function CrossWipeEffect:Destroy()
	self._horizontal:Destroy()
	self._vertical:Destroy()
end

-- ── TransitionManager ──────────────────────────────────────────

local EFFECT_FACTORIES = {
	Fade = function()
		return FadeEffect.new()
	end,
	Iris = function()
		return ShapeEffect.new("iris")
	end,
	Diamond = function()
		return ShapeEffect.new("diamond")
	end,
	Box = function()
		return ShapeEffect.new("box")
	end,
	LinearWipe = function()
		return LinearWipeEffect.new()
	end,
	Split = function()
		return SplitEffect.new()
	end,
	CrossWipe = function()
		return CrossWipeEffect.new()
	end,
	Hexagon = function()
		return GridEffect.new(GRID_CONFIGS.HEXAGON)
	end,
	Triangle = function()
		return GridEffect.new(GRID_CONFIGS.TRIANGLE)
	end,
	Tiles = function()
		return GridEffect.new(GRID_CONFIGS.TILES)
	end,
	PolkaDots = function()
		return GridEffect.new(GRID_CONFIGS.POLKA_DOTS)
	end,
	Blinds = function()
		return GridEffect.new(GRID_CONFIGS.BLINDS)
	end,
	Checkerboard = function()
		return GridEffect.new(GRID_CONFIGS.CHECKERBOARD)
	end,
	RandomTiles = function()
		return GridEffect.new(GRID_CONFIGS.RANDOM_TILES)
	end,
}

local TransitionType = table.freeze({
	Fade = "Fade",
	Iris = "Iris",
	Diamond = "Diamond",
	Box = "Box",
	LinearWipe = "LinearWipe",
	Split = "Split",
	CrossWipe = "CrossWipe",
	Hexagon = "Hexagon",
	Triangle = "Triangle",
	Tiles = "Tiles",
	PolkaDots = "PolkaDots",
	Blinds = "Blinds",
	Checkerboard = "Checkerboard",
	RandomTiles = "RandomTiles",
})

local TransitionDirection = table.freeze({
	In = "In",
	Out = "Out",
})

local TransitionWaveOrigin = table.freeze({
	Center = "Center",
	TopLeft = "TopLeft",
	BottomRight = "BottomRight",
})

local nextId = 0

local TransitionManager = {}
TransitionManager.__index = TransitionManager

function TransitionManager.new(playerGui: PlayerGui, options: { displayOrder: number?, color: Color3? }?)
	nextId += 1

	local self = setmetatable({
		_color = (options and options.color) or DEFAULT_COLOR,
		_gui = nil :: ScreenGui?,
		_effects = {} :: { [string]: any },
		_activeEffect = nil :: any,
		_playing = false,
		_destroyed = false,
		_elapsed = 0,
		_duration = 0,
		_direction = "In",
		_renderStepName = RENDER_STEP_NAME .. "_" .. tostring(nextId),
	}, TransitionManager)

	local gui = Instance.new("ScreenGui")
	gui.Name = "TransitionOverlay"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = (options and options.displayOrder) or 99
	gui.Enabled = false
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	self._gui = gui

	RunService:BindToRenderStep(self._renderStepName, Enum.RenderPriority.Camera.Value + 1, function(dt)
		self:_onRender(dt)
	end)

	return self
end

function TransitionManager:IsPlaying(): boolean
	return self._playing
end

function TransitionManager:Play(direction: string, duration: number, origin: string?, effectType: string?)
	if self._destroyed then
		error("TransitionManager has been destroyed")
	end

	if self._playing then
		self._playing = false
		if self._activeEffect then
			self._activeEffect:Hide()
		end
	end

	local effect = self:_getOrCreateEffect(effectType or "Hexagon")
	self._activeEffect = effect
	self._gui.Enabled = true

	effect:Prepare(origin or "Center")
	self._elapsed = 0
	self._duration = duration
	self._direction = direction
	self._playing = true

	repeat
		task.wait()
	until not self._playing
end

function TransitionManager:PlayInOut(
	duration: number,
	onMidpoint: (() -> ())?,
	origin: string?,
	effectType: string?,
	holdTime: number?
)
	local o = origin or "Center"
	local e = effectType or "Hexagon"
	self:Play("In", duration / 2, o, e)
	if onMidpoint then
		onMidpoint()
	end
	if holdTime and holdTime > 0 then
		task.wait(holdTime)
	end
	self:Play("Out", duration / 2, o, e)
end

function TransitionManager:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	RunService:UnbindFromRenderStep(self._renderStepName)
	for _, effect in self._effects do
		effect:Destroy()
	end
	self._effects = {}
	self._gui:Destroy()
end

function TransitionManager:_onRender(dt: number)
	if not self._playing or not self._activeEffect then
		return
	end

	self._elapsed += dt
	local rawProgress = math.clamp(self._elapsed / self._duration, 0, 1)
	local progress = easeInOutSine(rawProgress)

	self._activeEffect:Update(progress, self._direction)

	if rawProgress < 1 then
		return
	end

	self._playing = false

	if self._direction == "Out" then
		self._activeEffect:Hide()
		self._gui.Enabled = false
	end
end

function TransitionManager:_getScreenSize(): (number, number)
	local wasEnabled = self._gui.Enabled
	if not wasEnabled then
		self._gui.Enabled = true
		task.wait()
	end
	local sw = self._gui.AbsoluteSize.X
	local sh = self._gui.AbsoluteSize.Y
	if not wasEnabled then
		self._gui.Enabled = false
	end
	if sw <= 0 or sh <= 0 then
		return DEFAULT_SCREEN_WIDTH, DEFAULT_SCREEN_HEIGHT
	end
	return sw, sh
end

function TransitionManager:_getOrCreateEffect(effectType: string)
	local effect = self._effects[effectType]
	if effect then
		return effect
	end

	local factory = EFFECT_FACTORIES[effectType]
	if not factory then
		error("Unknown transition type: " .. effectType)
	end

	effect = factory()
	local sw, sh = self:_getScreenSize()
	effect:Build(self._gui, sw, sh, self._color)
	self._effects[effectType] = effect
	return effect
end

return table.freeze({
	TransitionManager = TransitionManager,
	TransitionType = TransitionType,
	TransitionDirection = TransitionDirection,
	TransitionWaveOrigin = TransitionWaveOrigin,
})
