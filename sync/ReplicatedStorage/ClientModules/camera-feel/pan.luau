--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local input = require(ReplicatedStorage.Packages.input)
local observer = require(ReplicatedStorage.Utility.observer)

export type CameraPan = {
	-- Create a new instance
	new: (any) -> CameraPan,

	-- Methods
	SetCanvasOrigin: (self: CameraPan, UDim2) -> (),
	GetPosition: (self: CameraPan) -> UDim2,
	Start: (self: CameraPan) -> (),
	Stop: (self: CameraPan) -> (),
	Destroy: (self: CameraPan) -> (),
}

local CameraPan = {}
CameraPan.__index = CameraPan

-- Constructor
function CameraPan.new(): CameraPan
	local self = setmetatable({}, CameraPan)

	-- observers and state (snake-case)
	self.panning = observer.new(false)
	self.pan_origin = observer.new(Vector2.zero) -- starting mouse position when panning starts
	self.canvas_origin = observer.new(UDim2.new()) -- UI canvas origin at pan start
	self.position = observer.new(UDim2.new())

	-- mouse and connections
	self._mouse = input.Mouse.new()
	self._connections = {} :: { RBXScriptConnection }

	-- connect events
	table.insert(
		self._connections,
		(self._mouse.LeftDown :: RBXScriptSignal<boolean>):Connect(function()
			self.panning:Set(true)
			-- capture the starting mouse position when panning begins
			local current_mouse_pos = self._mouse:GetPosition() :: Vector2
			self.pan_origin:Set(current_mouse_pos)
		end)
	)

	table.insert(
		self._connections,
		(self._mouse.LeftUp :: RBXScriptSignal<boolean>):Connect(function()
			self.panning:Set(false)
		end)
	)

	table.insert(
		self._connections,
		(self._mouse.Moved :: RBXScriptSignal<Vector2, boolean>):Connect(function()
			if not self.panning:Get() then
				return
			end

			-- Compute delta from start and apply to canvas_origin to produce new position
			local current_mouse_pos = self._mouse:GetPosition() :: Vector2
			local origin_mouse_pos = self.pan_origin:Get() :: Vector2
			local delta = current_mouse_pos - origin_mouse_pos

			local canvas_udim = self.canvas_origin:Get() :: UDim2
			self.position:Set(canvas_udim + UDim2.fromOffset(delta.X, delta.Y))
		end)
	)

	return (self :: any) :: CameraPan
end

-- Set the canvas (UI) origin used as base for panning. Accepts UDim2.
function CameraPan:SetCanvasOrigin(canvas_udim: UDim2)
	self.canvas_origin:Set(canvas_udim)
end

function CameraPan:GetPosition(): UDim2
	return self.position:Get()
end

-- Enable panning (if it was disabled)
function CameraPan:Start()
	self.panning:Set(false)
end

-- Disable panning (stops tracking even if mouse is down)
function CameraPan:Stop()
	self.panning:Set(false)
end

-- Disconnect all connections and cleanup
function CameraPan:Destroy()
	for i, conn in ipairs(self._connections :: { RBXScriptConnection }) do
		if conn then
			conn:Disconnect()
		end
	end
	self._connections = {}
end

return CameraPan
