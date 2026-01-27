--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local random = require(ReplicatedStorage.Utility.random)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- sparkle.luau

local sparkle = {
	_trove = trove.new(),
	connection = nil,
}

sparkle.default = {
	texture = "rbxassetid://7112305588",
	lifetime = 2.5,
	rate = 0.5,
	minimumSize = UDim2.new(),
	maximumSize = UDim2.fromScale(25, 25),
	easing = "Quad",
	rotation = false,
	maxPerGui = 6,
}

export type config = typeof(sparkle.default)

sparkle.activeEmitters = {}
sparkle.pool = {} :: { ImageLabel }
sparkle.sparkleCount = {}
sparkle.lastSpawnTimes = {}

local function getSparkle(): ImageLabel
	local spark = table.remove(sparkle.pool)

	if spark then
		spark.Visible = true
	else
		spark = Instance.new("ImageLabel")
		spark.BackgroundTransparency = 1
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
	end

	return spark
end

local function cleanupSparkle(spark: ImageLabel)
	spark.Visible = false
	spark.Parent = nil

	table.insert(sparkle.pool, spark)
end

local function createSparkle(ancestor: GuiObject, config: config)
	if sparkle.sparkleCount[ancestor] >= config.maxPerGui then
		return
	end

	local spark = getSparkle()
	spark.Image = config.texture
	spark.Size = config.maximumSize

	if config.rotation then
		spark.Rotation = random.integer(0, 360)
	end

	local abs_size = ancestor.AbsoluteSize
	local x = random.integer() * abs_size.X
	local y = random.integer() * abs_size.Y

	spark.Position = UDim2.fromScale(x, y)
	spark.Parent = ancestor

	spr.target(spark, 1, 1 / config.lifetime, {
		Size = config.maximumSize,
	})

	spr.completed(spark, function()
		spr.target(spark, 1, 1 / config.lifetime, {
			Size = config.minimumSize,
		})
	end)

	spr.completed(spark, function()
		cleanupSparkle(spark)
		sparkle.sparkleCount[ancestor] -= 1
	end)
end

function sparkle._update()
	local current_time = time()

	for ancestor, config in sparkle.activeEmitters do
		if ancestor then
			sparkle.activeEmitters[ancestor] = nil
			sparkle.sparkleCount[ancestor] = nil
			sparkle.lastSpawnTimes[ancestor] = nil
			continue
		end

		local lastSpawnTime = sparkle.lastSpawnTimes[ancestor] or 0
		local interval = (1 / config.rate) * random.integer() * 0.1

		if current_time - lastSpawnTime >= interval then
			createSparkle(ancestor, config)
			sparkle.lastSpawnTimes[ancestor] = current_time
		end
	end

	if next(sparkle.activeEmitters) == nil and sparkle.connection then
		sparkle._trove:Remove(sparkle.connection)
		sparkle.connection = nil
	end
end

--[[
	Type def.
	```luau
	texture = "rbxassetid://7112305588",
	lifetime = 2.5,
	rate = 0.5,
	minimumSize = UDim2.new(),
	maximumSize = UDim2.fromScale(25, 25),
	easing = "Quad",
	rotation = false,
	maxPerGui = 6,
	```
]]
function sparkle:on(ancestor: GuiObject, config: config?)
	if sparkle.activeEmitters[ancestor] then
		return
	end

	config = config or {}

	for key, value in sparkle.default do
		if not config[key] then
			config[key] = value
		end
	end

	sparkle.activeEmitters[ancestor] = config
	sparkle.sparkleCount[ancestor] = 0
	sparkle.lastSpawnTimes[ancestor] = 0

	sparkle._trove:Connect(ancestor.Destroying, function()
		sparkle.activeEmitters[ancestor] = nil
		sparkle.sparkleCount[ancestor] = nil
		sparkle.lastSpawnTimes[ancestor] = nil
	end)

	sparkle.connection = RunService.PreRender:Connect(sparkle._update)

	sparkle._trove:Add(sparkle.connection)
end

function sparkle:off(ancestor: GuiObject)
	sparkle.activeEmitters[ancestor] = nil
	sparkle.sparkleCount[ancestor] = nil
	sparkle.lastSpawnTimes[ancestor] = nil
end

return sparkle
