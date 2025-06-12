--!nonstrict

-- parallax.luau

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Spring = require("./spring")

export type Layer = {
	Instance: GuiObject,
	DepthFactor: number,
	Spring: Spring.Spring,
}

local Parallax = {}
Parallax.__index = Parallax

export type ParallaxEffect = {
	Layers: { Layer },
	ScreenCenter: Vector2,
	MaxOffset: Vector2,
	MousePosition: Vector2,
	IsEnabled: boolean,

	-- Methods
	AddLayer: (self: ParallaxEffect, instance: GuiObject, depthFactor: number) -> (),
	Enable: (self: ParallaxEffect) -> (),
	Disable: (self: ParallaxEffect) -> (),
	Destroy: (self: ParallaxEffect) -> (),
}

--[[
   ```luau

   -- Example usage
   local Parallax = require(path.to.parallax)

   -- Create a new parallax effect with custom max offset
   local cardParallax = Parallax.new(Vector2.new(15, 15))

   -- Add layers with different depth factors
   -- Higher depth factor = more movement
   cardParallax:AddLayer(cardBackground, 0.2)  -- Background moves least
   cardParallax:AddLayer(cardMiddleground, 0.5)  -- Middle layer moves more
   cardParallax:AddLayer(cardForeground, 0.8)  -- Foreground moves most

   -- Enable the effect
   cardParallax:Enable()

   -- When you're done with the effect
   cardParallax:Disable()
   -- Or to completely clean up
   cardParallax:Destroy()

   -- To make cards feel more dynamic, you might want to use depth factors like:

   -- Card shadow: 0.1-0.2
   -- Card background: 0.3-0.4
   -- Card art/content: 0.5-0.6
   -- Card highlights/effects: 0.7-0.8

   -- CardFrame
   -- ├── Background
   -- ├── Artwork
   -- └── Foreground

   ```
]]
function Parallax.new(maxOffset: Vector2?)
	local self = setmetatable({
		Layers = {},
		ScreenCenter = Vector2.new(),
		MaxOffset = maxOffset or Vector2.new(20, 20),
		MousePosition = Vector2.new(),
		IsEnabled = false,
		_connections = {},
	}, Parallax)

	-- Initialize screen center
	local viewportSize = workspace.CurrentCamera.ViewportSize
	self.ScreenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

	return self
end

function Parallax.AddLayer(self: ParallaxEffect, instance: GuiObject, depthFactor: number)
	-- Create springs for smooth movement
	local spring = Spring.new(
		Vector2.new(0, 0), -- initial position
		4, -- lower stiffness for smoother movement
		0.8, -- damping
		1 -- mass
	)

	table.insert(self.Layers, {
		Instance = instance,
		DepthFactor = depthFactor,
		Spring = spring,
	})
end

function Parallax.Enable(self: ParallaxEffect)
	if self.IsEnabled then
		return
	end
	self.IsEnabled = true

	-- Track mouse movement
	table.insert(
		self._connections,
		UserInputService.InputChanged:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				self.MousePosition = Vector2.new(input.Position.X, input.Position.Y)
			end
		end)
	)

	-- Update parallax effect
	table.insert(
		self._connections,
		RunService.RenderStepped:Connect(function(deltaTime: number)
			local mouseOffset = self.MousePosition - self.ScreenCenter

			-- Normalize offset and apply max limits
			mouseOffset = Vector2.new(
				math.clamp(mouseOffset.X / self.ScreenCenter.X, -1, 1),
				math.clamp(mouseOffset.Y / self.ScreenCenter.Y, -1, 1)
			)

			-- Update each layer
			for _, layer in ipairs(self.Layers) do
				local targetOffset = Vector2.new(
					mouseOffset.X * self.MaxOffset.X * layer.DepthFactor,
					mouseOffset.Y * self.MaxOffset.Y * layer.DepthFactor
				)

				-- Update spring physics
				layer.Spring:SetTarget(layer.Spring, targetOffset)
				layer.Spring:Update(layer.Spring, deltaTime)

				-- Apply position with smooth interpolation
				local position = layer.Spring.Position
				layer.Instance.Position = UDim2.new(
					layer.Instance.Position.X.Scale,
					position.X,
					layer.Instance.Position.Y.Scale,
					position.Y
				)
			end
		end)
	)
end

function Parallax.Disable(self: ParallaxEffect)
	self.IsEnabled = false

	-- Disconnect all events
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	-- Reset all layers to original position
	for _, layer in ipairs(self.Layers) do
		layer.Spring:Reset(layer.Spring)
		layer.Instance.Position =
			UDim2.new(layer.Instance.Position.X.Scale, 0, layer.Instance.Position.Y.Scale, 0)
	end
end

function Parallax.Destroy(self: ParallaxEffect)
	self:Disable()
	table.clear(self.Layers)
	setmetatable(self, nil)
end

return Parallax
