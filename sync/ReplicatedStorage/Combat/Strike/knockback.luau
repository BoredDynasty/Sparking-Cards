--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)
local random = require(ReplicatedStorage.Utility.random)
local trove = require(ReplicatedStorage.Packages.trove)

-- knockback.luau

local _trove = trove.new()

return function(player: Player, direction: Vector3)
	local character = player.Character or player.CharacterAdded:Wait()
	local root_part = character.PrimaryPart
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local force_power = 200
	local expiry = 0.75
	local minimum_rotation = 1
	local max_rotation = 10

	-- disable movement
	humanoid.PlatformStand = true

	local force = _trove:Construct(Instance, "LinearVelocity", root_part) :: LinearVelocity
	hydration(force) {
		Parent = root_part,
		MaxForce = math.huge,
		VectorVelocity = (direction + Vector3.new(0, 1, 0)).Unit * 26,
	}

	local rotation = _trove:Construct(Instance, "AngularVelocity", root_part) :: AngularVelocity
	hydration(rotation) {
		Parent = root_part,
		AngularVelocity = Vector3.one * math.pi * random.integer(minimum_rotation, max_rotation),
		MaxTorque = force_power,
	}
	-- the aggresiveness should be (5000)

	task.delay(expiry, function()
		humanoid.PlatformStand = false

		_trove:Remove(force)
		_trove:Remove(rotation)
	end)
end
