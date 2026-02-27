--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local future = require(ReplicatedStorage.Packages.future)
local hydration = require(ReplicatedStorage.Utility.hydration)
local input = require(ReplicatedStorage.Packages.input)
local property = require(ReplicatedStorage.Utility.property)
local spr = require(ReplicatedStorage.Modules.spr)

-- ripple.luau

local mouse = input.Mouse.new()

local pool = PoolerPlus:CreatePool("RipplePool", function()
	local object = Instance.new("Frame")
	hydration(object) {
		Name = "Effect",
		Size = UDim2.fromScale(0, 0),
	}

	local ui_corner = Instance.new("UICorner")
	hydration(ui_corner) {
		CornerRadius = UDim.new(1, 0),
		Parent = object,
	}

	return object
end)

return function(object: GuiObject, duration: number?)
	object.ClipsDescendants = true

	if property.hasProperty(object, "AutoButtonColor") then
		object.AutoButtonColor = false
	end

	duration = duration or 0.5

	local mouse_position = mouse:GetPosition()

	local absolute_size = object.AbsoluteSize

	local x_scale = (-absolute_size.X + mouse_position.X) / absolute_size.X
	local y_scale = ((-absolute_size.Y + mouse_position.Y) / absolute_size.Y) - 3

	local ripple = pool:Get()
	ripple.Position = UDim2.fromScale(x_scale, y_scale)
	ripple.Size = UDim2.fromScale(0, 0)

	local max_size = math.max(absolute_size.X, absolute_size.Y) * 3

	ripple.Parent = object

	spr.target(ripple, 0.8, math.max(1 / duration, 6), {
		Size = UDim2.fromOffset(max_size, max_size),
		Transparency = 1,
	})

	spr.completed(ripple, function()
		task.wait(0.1)

		pool:Return(ripple)
	end)
end
