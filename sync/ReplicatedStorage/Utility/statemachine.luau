--!nonstrict

--[[
    `statemachine.luau`

    a module for defining states, 
    transition between states,
    and handle state changes.
]]

local StateMachine = {}
StateMachine.__index = StateMachine

export type State = {
	name: string,
	onEnter: ((...any?) -> ())?,
	onExit: ((...any?) -> ())?,
	transitions: { [string]: string },
}

export type StateMachineType = {
	currentState: string,
	states: { [string]: State },
	new: (states: { [string]: State }, initialState: string) -> StateMachineType,
	transition: (self: StateMachineType, event: string, ...any?) -> boolean,
	getCurrentState: (self: StateMachineType) -> string,
	nextState: (self: StateMachineType, ...any?) -> (boolean, string), -- Added
	previousState: (self: StateMachineType, ...any?) -> (boolean, string), -- Added
}

--[[
   
]]

function StateMachine.new(states: { [string]: State }, initialState: string): StateMachineType
	local self = setmetatable({}, StateMachine)

	assert(states[initialState], "Initial state must exist in states table")

	self.states = states
	self.currentState = initialState

	-- Call onEnter for initial state
	if self.states[initialState].onEnter then
		self.states[initialState].onEnter()
	end

	return self
end

function StateMachine:transition(event: string, ...: any?): (boolean, string)
	local currentState = (self :: StateMachineType).states[self.currentState]
	local nextStateName = currentState.transitions[event]

	if not nextStateName then
		return false, "Transition not found" -- Transition not found
	end

	local nextState = self.states[nextStateName]
	if not nextState then
		return false, "Next state doesn't exist" -- Next state doesn't exist
	end

	-- Call exit function of current state
	if currentState.onExit then
		currentState.onExit(...)
	end

	-- Update current state
	self.currentState = nextStateName

	-- Call enter function of new state
	if nextState.onEnter then
		nextState.onEnter(...)
	end

	return true
end

function StateMachine:nextState(...: any?): (boolean, string)
	local states = {}
	for stateName in pairs(self.states :: StateMachineType) do
		table.insert(states, stateName)
	end
	table.sort(states) -- Ensure consistent ordering

	local currentIndex = table.find(states, self.currentState)
	if not currentIndex then
		return false, "Current state not found"
	end

	local nextIndex = currentIndex % #states + 1
	local nextStateName = states[nextIndex]

	-- Call exit function of current state
	local currentState = self.states[self.currentState] :: State
	if currentState.onExit then
		currentState.onExit(...)
	end

	-- Update current state
	self.currentState = nextStateName

	-- Call enter function of new state
	local nextState = self.states[nextStateName] :: State
	if nextState.onEnter then
		nextState.onEnter(...)
	end

	return true, nextStateName
end

function StateMachine:previousState(...: any?): (boolean, string)
	local states = {}
	for stateName in pairs(self.states :: StateMachineType) do
		table.insert(states, stateName)
	end
	table.sort(states) -- Ensure consistent ordering

	local currentIndex = table.find(states, self.currentState)
	if not currentIndex then
		return false, "Current state not found"
	end

	local prevIndex = (currentIndex - 2) % #states + 1
	local prevStateName = states[prevIndex]

	-- Call exit function of current state
	local currentState = self.states[self.currentState] :: State
	if currentState.onExit then
		currentState.onExit(...)
	end

	-- Update current state
	self.currentState = prevStateName

	-- Call enter function of new state
	local nextState = self.states[prevStateName] :: State
	if nextState.onEnter then
		nextState.onEnter(...)
	end

	return true, prevStateName
end

function StateMachine:getCurrentState(): string
	return self.currentState
end

return StateMachine
