--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

-- states.luau

-- Define state names as constants for easier reference and to avoid typos
local STATE_IDLE = "Idle"
local STATE_ATTACKING = "Attacking"
local STATE_BLOCKING = "Blocking"
local STATE_STUNNED = "Stunned"
local STATE_DEFUNCT = "Defunct" -- Renamed from Defeated to avoid conflict if 'Defeated' is an event name
local STATE_CHANNELING = "Channeling"
-- Add more states as needed, e.g., Dashing, Dodging, Climbing

local function newStateMachine(player: playerMarshaller.player)
	local states: { [string]: statemachine.State } = {
		[STATE_IDLE] = {
			name = STATE_IDLE,
			onEnter = function(params: { [string]: any }?)
				-- print(player.Name .. " entered Idle state")
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- Example: Reset walkspeed if it was modified by other states
					-- humanoid.WalkSpeed = 16
				end
			end,
			onExit = function(params: { [string]: any }?)
				-- print(player.Name .. " exited Idle state")
			end,
			transitions = {
				-- Event name leading to state name
				start_attack = STATE_ATTACKING,
				start_block = STATE_BLOCKING,
				got_stunned = STATE_STUNNED,
				died = STATE_DEFUNCT,
				start_channel = STATE_CHANNELING,
			},
		},
		[STATE_ATTACKING] = {
			name = STATE_ATTACKING,
			onEnter = function(params: { attackName: string, duration: number }?)
				-- print(player.Name .. " entered Attacking state with params:", params)
				-- Potentially slow player, prevent jumping, etc.
			end,
			onExit = function()
				-- print(player.Name .. " exited Attacking state")
			end,
			transitions = {
				finish_attack = STATE_IDLE,
				got_stunned = STATE_STUNNED, -- Can be interrupted
				died = STATE_DEFUNCT,
				-- Add transitions for combo breaks or specific attack interruptions
			},
		},
		[STATE_BLOCKING] = {
			name = STATE_BLOCKING,
			onEnter = function()
				-- print(player.Name .. " entered Blocking state")
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- humanoid.WalkSpeed = CombatStructure.Blocking.WalkSpeed or 8
				end
			end,
			onExit = function()
				-- print(player.Name .. " exited Blocking state")
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- humanoid.WalkSpeed = 16 -- Reset to default
				end
			end,
			transitions = {
				stop_block = STATE_IDLE,
				got_stunned = STATE_STUNNED, -- Block can be broken by heavy attacks leading to stun
				died = STATE_DEFUNCT,
				-- block_break_attack = STATE_STUNNED, (Example specific event)
			},
		},
		[STATE_STUNNED] = {
			name = STATE_STUNNED,
			onEnter = function(params: { duration: number }?)
				-- print(player.Name .. " entered Stunned state for duration:", params and params.duration)
				-- Stop animations, prevent movement/actions
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- humanoid.WalkSpeed = 0
				end
				if params and params.duration then
					task.delay(params.duration, function()
						-- Check if still stunned before transitioning, could have been overridden
						local sm = require(ReplicatedStorage.Combat.orion).GetPlayerState(player)
						if sm and sm:getCurrentState() == STATE_STUNNED then
							sm:transition("recover_from_stun")
						end
					end)
				end
			end,
			onExit = function()
				-- print(player.Name .. " exited Stunned state")
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- humanoid.WalkSpeed = 16 -- Reset to default
				end
			end,
			transitions = {
				recover_from_stun = STATE_IDLE,
				died = STATE_DEFUNCT,
			},
		},
		[STATE_DEFUNCT] = {
			name = STATE_DEFUNCT,
			onEnter = function()
				-- print(player.Name .. " entered Defunct state (died)")
				-- Handle ragdoll, drop items, etc.
			end,
			-- No onExit usually, player might respawn which would reset the state machine or create a new one
			transitions = {
				-- respawn = STATE_IDLE, -- Respawn logic would typically re-initialize the player's state machine
			},
		},
		[STATE_CHANNELING] = {
			name = STATE_CHANNELING,
			onEnter = function(params: { channel_duration: number, ability_name: string }?)
				-- print(player.Name .. " entered Channeling state for:", params and params.ability_name)
				-- Play channeling animation, VFX. Prevent most other actions.
			end,
			onExit = function()
				-- print(player.Name .. " exited Channeling state")
			end,
			transitions = {
				finish_channel_success = STATE_IDLE, -- Or directly into an attack state
				channel_interrupted_stun = STATE_STUNNED,
				channel_interrupted_cancel = STATE_IDLE,
				died = STATE_DEFUNCT,
			},
		},
	}

	-- The statemachine module itself handles calling onEnter for the initial state.
	return statemachine.new(states, STATE_IDLE)
end

return {
	new = newStateMachine,
	-- Export state names for external use if needed, e.g. orion.SetPlayerState(player, states.IDLE)
	IDLE = STATE_IDLE,
	ATTACKING = STATE_ATTACKING,
	BLOCKING = STATE_BLOCKING,
	STUNNED = STATE_STUNNED,
	DEFUNCT = STATE_DEFUNCT,
	CHANNELING = STATE_CHANNELING,
}
