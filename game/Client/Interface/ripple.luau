--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local future = require(ReplicatedStorage.Packages.future)
local input = require(ReplicatedStorage.Packages.input)
local promise = require(ReplicatedStorage.Packages.promise)
local spr = require(ReplicatedStorage.Modules.spr)

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
	return future.Try(function()
		if not ancestor.ClipsDescendants then
			ancestor.ClipsDescendants = true
		end

		duration = duration or 0.4

		local mouse_position = mouse:GetPosition()
		assert(mouse_position and mouse_position.X and mouse_position.Y, "Invalid mouse position")

		local mouse_x, mouse_y = mouse_position.X, mouse_position.Y
		assert(
			ancestor.AbsoluteSize and ancestor.AbsoluteSize.X and ancestor.AbsoluteSize.Y,
			"Invalid ancestor absolute size"
		)

		local abs_x, abs_y = ancestor.AbsoluteSize.X, ancestor.AbsoluteSize.Y

		local x_scale = (-abs_x + mouse_x) / abs_x
		local y_scale = ((-abs_y + mouse_y) / abs_y) - 3

		local effect = createRippleEffect(ancestor)
		effect.Position = UDim2.fromScale(x_scale, y_scale)

		local max_size = math.max(abs_x, abs_y) * 3

		spr.target(effect, 1, 1 / duration, {
			Size = UDim2.fromOffset(max_size, max_size),
		})
		spr.target(effect, 1, 1 / duration, {
			BackgroundTransparency = 1,
		})

		task.delay(duration, function()
			effect:Destroy()
		end)
	end)
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
	if not ancestor and not ancestor.Destroying then
		-- we're getting errors on ts
		return
	end

	local conn = nil

	future.Try(function()
		ancestor.Destroying:Connect(function()
			if conn then
				conn:Disconnect()
			end
		end)
	end)

	local abs_size = ancestor.AbsoluteSize
	local abs_position = ancestor.AbsolutePosition
	conn = (mouse.LeftDown :: RBXScriptSignal):Connect(function()
		local position = mouse:GetPosition()
		if not position then
			return
		end

		if not bounds.inner(abs_position, abs_size, position) then
			return
		end

		ripple(ancestor, duration)
	end)
end

return setmetatable({
	Watch = watch,
}, {
	__call = ripple,
})
