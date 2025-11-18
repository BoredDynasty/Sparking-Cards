--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local orion = require(ReplicatedStorage.Combat.orion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local stun = require(ReplicatedStorage.Combat.Strike.stun)

-- parry.luau

-- we need a more robust and advanced system for this.

local parry = {
	PARRY_WINDOW = 0.35, -- seconds allowed after client parry start (tweak)
	PARRY_COOLDOWN = 0.6,
	STUN_DURATION = 0.7,
	RIPOSTE_WINDOW = 0.6,
}

local parryingPlayers = {}

local function startParry(player: Player)
	local playerId = player.UserId
	if parryingPlayers[playerId] then
		return
	end

	parryingPlayers[playerId] = true

	task.delay(parry.PARRY_WINDOW, function()
		if parryingPlayers[playerId] then
			parryingPlayers[playerId] = nil
		end
	end)
end

local function onDamageIncoming(damageData: damage.Damage)
	local targetPlayer = damageData.target
	if not targetPlayer then
		return
	end

	local targetId = targetPlayer.UserId
	if not parryingPlayers[targetId] then
		return
	end

	-- Successfully parried
	parryingPlayers[targetId] = nil -- End parry window immediately

	-- Cancel the damage
	damage.cancel:Fire()

	-- Stun the attacker
	local sourcePlayer = damageData.source
	if sourcePlayer then
		stun(sourcePlayer, parry.STUN_DURATION)
	end

	-- Notify the client of the successful parry
	local playerInstance = playerMarshaller.getByUserId(targetId)
	if playerInstance then
		Packet.ParrySuccess.sendTo({}, playerInstance)
	end
end

Packet.AttemptParry.listen(function(player: Player)
	startParry(player)
end)

damage.incoming:Connect(onDamageIncoming)

return parry
