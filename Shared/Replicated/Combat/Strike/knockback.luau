--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local random = require(ReplicatedStorage.Utility.random)
local trove = require(ReplicatedStorage.Packages.trove)

-- knockback.luau

local _trove = trove.new()

return function(player: playerMarshaller.player, direction: Vector3)
	local character = player.Character
	local rootPart = character.HumanoidRootPart
	local humanoid = character.Humanoid

	local forcePower = 200
	local forceTime = 0.75
	local minimimRotation = 1
	local maxRotation = 10

	-- disable movement
	humanoid.PlatformStand = true

	local force = Instance.new("LinearVelocity")
	force.Parent = rootPart
	force.MaxForce = math.huge
	force.VectorVelocity = (direction + Vector3.new(0, 1, 0)).Unit * 26

	local rotation = Instance.new("AngularVelocity")
	rotation.Parent = rootPart
	rotation.AngularVelocity = Vector3.one * math.pi * random.integer(minimimRotation, maxRotation)
	rotation.MaxTorque = math.huge
	-- the aggresiveness should be (5000)

	_trove:Add(force)
	_trove:Add(rotation)

	task.delay(forceTime, function()
		humanoid.PlatformStand = false
		_trove:Remove(force)
		_trove:Remove(rotation)
	end)
end
