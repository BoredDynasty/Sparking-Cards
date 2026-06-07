--!strict

-- drag.luau
-- Drag detector for GuiObjects that fires a signal for every pixel moved.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)

local module = {}

export type DragDetector = setmetatable<self, typeof(module)>

type self = {
	_gui: GuiObject,
	_isDragging: boolean,
	_lastPos: Vector2?,
	_remainder: Vector2,
	_connections: { RBXScriptConnection },
	OnDrag: SignalPlus.Signal<Vector2, Vector2>,
	OnDragStart: SignalPlus.Signal<Vector2>,
	OnDragEnd: SignalPlus.Signal<Vector2>,
	new: (guiObject: GuiObject) -> DragDetector,
	Destroy: (self: self) -> (),
	_setupInputHandlers: (self: self) -> (),
}

function module.new(guiObject: GuiObject): self
	local self = setmetatable({} :: self, module)

	self._gui = guiObject
	self._isDragging = false
	self._lastPos = nil
	self._remainder = Vector2.new(0, 0)
	self._connections = {}

	self.OnDrag = SignalPlus() :: SignalPlus.Signal<Vector2, Vector2>
	self.OnDragStart = SignalPlus() :: SignalPlus.Signal<Vector2>
	self.OnDragEnd = SignalPlus() :: SignalPlus.Signal<Vector2>

	self:_setupInputHandlers()

	return self
end

function module:_setupInputHandlers(self: self)
	-- Begin dragging on touch or left-click
	table.insert(
		self._connections,
		self._gui.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				self._isDragging = true
				self._lastPos = input.Position
				self._remainder = Vector2.new(0, 0)
				self.OnDragStart:Fire(self._lastPos)
			end
		end)
	)

	-- Track movement while dragging
	table.insert(
		self._connections,
		self._gui.InputChanged:Connect(function(input: InputObject)
			local isValid = self._isDragging
				and (
					input.UserInputType == Enum.UserInputType.Touch
					or input.UserInputType == Enum.UserInputType.MouseMovement
				)
			if not isValid then
				return
			end

			if self._lastPos then
				local currentPos: Vector2 = input.Position
				local delta: Vector2 = currentPos - self._lastPos

				-- Accumulate sub-pixel movement so we fire for each whole pixel moved
				self._remainder = self._remainder + delta
				local stepX = math.floor(self._remainder.X)
				local stepY = math.floor(self._remainder.Y)

				if stepX ~= 0 or stepY ~= 0 then
					local step = Vector2.new(stepX, stepY)
					self._remainder = self._remainder - step
					self.OnDrag:Fire(step, currentPos)
				end

				self._lastPos = currentPos
			end
		end)
	)

	-- End dragging when touch or mouse button is released
	table.insert(
		self._connections,
		self._gui.InputEnded:Connect(function(input: InputObject)
			local isValid = input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			if isValid and self._isDragging then
				self._isDragging = false
				self.OnDragEnd:Fire(input.Position)
				self._lastPos = nil
				self._remainder = Vector2.new(0, 0)
			end
		end)
	)
end

function module:Destroy(self: self)
	for _, connection in self._connections do
		connection:Disconnect()
	end
	self._connections = {}

	self.OnDrag:Destroy()
	self.OnDragStart:Destroy()
	self.OnDragEnd:Destroy()

	setmetatable(self, nil)
	self = nil
end

return module
