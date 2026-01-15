--!nonstrict

-- parallax.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Spring = require(script.Parent.spring)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

export type Layer = {
	Instance: GuiObject?,
	DepthFactor: number,
	Spring: Spring.spring,
	Id: string,
}

local Parallax = {}
Parallax.__index = Parallax

export type ParallaxEffect = {
	Layers: { Layer },
	ScreenCenter: Vector2,
	MaxOffset: Vector2,
	MousePosition: Vector2,
	state: observer.Observer<boolean>,
	_trove: typeof(trove.new()),

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
		state = observer.new(false),
		_trove = trove.new(),
		_debug = false,
		_originalPositions = {},
		_viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(0, 0),
	}, Parallax)

	-- Initialize screen center
	local viewportSize = workspace.CurrentCamera.ViewportSize
	self.ScreenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

	return self
end

function Parallax:AddLayer(instance: GuiObject?, depthFactor: number, imageId: string?)
	-- Create springs for smooth movement
	local spring = Spring.new(
		Vector2.new(0, 0), -- initial position
		4, -- lower stiffness for smoother movement
		0.8, -- damping
		1 -- mass
	)

	table.insert(self.Layers, {
		Instance = instance or nil,
		DepthFactor = depthFactor,
		Spring = spring,
		Id = imageId or "", -- rbxasset yadayada
	})
end

function Parallax:Setup(holder: GuiObject)
	local num_layers = #self.Layers

	local folder = Instance.new("Folder")
	folder.Name = "ParallaxFolder"
	folder.Parent = holder

	for i, data in ipairs(self.Layers) do
		local layer = data.Instance
		local created = false
		if not layer or layer == nil then
			layer = Instance.new("ImageLabel")
			layer.Name = tostring(i)
			layer.AnchorPoint = Vector2.new(0.5, 0.5)
			layer.BackgroundTransparency = 1
			layer.Position = UDim2.fromScale(0.5, 0.5)
			layer.Size = UDim2.fromScale(1, 1)
			layer.Image = data.Id
			created = true
		end

		layer.ZIndex = i

		-- Preserve parent's UICorner styling if present
		local parent = layer.Parent
		if parent and parent:FindFirstChildOfClass("UICorner") then
			local corner = parent:FindFirstChildOfClass("UICorner")
			corner = corner:Clone()
			corner.Parent = layer
		end

		if created then
			layer.Parent = folder
		else
			-- ensure owned layers are inside folder for consistent positioning
			layer.Parent = folder
		end

		-- store original offsets for resetting
		self._originalPositions[i] = { X = layer.Position.X.Offset, Y = layer.Position.Y.Offset }

		-- update instance reference
		self.Layers[i].Instance = layer
	end

	return num_layers
end

