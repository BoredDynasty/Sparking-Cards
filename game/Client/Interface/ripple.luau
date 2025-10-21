--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local input = require(ReplicatedStorage.Packages.input)

-- ripple.luau

local mouse = input.Mouse.new()

local function createRippleEffect(ancestor: GuiObject)
	local effect = Instance.new("Frame")
	effect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	effect.BackgroundTransparency = 0.5
	effect.BorderSizePixel = 0
	effect.ZIndex = ancestor.ZIndex + 1
	effect.AnchorPoint = Vector2.new(0.5, 0.5)
	effect.Size = UDim2.fromOffset(0, 0)
	effect.Name = "RippleEffect"
	effect.Parent = ancestor

	return effect
end

--[[
      @param ancestor: GuiObject
      @param duration: number?

      ```luau
      ripple(button, 0.35)
      ```

      @return void
]]
local function ripple(ancestor: GuiObject, duration: number?)
	if not ancestor.ClipsDescendants then
		ancestor.ClipsDescendants = true
	end

	duration = duration or 0.4

	local mouse_x, mouse_y = mouse:GetPosition().X, mouse:GetPosition().Y

	local abs_x, abs_y = ancestor.AbsoluteSize.X, ancestor.AbsoluteSize.Y

	local x_scale = (-abs_x + mouse_x) / abs_x
	local y_scale = ((-abs_y + mouse_y) / abs_y) - 3

	local effect = createRippleEffect(ancestor)
	effect.Position = UDim2.fromScale(x_scale, y_scale)

	local max_size = math.max(abs_x, abs_y) * 3

	local tween_1 = TweenPlus(effect, {
		Size = UDim2.fromOffset(max_size, max_size),
	}, {
		EasingDirection = "Out",
		EasingStyle = "Sine",
		Time = duration,
	})
	local tween_2 = TweenPlus(effect, {
		BackgroundTransparency = 1,
	}, {
		Time = duration,
	})
	tween_1:Start()
	tween_2:Start()

	tween_2.Completed:Wait()
	effect:Destroy()
end

--[[
      @param ancestor: GuiObject
      @param duration: number?

      ```luau
      ripple(button, 0.35)
      ```

      @return void
]]
local function watch(ancestor: GuiObject, duration: number?)
	local abs_size = ancestor.AbsoluteSize
	local abs_position = ancestor.AbsolutePosition
	local conn = (mouse.LeftDown :: RBXScriptSignal):Connect(function()
		local position = mouse:GetPosition()

		if not bounds.inner(abs_position, abs_size, position) then
			return
		end

		ripple(ancestor, duration)
	end)

	ancestor.Destroying:Once(function()
		conn:Disconnect()
	end)
end

local self = table.freeze(setmetatable({
	Watch = watch,
}, {
	__index = ripple,
	__call = ripple,
}))

return self
