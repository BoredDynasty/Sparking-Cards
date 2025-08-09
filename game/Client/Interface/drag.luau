--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

local drag = {}
drag.__index = drag

type self = {
	_statemachines: { typeof(statemachine.new()) },
	_states: { [string]: statemachine.State },
	_initialState: string,
	_dragged: SignalPlus.Signal<direction, Vector3>,
	_cancelDragging: SignalPlus.Signal<>,
	_connections: { RBXScriptConnection },
	new: () -> drag,
	affix: (self: self, { GuiObject }) -> (),
}

export type direction = "up" | "down" | "left" | "right"

export type drag = typeof(setmetatable({} :: self, drag))

function drag.new(): drag
	return setmetatable({
		_statemachines = {},
		_states = {
			onDragging = {
				name = "Dragging",
				transitions = {
					cancelDragging = "cancelDragging",
				},
			},
			cancelDragging = {
				name = "cancelDragging",
				transitions = {
					onDragging = "onDragging",
				},
			},
		},
		_initialState = "cancelDragging",
		_dragged = SignalPlus(),
		_cancelDragging = SignalPlus(),
		_connections = {},
	}, drag)
end

function drag:affix(self: self, objects: { GuiObject })
	local dragInput = nil
	local dragStart: Vector3 = Vector3.new()
	local startPosition = UDim2.new() -- Changed from UDim to UDim2

	local function update(input: InputObject, object: GuiObject)
		local delta = input.Position - dragStart
		local dragTime = 0.04
		local smoothDrag = {
			Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			),
		}
		TweenPlus(object, smoothDrag, {
			Time = dragTime,
			EasingStyle = "Sine",
			EasingDirection = "InOut",
		}):Start()
	end

	for _, object in ipairs(objects) do
		local machine = statemachine.new(self._states, self._initialState)
		table.insert(self._statemachines, machine)

		local connections = {}

		table.insert(
			connections,
			object.InputBegan:Connect(function(input: InputObject)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					machine:transition("onDragging")
					dragStart = input.Position
					startPosition = object.Position

					local direction: direction? = nil
					if input.Position.X < object.AbsolutePosition.X then
						direction = "left"
					elseif input.Position.X > object.AbsolutePosition.X + object.AbsoluteSize.X then
						direction = "right"
					elseif input.Position.Y < object.AbsolutePosition.Y then
						direction = "up"
					elseif input.Position.Y > object.AbsolutePosition.Y + object.AbsoluteSize.Y then
						direction = "down"
					end
					assert(direction, "Direction must be defined: " .. tostring(input.Position))
					self._dragged:Fire(direction, dragStart)
				end
			end)
		)

		table.insert(
			connections,
			object.InputChanged:Connect(function(input: InputObject)
				if
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragInput = input
				end
			end)
		)

		table.insert(
			connections,
			UserInputService.InputChanged:Connect(function(input: InputObject)
				if input == dragInput and machine:getCurrentState() == "onDragging" and object.Parent then -- Better existence check
					update(input, object)
				end
			end)
		)

		-- Store connections for cleanup
		for _, connection in ipairs(connections) do
			table.insert(self._connections, connection)
		end
	end
end

function drag:destroy()
	-- Cleanup connections
	for _, connection: RBXScriptConnection in ipairs(self._connections :: { RBXScriptConnection }) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	-- Cleanup signals
	self._dragged:Destroy()
	self._cancelDragging:Destroy()

	-- Clear state machines
	table.clear(self._statemachines)
end

return drag
