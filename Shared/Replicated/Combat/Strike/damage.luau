--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local damageIndict = require(ReplicatedStorage.Effects.damageIndict)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- damage.luau

-- This module handles the damage calculations and effects for combat strikes in the Orion framework.

export type Damage = {
	amount: number, -- The amount of damage dealt
	source: playerMarshaller.player?, -- Optional player who dealt the damage
	target: playerMarshaller.player, -- player who received the damage
}

local damage = setmetatable({}, {
	__call = function(self, parameters: Damage)
		return self.__call(parameters)
	end,
})
damage.__index = damage

export type incomingSignal = SignalPlus.Signal<Damage>

damage.currentlyInflicting = {}
damage.incoming = SignalPlus() :: incomingSignal
damage.cancel = SignalPlus()

function damage.__call(parameters: Damage)
	-- Process damage logic here
	local damageAmount = parameters.amount
	local sourcePlayerId = parameters.source and parameters.source.UserId
	local targetPlayerId = parameters.target and parameters.target.UserId

	-- get the player instances
	local sourceInstance = parameters.source and playerMarshaller.getByUserId(sourcePlayerId)
	local targetInstance = parameters.target and playerMarshaller.getByUserId(targetPlayerId)

	local targetCharacter = targetInstance.Character

	-- do a nice lil visual effect for the damage
	local targetRoot = targetCharacter:WaitForChild("HumanoidRootPart") :: BasePart
	damageIndict(damageAmount, targetRoot)

	local targetHumanoid = targetCharacter:WaitForChild("Humanoid") :: Humanoid
	damage.incoming:Fire({
		amount = damageAmount,
		source = sourceInstance,
		target = targetInstance,
	})
	damage.cancel:Once(function()
		-- if the damage is cancelled, we don't apply it
		return false
	end)
	task.wait(0.032)
	targetHumanoid:TakeDamage(damageAmount)

	return true -- Indicate success
end

return damage
