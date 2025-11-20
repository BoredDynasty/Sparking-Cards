--!strict

--- @class PlayerState
-- Manages the player's current state (e.g., Idle, Moving, Attacking).
-- Allows for multiple states to be active at once.
-- @server
-- @client
local PlayerState = {}
PlayerState.__index = PlayerState

export type State = {
	Name: string,
	Enter: () -> (),
	Exit: () -> (),
	Exclusive: {string}?, -- list of state names this state is exclusive with
}

export type self = {
	state_definitions: { [string]: State },
	active_states: { [string]: State },
}

--- Creates a new PlayerState manager.
-- @return PlayerState The new PlayerState manager.
function PlayerState.new(): self
	local self = setmetatable({}, PlayerState)
	self.state_definitions = {}
	self.active_states = {}
	return self
end

--- Adds a new state definition to the manager.
-- @param state State The state module.
function PlayerState:addStateDefinition(state: State)
	self.state_definitions[state.Name] = state
end

--- Enters a new state. If the state is exclusive with any active states,
-- those states will be exited first.
-- @param name string The name of the state to enter.
function PlayerState:enterState(name: string)
	if self.active_states[name] then
		return -- already in this state
	end

	local state_definition = self.state_definitions[name]
	if not state_definition then
		warn("Attempted to enter unregistered state: " .. name)
		return
	end

    -- Handle mutual exclusivity
	if state_definition.Exclusive then
		for _, exclusive_state_name in ipairs(state_definition.Exclusive) do
			if self.active_states[exclusive_state_name] then
				self:exitState(exclusive_state_name)
			end
		end
	end

    -- Also check if any active state is exclusive with this new one
    for active_state_name, _ in pairs(self.active_states) do
        local active_state_definition = self.state_definitions[active_state_name]
        if active_state_definition.Exclusive and table.find(active_state_definition.Exclusive, name) then
            self:exitState(active_state_name)
        end
    end

	self.active_states[name] = state_definition
	if state_definition.Enter then
		state_definition:Enter()
	end
end

--- Exits a state.
-- @param name string The name of the state to exit.
function PlayerState:exitState(name: string)
	local state = self.active_states[name]
	if not state then
		return
	end

	self.active_states[name] = nil
	if state.Exit then
		state:Exit()
	end
end

--- Checks if a state is currently active.
-- @param name string The name of the state to check for.
-- @return boolean Whether the state is active.
function PlayerState:hasState(name: string): boolean
	return self.active_states[name] ~= nil
end

--- Gets all active states.
-- @return {[string]: State} A dictionary of active states.
function PlayerState:getActiveStates(): { [string]: State }
	return self.active_states
end

return PlayerState
