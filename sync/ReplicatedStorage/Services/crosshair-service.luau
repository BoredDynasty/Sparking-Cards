--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local input = require(ReplicatedStorage.Packages.input)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local spr = require(ReplicatedStorage.Modules.spr)

-- crosshair-service.luau

local crosshair_module = {}
crosshair_module.__index = crosshair_module

export type crosshair_interface<T> = ScreenGui & {
	Crosshair: Frame & {
		T: Frame | ImageLabel,
		Hitmarker: ImageLabel,
	},
}

type crosshair_lines = "Bottom" | "Center" | "Left" | "Right" | "Top"

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

-- TODO) make the actual crosshair ui

--[[
   Creates a new cross-hair

   @param radius `number`
]]
function crosshair_module.new(radius: number?)
	local self = setmetatable({
		interface = nil :: crosshair_interface<crosshair_lines>?,
		enabled = observer.new(false),
		radius = observer.new(radius or 50),
		frozen = observer.new(false),
		can_animate = observer.new(true),
		render_priority = Enum.RenderPriority.Camera.Value,
		mouse = input.Mouse.new(),
		render_tag = "crosshair-update",
	}, crosshair_module)

	self.line_positions = {
		Top = UDim2.new(0, 0, 0, -self.radius:Get() - 7),
		Left = UDim2.new(0, -self.radius:Get() - 7, 0, 0),
		Right = UDim2.new(0, self.radius:Get(), 0, 0),
		Bottom = UDim2.new(0, 0, 0, self.radius:Get()),
	} :: { [crosshair_lines]: UDim2 }

	self:SetRadius(self.radius:Get())
end

function crosshair_module:_UpdateLinePositions()
	self.line_positions = {
		Top = UDim2.new(0, 0, 0, -self.radius:Get() :: number - 7),
		Left = UDim2.new(0, -self.radius:Get() :: number - 7, 0, 0),
		Right = UDim2.new(0, self.radius:Get() :: number, 0, 0),
		Bottom = UDim2.new(0, 0, 0, self.radius:Get() :: number),
	} :: { [crosshair_lines]: UDim2 }
end

--[[
   Sets the distance between each crosshair line

   @param radii `number`
]]
function crosshair_module:SetRadius(radii: number)
	if typeof(radii) ~= "number" then
		warn("raddi is not a number")
	end

	self.radius:Set(radii)

	self:_UpdateLinePositions()

	for i, position in pairs(self.line_positions) do
		if self.can_animate:Get() then
			spr.target(self.interface[i], 0.7, 8, {
				Position = position,
			})
		else
			self.interface[i].Position = position
		end
	end
end

--[[
   Shoves the cross-hair

   ```luau
   local crosshair_module = require(path.to.crosshair_module)

   local mouse = input.Mouse.new()
   local crosshair = crosshair_module.new()

   mouse.LeftDown:Connect(function()
      crosshair:Shove()
   end
   ```

   @param radii `number`
]]
function crosshair_module:Shove(radii: number)
	if typeof(radii) ~= "number" then
		warn("raddi is not a number")
	end

	self.interface.Crosshair.Top.Position = UDim2.new(0, 0, 0, -radii - 7)
	self.interface.Crosshair.Left.Position = UDim2.new(0, -radii - 7, 0, 0)
	self.interface.Crosshair.Right.Position = UDim2.new(0, radii, 0, 0)
	self.interface.Crosshair.Bottom.Position = UDim2.new(0, 0, 0, radii)

	self.radius:Set(radii)

	self:_UpdateLinePositions()

	for i, position in pairs(self.line_positions) do
		if self.can_animate:Get() then
			spr.target(self.interface[i], 0.7, 8, {
				Position = position,
			})
		else
			self.interface[i].Position = position
		end
	end
end

function crosshair_module:Update()
	if self.frozen:Get() then
		-- is frozen
		return
	end
	local mouse_position = self.mouse:GetPosition() :: Vector2
	if not mouse_position then
		return
	end

	local position = UDim2.fromOffset(mouse_position.X, mouse_position.Y)

	self.interface.Crosshair.Position = position
end

function crosshair_module:Freeze()
	self.frozen:Set(true)
end

function crosshair_module:Thaw()
	self.frozen:Set(false)
end

function crosshair_module:Enable()
	self.enabled:Set(true)

	UserInputService.MouseIconEnabled = false
	self.interface.Enabled = true

	RunService:BindToRenderStep(self.render_tag, self.render_priority, function(delta: number)
		self:Update()
	end)
end

function crosshair_module:Disable()
	self.enabled:Set(false)

	UserInputService.MouseIconEnabled = true
	self.interface.Enabled = false

	RunService:UnbindFromRenderStep(self.render_tag)
end

function crosshair_module:Destroy()
	self:Disable()

	if self.interface then
		self.interface:Destroy()
		self.interface = nil
	end

	self.enabled:Destroy()
	self.can_animate:Destroy()
	self.radius:Destroy()
	self.frozen:Destroy()
	self.mouse:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

return crosshair_module
