--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packet = require(ReplicatedStorage.Packet)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local parryConstants = require(ReplicatedStorage.Combat.framework.features.parry)
local stun = require(ReplicatedStorage.Combat.Strike.stun)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- ParryHandler.luau

local ParryHandler = {}

local parryingPlayers = {}

local function startParry(player: playerMarshaller.player)
	local playerId = player.UserId
	if parryingPlayers[playerId] then
		return
	end

	parryingPlayers[playerId] = true

	task.delay(parryConstants.PARRY_WINDOW, function()
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
		stun(sourcePlayer, parryConstants.STUN_DURATION)
	end

	-- Notify the client of the successful parry
	local playerInstance = playerMarshaller.getByUserId(targetId)
	if playerInstance then
		Packet.ParrySuccess.sendTo({}, playerInstance)
	end
end

Packet.AttemptParry.on(function(playerInstance)
	local player = playerMarshaller.get(playerInstance)
	startParry(player)
end)

damage.incoming:Connect(onDamageIncoming)

return ParryHandler
