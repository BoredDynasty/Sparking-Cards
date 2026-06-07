--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local hydration = require(ReplicatedStorage.Utility.hydration)
local input = require(ReplicatedStorage.Packages.input)
local property = require(ReplicatedStorage.Utility.property)

-- ripple.luau

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

	duration = duration or 0.8

	local mouse_location = UserInputService:GetMouseLocation()

	local mouse_position = Vector2.new(
		mouse_location.X - object.AbsolutePosition.X,
		mouse_location.Y - object.AbsolutePosition.Y
	)

	local absolute_size = object.AbsoluteSize

	local x_scale = (-absolute_size.X + mouse_position.X) / absolute_size.X
	local y_scale = ((-absolute_size.Y + mouse_position.Y) / absolute_size.Y) - 3

	local ripple = pool:Get()
	ripple.Position = UDim2.fromScale(x_scale, y_scale)
	ripple.Size = UDim2.fromScale(0, 0)
	ripple.BackgroundTransparency = 0

	local max_size = math.max(absolute_size.X, absolute_size.Y) * 3

	ripple.Parent = object

	local t_info = TweenInfo.new(duration, Enum.EasingStyle.Linear)

	local tween = TweenService:Create(ripple, t_info, {
		Size = UDim2.fromOffset(max_size, max_size),
		BackgroundTransparency = 1,
	})
	tween:Play()

	tween.Completed:Connect(function()
		pool:Return(ripple)
	end)
end