function Parallax:Enable()
	if self.state:Get() then
		return
	end
	self.state:Set(true)

	-- Track mouse movement (only mouse movement events)
	local conn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			-- Input.Position is already a Vector2; assign directly to avoid allocation
			self.MousePosition = input.Position
		end
	end)

	self._trove:Add(conn)

	-- handle viewport size changes to keep ScreenCenter correct
	local cam = workspace.CurrentCamera
	local resizeConn
	if cam then
		resizeConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self._viewportSize = cam.ViewportSize
			self.ScreenCenter = Vector2.new(self._viewportSize.X * 0.5, self._viewportSize.Y * 0.5)
		end)
		self._trove:Add(resizeConn)
	end

	-- Pre-cache some locals for faster inner loop
	local maxOffset = self.MaxOffset

	local conn2 = RunService.RenderStepped:Connect(function(deltaTime: number)
		-- If disabled during frame, bail early
		if not self.state:Get() then
			return
		end

		debug.profilebegin("parallax-update")
		-- Compute normalized mouse offset once per frame
		local mp = self.MousePosition
		local screenCenter = self.ScreenCenter
		local denomX = (screenCenter.X ~= 0) and screenCenter.X or 1
		local denomY = (screenCenter.Y ~= 0) and screenCenter.Y or 1
		local mx = math.clamp((mp.X - screenCenter.X) / denomX, -1, 1)
		local my = math.clamp((mp.Y - screenCenter.Y) / denomY, -1, 1)

		-- cache layers length
		for i = 1, #self.Layers do
			local layer = self.Layers[i]
			local df = layer.DepthFactor
			local targetX = mx * maxOffset.X * df
			local targetY = my * maxOffset.Y * df

			-- cache spring and instance locally to reduce table lookups
			local spring = layer.Spring
			spring:SetTarget(spring, Vector2.new(targetX, targetY))
			spring:Update(spring, deltaTime)

			local pos = spring.Position
			-- Apply Position offsets in Offset (pixel) space for smoothness
			local inst = layer.Instance
			if inst then
				inst.Position = UDim2.new(inst.Position.X.Scale, pos.X, inst.Position.Y.Scale, pos.Y)
			end
		end

		-- Debug overlay update
		if self._debug then
			if self._debugLabel and self._debugLabel.Parent then
				self._debugLabel.Text = string.format("mx=%.2f my=%.2f", mx, my)
			end
		end

		debug.profileend()
	end)

	self._trove:Add(conn2)
end

function Parallax:Disable()
	self.state:Set(false)

	-- Disconnect all events but preserve for potential re-enable
	self._trove:Clean()

	-- Reset all layers to original position smoothly
	for i = 1, #self.Layers do
		local layer = self.Layers[i]
		if layer and layer.Instance then
			layer.Spring:Reset(layer.Spring)
			local orig = self._originalPositions[i]
			if orig then
				layer.Instance.Position = UDim2.new(
					layer.Instance.Position.X.Scale,
					orig.X or 0,
					layer.Instance.Position.Y.Scale,
					orig.Y or 0
				)
			else
				layer.Instance.Position =
					UDim2.new(layer.Instance.Position.X.Scale, 0, layer.Instance.Position.Y.Scale, 0)
			end
		end
	end
end

function Parallax:Destroy()
	self:Disable()

	-- Destroy trove and state
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end

	if self.state then
		self.state:Destroy()
		self.state = nil
	end

	-- Remove debug UI
	if self._debugLabel then
		self._debugLabel:Destroy()
		self._debugLabel = nil
	end

	table.clear(self.Layers)
	setmetatable(self, nil)
end

-- Toggle debug overlay; creates a small TextLabel inside the first layer's parent
function Parallax:ToggleDebug(enable: boolean)
	self._debug = enable and true or false
	if self._debug then
		if not self._debugLabel then
			local lbl = Instance.new("TextLabel")
			lbl.Name = "ParallaxDebug"
			lbl.Size = UDim2.new(0, 120, 0, 24)
			lbl.BackgroundTransparency = 0.5
			lbl.BackgroundColor3 = Color3.new(0, 0, 0)
			lbl.TextColor3 = Color3.new(1, 1, 1)
			lbl.TextScaled = true
			lbl.Font = Enum.Font.SourceSans
			lbl.AnchorPoint = Vector2.new(0, 0)
			lbl.Position = UDim2.new(0, 0, 0, 0)
			-- Parent to first layer's parent or to PlayerGui/Camera fallback
			local parent = nil
			if #self.Layers > 0 and self.Layers[1].Instance and self.Layers[1].Instance.Parent then
				parent = self.Layers[1].Instance.Parent
			else
				local playerGui = playerMarshaller.get().PlayerGui
				parent = playerGui
				if not parent and workspace.CurrentCamera then
					parent = workspace.CurrentCamera
				end
			end
			lbl.Parent = parent
			self._debugLabel = lbl
		end
	else
		if self._debugLabel then
			self._debugLabel:Destroy()
			self._debugLabel = nil
		end
	end
end

return Parallax
