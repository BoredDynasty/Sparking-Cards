--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local random = require(ReplicatedStorage.Utility.random)

-- knockback.luau

return function(player: Player, direction: Vector3, power: number?, duration: number?): boolean
	local character = player.Character or player.CharacterAdded:Wait()
	local root_part = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root_part or not humanoid or humanoid.Health <= 0 then
		return false
	end

	if direction.Magnitude <= 0 then
		return false
	end

	local force_power = power or 26
	local expiry = duration or 0.35
	local minimum_rotation = 1
	local max_rotation = 10

	-- disable movement
	humanoid.PlatformStand = true

	local attachment = Instance.new("Attachment")
	attachment.Name = "KnockbackAttachment"
	attachment.Parent = root_part

	local force = Instance.new("LinearVelocity")
	force.Name = "KnockbackVelocity"
	force.Attachment0 = attachment
	force.MaxForce = math.huge
	force.VectorVelocity = (direction.Unit + Vector3.new(0, 0.35, 0)).Unit * force_power
	force.Parent = root_part

	local rotation = Instance.new("AngularVelocity")
	rotation.Name = "KnockbackRotation"
	rotation.Attachment0 = attachment
	rotation.AngularVelocity = Vector3.one * math.pi * random.integer(minimum_rotation, max_rotation)
	rotation.MaxTorque = force_power * 200
	rotation.Parent = root_part
	-- the aggresiveness should be (5000)

	task.delay(expiry, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
		end

		force:Destroy()
		rotation:Destroy()
		attachment:Destroy()
	end)

	Debris:AddItem(force, expiry + 0.5)
	Debris:AddItem(rotation, expiry + 0.5)
	Debris:AddItem(attachment, expiry + 0.5)

	return true
end
