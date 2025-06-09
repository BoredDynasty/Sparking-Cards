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
	onEnter: ((any) -> ())?,
	onExit: ((any) -> ())?,
	transitions: { [string]: string },
}

export type StateMachineType = {
	currentState: string,
	states: { [string]: State },
	new: (states: { [string]: State }, initialState: string) -> StateMachineType,
	transition: (self: StateMachineType, event: string) -> boolean,
	getCurrentState: (self: StateMachineType) -> string,
}

StateMachine.dataTypes = { stateMachine = typeof(StateMachine) }

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

function StateMachine:transition(event: string, ...: any?): boolean
	local currentState = self.states[self.currentState]
	local nextStateName = currentState.transitions[event]

	if not nextStateName then
		return false -- Transition not found
	end

	local nextState = self.states[nextStateName]
	if not nextState then
		return false -- Next state doesn't exist
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

function StateMachine:getCurrentState(): string
	return self.currentState
end

return StateMachine
