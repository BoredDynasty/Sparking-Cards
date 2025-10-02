--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local arbitrary = require(ReplicatedStorage.Combat.framework.utils.arbitrary)
local explosion = require(ReplicatedStorage.Combat.framework.effects.explosion)
local freeze = require(ReplicatedStorage.Combat.framework.status.freeze)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local timer = require(ReplicatedStorage.Modules.timer)
local trove = require(ReplicatedStorage.Packages.trove)
local visuals = require(ReplicatedStorage.Combat.framework.visuals)

local cryo = {
	moveset = {},
	_trove = trove.new(),
}

function cryo.moveset:M1(player: playerMarshaller.player)
	--
end

function cryo.moveset:Skill(player: playerMarshaller.player, position: Vector3, duration: number?)
	duration = duration or 1.5

	local stack = SignalPlus()

	explosion.kaboom({
		position = position,
		duration = duration,
		colors = {
			Color3.new(0.305882, 0.470588, 1),
			Color3.new(0.584314, 0.682353, 1),
			Color3.new(0.113725, 0.321569, 1),
		},
	})

	visuals.rocks(CFrame.new(position), 1, 10)
	freeze(player, stack)

	local clock = timer.new()
	clock:Start()
	clock:interval(1, stack.Fire, stack)

	task.delay(10, function()
		clock:Destroy()
	end)
end
