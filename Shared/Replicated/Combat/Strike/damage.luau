--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local damageIndict = require(ReplicatedStorage.Combat.framework.effects.damageIndict)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- damage.luau

-- This module handles the damage calculations and effects for combat strikes in the Orion framework.

export type Damage = {
	amount: number, -- The amount of damage dealt
	source: playerMarshaller.player?, -- Optional player who dealt the damage
	target: playerMarshaller.player, -- player who received the damage
}

return function(parameters: Damage)
	-- Validate parameters
	assert(type(parameters.amount) == "number", "Damage amount must be a number")
	assert(
		parameters.target == nil or type(parameters.target) == "table",
		"Target must be a player object or nil"
	)

	-- Process damage logic here
	local damageAmount = parameters.amount
	local sourcePlayerId = parameters.source and parameters.source.UserId
	local targetPlayerId = parameters.target and parameters.target.UserId

	-- get the player instances
	local sourceInstance = parameters.source and playerMarshaller.getByUserId(sourcePlayerId)
	local targetInstance = parameters.target and playerMarshaller.getByUserId(targetPlayerId)

	-- do a nice lil visual effect for the damage
	local targetRoot = targetInstance:WaitForChild("HumanoidRootPart") :: BasePart
	damageIndict(damageAmount, targetRoot)

	local targetHumanoid = targetInstance:WaitForChild("Humanoid") :: Humanoid
	targetHumanoid:TakeDamage(parameters.amount)

	return true -- Indicate success
end
