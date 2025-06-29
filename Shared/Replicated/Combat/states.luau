--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local StateMachineUtil = require(ReplicatedStorage.Utility.statemachine)

-- states.luau
-- Defines character combat states and their transitions.

-- Types for state parameters to improve type safety and clarity
type PlayerType = PlayerMarshaller.player -- More specific than 'Player' if playerMarshaller has custom fields

type IdleStateParams = {} -- No specific params for Idle onEnter/onExit currently
type AttackingStateParams = { attackName: string, duration: number }
type BlockingStateParams = {} -- No specific params for Blocking onEnter/onExit currently
type StunnedStateParams = { duration: number } -- Duration is now primarily for server logic to schedule recovery
type DefunctStateParams = {} -- No specific params for Defunct onEnter/onExit currently
type ChannelingStateParams = { channelDuration: number, abilityName: string }

-- Define state names as constants
local STATE_IDLE = "Idle"
local STATE_ATTACKING = "Attacking"
local STATE_BLOCKING = "Blocking"
local STATE_STUNNED = "Stunned"
local STATE_DEFUNCT = "Defunct"
local STATE_CHANNELING = "Channeling"

local function newStateMachine(player: PlayerType): StateMachineUtil.StateMachineType
	local states: { [string]: StateMachineUtil.State } = {
		[STATE_IDLE] = {
			name = STATE_IDLE,
			onEnter = function(params: IdleStateParams?)
				-- print(player.Name .. " entered Idle state")
				local char = player.Character
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- Example: humanoid.WalkSpeed = 16 -- Reset walkspeed
				end
			end,
			onExit = function(params: IdleStateParams?)
				-- print(player.Name .. " exited Idle state")
			end,
			transitions = {
				start_attack = STATE_ATTACKING,
				start_block = STATE_BLOCKING,
				got_stunned = STATE_STUNNED,
				died = STATE_DEFUNCT,
				start_channel = STATE_CHANNELING,
			},
		},
		[STATE_ATTACKING] = {
			name = STATE_ATTACKING,
			onEnter = function(params: AttackingStateParams?)
				-- print(player.Name .. " entered Attacking state with params:", params)
				-- Potentially slow player, prevent jumping, etc. based on params.attackName or params.duration
			end,
			onExit = function()
				-- print(player.Name .. " exited Attacking state")
			end,
			transitions = {
				finish_attack = STATE_IDLE,
				got_stunned = STATE_STUNNED, -- Can be interrupted
				died = STATE_DEFUNCT,
			},
		},
		[STATE_BLOCKING] = {
			name = STATE_BLOCKING,
			onEnter = function(params: BlockingStateParams?)
				-- print(player.Name .. " entered Blocking state")
				local char = player.Character
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- humanoid.WalkSpeed = 8 -- Example: Reduce walkspeed while blocking
				end
			end,
			onExit = function(params: BlockingStateParams?)
				-- print(player.Name .. " exited Blocking state")
				local char = player.Character
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- humanoid.WalkSpeed = 16 -- Reset walkspeed
				end
			end,
			transitions = {
				stop_block = STATE_IDLE,
				got_stunned = STATE_STUNNED, -- Block can be broken
				died = STATE_DEFUNCT,
			},
		},
		[STATE_STUNNED] = {
			name = STATE_STUNNED,
			onEnter = function(params: StunnedStateParams?)
				-- print(player.Name .. " entered Stunned state for duration:", params and params.duration)
				-- Stop animations, prevent movement/actions.
				-- The actual recovery timer and transition back to Idle ('recover_from_stun')
				-- will be handled by the system that initiated the stun (e.g., orion.luau),
				-- by calling playerState:transition("recover_from_stun") after the duration.
				local char = player.Character
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- humanoid.WalkSpeed = 0 -- Prevent movement
				end
			end,
			onExit = function()
				-- print(player.Name .. " exited Stunned state")
				local char = player.Character
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- humanoid.WalkSpeed = 16 -- Reset walkspeed
				end
			end,
			transitions = {
				recover_from_stun = STATE_IDLE,
				died = STATE_DEFUNCT, -- Can still die while stunned
			},
		},
		[STATE_DEFUNCT] = {
			name = STATE_DEFUNCT,
			onEnter = function(params: DefunctStateParams?)
				-- print(player.Name .. " entered Defunct state (died)")
				-- Handle ragdoll, drop items, notify game systems, etc.
			end,
			-- No onExit usually, player might respawn which would typically involve
			-- creating a new state machine or re-initializing this one to Idle.
			transitions = {
				-- respawn_complete = STATE_IDLE, -- Example if respawn logic transitions here
			},
		},
		[STATE_CHANNELING] = {
			name = STATE_CHANNELING,
			onEnter = function(params: ChannelingStateParams?)
				-- print(player.Name .. " entered Channeling state for:", params and params.abilityName)
				-- Play channeling animation, VFX. Prevent most other actions.
			end,
			onExit = function()
				-- print(player.Name .. " exited Channeling state")
			end,
			transitions = {
				finish_channel_success = STATE_IDLE, -- Or directly into an attack/action state
				channel_interrupted_stun = STATE_STUNNED,
				channel_interrupted_cancel = STATE_IDLE,
				died = STATE_DEFUNCT,
			},
		},
	}

	return StateMachineUtil.new(states, STATE_IDLE)
end

-- Module exports
local StateManager = {
	new = newStateMachine,
	IDLE = STATE_IDLE,
	ATTACKING = STATE_ATTACKING,
	BLOCKING = STATE_BLOCKING,
	STUNNED = STATE_STUNNED,
	DEFUNCT = STATE_DEFUNCT,
	CHANNELING = STATE_CHANNELING,

	-- Export types for external use if needed, e.g. in orion.luau for parameters
	-- Note: Luau doesn't directly export types in the same way as TypeScript.
	-- These are more for documentation or if this table is inspected.
	-- Actual type usage will be through `typeof(StateManager.IdleStateParams)` if needed elsewhere,
	-- but it's often cleaner to define shared types in a dedicated types module if they are widely used.
	_types = {
		PlayerType = "PlayerMarshaller.player", -- Placeholder for documentation
		IdleStateParams = "IdleStateParams",
		AttackingStateParams = "AttackingStateParams",
		BlockingStateParams = "BlockingStateParams",
		StunnedStateParams = "StunnedStateParams",
		DefunctStateParams = "DefunctStateParams",
		ChannelingStateParams = "ChannelingStateParams",
	},
}

export type StateManagerType = typeof(StateManager)
export type IdleParams = IdleStateParams
export type AttackingParams = AttackingStateParams
export type BlockingParams = BlockingStateParams
export type StunnedParams = StunnedStateParams
export type DefunctParams = DefunctStateParams
export type ChannelingParams = ChannelingStateParams


return StateManager
