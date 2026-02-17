--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)

-- state-machine.luau
-- a refurbished state-machine.luau
-- is still superseded by observer.luau

-- offers better functionality for "states" and stepping.

local module = {}
module.__index = module

type StateMachine = setmetatable<{
	current_state: any,
	Changed: SignalPlus.Signal<any, any>,
	registered_states: { any },
}, typeof(module)>

function module.new(): StateMachine
	local self = setmetatable({}, module)

	self.current_state = nil
	self.Changed = SignalPlus()
	self.registered_states = {}

	return self
end

function module.Set(self: StateMachine, state: any)
	local old_state = self.current_state

	self.current_state = state

	self.Changed:Fire(self.current_state, old_state)
end

function module.Step(self: StateMachine)
	local i = table.find(self.registered_states, self.current_state)

	if not i then
		return
	end

	local old_state = self.current_state

	local new_state = self.registered_states[i + 1]

	if new_state then
		self.current_state = new_state
	else
		self.current_state = self.registered_states[1]
	end

	self.Changed:Fire(self.current_state, old_state)
end

function module.Get(self: StateMachine)
	return self.current_state
end

function module.RegisterState(self: StateMachine, state: any)
	table.insert(self.registered_states, state)
end

return module
