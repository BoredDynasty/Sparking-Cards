--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local input = require(ReplicatedStorage.Packages.input)

-- hover.luau
-- recreate that Microsoft highlight effect when your
-- mouse hovers over a Gui element

local mouse = input.Mouse.new()

local function getCorner(position: Vector2, size: Vector2, anchor: Vector2)
	return position + (size * anchor)
end

--[[
      @param ancestor: GuiObject
      @param gradient: UIGradient

      ```luau

      hover(button, uiGradient)
      -- you have to call this every frame while hovering
      ```

      @return void
]]
local function hover(ancestor: GuiObject, gradient: UIGradient)
	local mouse_position = mouse:GetPosition()

	local centerPos = ancestor.AbsolutePosition + (ancestor.AbsoluteSize / 2)
	local dist = (mouse_position - centerPos).Magnitude

	-- avoid additional computation
	local threshold = math.max(ancestor.AbsoluteSize.X, ancestor.AbsoluteSize.Y) * 2
	if dist > threshold then
		return
	end

	local abs_x, abs_y = ancestor.AbsoluteSize.X, ancestor.AbsoluteSize.Y

	local corner = getCorner(ancestor.AbsoluteSize, ancestor.AbsolutePosition, ancestor.AnchorPoint)
	local center = corner + (ancestor.AbsoluteSize / 2)

	local position = mouse_position - center

	local circle = 360

	-- https://devforum.roblox.com/t/how-can-i-calculate-an-angle-on-the-screen-with-the-position-of-the-mouse/278096
	local angle = math.deg(math.atan2(position.X, position.Y))
	angle = angle < 0 and circle + angle or angle

	local offset = 90

	local distance = position.Magnitude

	gradient.Rotation = angle + offset

	local key_position = 0.25
	local KP1C = 1

	local minimum, maximum = 0, 0.5

	local mapped = math.clamp(
		minimum + (maximum - minimum) * (distance / (math.max(abs_x, abs_y) * 2)),
		minimum,
		maximum
	)
	key_position = maximum - mapped

	if key_position ~= 0 then
		KP1C = 1
	else
		KP1C = 0
	end

	local color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(KP1C, KP1C, KP1C)),
		ColorSequenceKeypoint.new(key_position, Color3.new()),
		ColorSequenceKeypoint.new(1, Color3.new()),
	})

	gradient.Color = color
end

-- we gotta do a bit of improvising
local watch: (ancestor: GuiObject, gradient: UIGradient) -> ()

local self = setmetatable({
	Watching = {} :: { [GuiObject]: UIGradient },
	Watch = watch,
}, {
	__call = hover,
})

watch = function(ancestor: GuiObject, gradient: UIGradient)
	self.Watching[ancestor] = gradient
	ancestor.Destroying:Connect(function()
		self.Watching[ancestor] = nil
	end)
end

(mouse.Moved :: RBXScriptSignal):Connect(function()
	for ancestor, gradient in pairs(self.Watching) do
		task.wait()
		hover(ancestor, gradient)
	end
end)

return self
