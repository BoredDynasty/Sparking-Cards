--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- throw.luau

export type throw = {
	direction: Vector3,
	speed: number, -- studs/s -- studs per second
	character: typemarshaller.Character,
}

local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude
local MAX_THROW_DURATION = 3

return function(parameters: throw): boolean
	local character = parameters.character
	local root_part = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not root_part or not humanoid or humanoid.Health <= 0 then
		return false
	end

	if parameters.direction.Magnitude <= 0 then
		return false
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "ThrowAttachment"
	attachment.Parent = root_part

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "ThrowVelocity"
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = parameters.direction.Unit * parameters.speed
	velocity.Parent = root_part

	local duration = math.min(MAX_THROW_DURATION, math.max(0.1, parameters.speed / 120))
	Debris:AddItem(velocity, duration)
	Debris:AddItem(attachment, duration)

	task.delay(duration, function()
		if velocity.Parent then
			velocity:Destroy()
		end

		if attachment.Parent then
			attachment:Destroy()
		end
	end)

	return true
end
