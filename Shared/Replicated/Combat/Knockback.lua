--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local config = ReplicatedStorage:WaitForChild("CombatConfiguration")
local modules = ReplicatedStorage.Modules

local characterUtility = require(ReplicatedStorage.Utility.character)
local createKnockbackVelocity = require(modules.CreateKnockbackVelocity)

function createKnockbackVelocity(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart

	local knockbackAttachment = Instance.new("Attachment")
	knockbackAttachment.Name = "KnockbackAttachment"
	knockbackAttachment.Parent = root

	local knockbackVelocity = Instance.new("LinearVelocity")
	knockbackVelocity.Name = "KnockbackVelocity"
	knockbackVelocity.Attachment0 = knockbackAttachment

	knockbackVelocity.MaxForce = math.huge -- lol

	knockbackVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	knockbackVelocity.RelativeTo = Enum.ActuatorRelativeTo.World

	knockbackVelocity.Enabled = false
	knockbackVelocity.Parent = root
end

function dealKnockback(player: Player, direction: Vector3, knockback: number)
	local character = characterUtility.get(player)
	local root = character.HumanoidRootPart

	if not root:FindFirstChild("KnockbackVelocity") then
		createKnockbackVelocity(character)
	end

	local knockbackVelocity = root:WaitForChild("KnockbackVelocity", 2) :: LinearVelocity
	if not knockback then
		return
	end

	local velocity = direction * knockback

	knockbackVelocity.VectorVelocity = velocity
	knockbackVelocity.Enabled = true

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { character }

	local started = tick()

	while true do
		local currentTime = tick()
		if currentTime - started >= config:WaitForChild("Knockback"):WaitForChild("Duration").Value then
			break
		end

		local ray = workspace:Blockcast(root.CFrame, root.Size, direction, rp)
		if ray and ray.Instance.CanCollide == false then
			break
		end

		game:GetService("RunService").Heartbeat:Wait()
	end

	knockbackVelocity.Enabled = false
end

return dealKnockback
