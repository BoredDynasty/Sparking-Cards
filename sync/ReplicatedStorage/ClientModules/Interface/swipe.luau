--!nonstrict

-- swipe.luau
-- a simple swipe detector for GUI objects in Roblox

local SwipeDetector = {}
SwipeDetector.__index = SwipeDetector

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)

export type SwipeDetector = { typeof(setmetatable({} :: self, SwipeDetector)) }

type self = {
	_gui: GuiObject,
	_threshold: number,
	_startPos: Vector3?,
	_connections: { RBXScriptConnection },
	OnSwipe: SignalPlus.Signal<direction, Vector3>,
	new: (guiObject: GuiObject) -> SwipeDetector,
	SetThreshold: (self: self, threshold: number) -> (),
	Destroy: (self: self) -> (),
	_setupInputHandlers: (self: self) -> (),
}

export type direction = "up" | "down" | "left" | "right" | "none"

-- Default settings
local DEFAULT_SWIPE_THRESHOLD = 10 -- Minimum distance in pixels to trigger a swipe

function SwipeDetector.new(guiObject: GuiObject): self
	local self = setmetatable({} :: self, SwipeDetector)

	self._gui = guiObject
	self._threshold = DEFAULT_SWIPE_THRESHOLD
	self._startPos = nil
	self._connections = {}
	self.OnSwipe = SignalPlus()

	-- Setup input handlers
	self:_setupInputHandlers(self)

	return self
end

function SwipeDetector:SetThreshold(self: self, threshold: number)
	self._threshold = threshold
end

function SwipeDetector:_setupInputHandlers(self: self)
	-- Touch/Mouse input start
	table.insert(
		self._connections,
		self._gui.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				self._startPos = input.Position
			end
		end)
	)

	-- Touch/Mouse input end
	table.insert(
		self._connections,
		self._gui.InputEnded:Connect(function(input: InputObject)
			local condition = input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			-- Check if swipe is valid
			if condition then
				if self._startPos then
					local endPos = input.Position
					local delta: Vector3 = endPos - self._startPos

					-- Check if movement exceeds threshold
					if delta.Magnitude >= self._threshold then
						-- Determine direction
						local direction: direction = "none"
						if math.abs(delta.X) > math.abs(delta.Y) then
							-- Horizontal swipe
							direction = delta.X > 0 and "right" or "left"
						else
							-- Vertical swipe
							direction = delta.Y > 0 and "down" or "up"
						end

						-- Fire the swipe signal
						self.OnSwipe:Fire(direction, delta)
					end
				end

				self._startPos = nil
			end
		end)
	)
end

function SwipeDetector:Destroy(self: self)
	-- Cleanup connections
	for _, connection in self._connections do
		connection:Disconnect()
	end
	self._connections = {}

	-- Cleanup signal
	self.OnSwipe:Destroy()

	setmetatable(self, nil) -- Remove metatable to prevent further access
	self = nil
end

return SwipeDetector
