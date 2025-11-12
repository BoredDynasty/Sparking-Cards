--!strict
--[[
	ExampleReaction.luau
	An example reaction module.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Orion = require(ReplicatedStorage.Combat.orion)
-- local Packet = require(ReplicatedStorage.Packet)
local PlayerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

type Player = PlayerMarshaller.player
type AttackData = Orion.AttackData

local ExampleReaction = {}

--[[
	This function is called when a player with this reaction is damaged.

	@param damagedPlayer The player who was damaged.
	@param sourcePlayer The player who dealt the damage.
	@param damage The amount of damage dealt.
	@param attackData Data about the attack.
]]
function ExampleReaction.OnPlayerDamaged(
	damagedPlayer: Player,
	sourcePlayer: Player?,
	damage: number,
	attackData: AttackData?
)
	-- This function would contain the logic for the reaction.
	-- For example, it could apply a status effect to the attacker,
	-- or heal the damaged player.
end

return ExampleReaction
