--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local animate = require("../Utilities/animate")
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local ragdoll = {}

local RAGDOLL_INSTANCE_NAMES = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}
--[[
	@param character: Model
	@param humanoid: Humanoid

	This process involves disabling existing Motor6D joints and replacing them
	with physics-based constraints.
]]
local function replaceJoints(character: characterMarshaller.Character, humanoid: Humanoid)
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = true

	local animateScript = character:FindFirstChild("Animate") :: LocalScript?
	if animateScript then
		animateScript.Enabled = false
	end

	animate.stopAll(0.25)

	for _, motor: Motor6D in pairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
			-- disable the Motor6D to allow physics to take over
			motor.Enabled = false

			local attachment0 = Instance.new("Attachment")
			local attachment1 = Instance.new("Attachment")

			attachment0.CFrame = motor.C0
			attachment1.CFrame = motor.C1
			attachment0.Name = "RagdollAttachment"
			attachment1.Name = "RagdollAttachment"

			local ballSocketConstraint = Instance.new("BallSocketConstraint")
			ballSocketConstraint.Attachment0 = attachment0
			ballSocketConstraint.Attachment1 = attachment1
			ballSocketConstraint.Name = "RagdollConstraint"
			ballSocketConstraint.Radius = 0.15
			ballSocketConstraint.LimitsEnabled = true
			ballSocketConstraint.TwistLimitsEnabled = true -- Allow some twist, but with limits
			ballSocketConstraint.MaxFrictionTorque = 0 -- No friction at the joint
			ballSocketConstraint.Restitution = 0 -- No bounce at the joint
			ballSocketConstraint.UpperAngle = 90
			ballSocketConstraint.TwistLowerAngle = -45
			ballSocketConstraint.TwistUpperAngle = 45

			if string.find(motor.Name, "Neck") then
				ballSocketConstraint.UpperAngle = 45
				ballSocketConstraint.TwistLowerAngle = -70
				ballSocketConstraint.TwistUpperAngle = 70
			elseif string.find(motor.Name, "Hip") then
				ballSocketConstraint.UpperAngle = 60
				ballSocketConstraint.TwistLowerAngle = -30
				ballSocketConstraint.TwistUpperAngle = 30
			elseif string.find(motor.Name, "Shoulder") then
				ballSocketConstraint.UpperAngle = 75
				ballSocketConstraint.TwistLowerAngle = -60
				ballSocketConstraint.TwistUpperAngle = 60
			end

			attachment0.Parent = motor.Part0
			attachment1.Parent = motor.Part1
			ballSocketConstraint.Parent = motor.Parent
		end
	end
	humanoid.AutoRotate = false

	-- this flag might be used for anti cheat
	character:SetAttribute("LastRag", tick())
end
--[[
	@param character: Model -- The character model to unragdoll.
	@param humanoid: Humanoid -- The humanoid object within the character.
	@brief Destroys all Ragdoll-related instances (attachments, constraints, colliders)
	and re-enables the original Motor6D's to restore normal character animation.
]]
local function resetJoints(character: characterMarshaller.Character, humanoid: Humanoid)
	-- Do not unragdoll if the humanoid is dead
	if humanoid.Health <= 0 then
		return
	end

	for _, instance in pairs(character:GetDescendants()) do
		if RAGDOLL_INSTANCE_NAMES[instance.Name] then
			instance:Destroy()
		end

		if instance:IsA("Motor6D") then
			instance.Enabled = true
		end
	end
	humanoid.AutoRotate = true

	local animateScript = character:FindFirstChild("Animate") :: LocalScript?
	if animateScript then
		animateScript.Enabled = true
	end
end
--[[
	@param character: Model -- The character model to push.
	@param direction: Vector3 -- The direction of the push to apply.
	@brief Applies an impulse to the character's HumanoidRootPart or Torso.
]]
local function applyPush(character: characterMarshaller.Character, direction: Vector3)
	local rootPart = character.HumanoidRootPart
	if rootPart then
		rootPart:ApplyImpulse(direction)
	end
end
--[[
	@param character: Model
	@param value: boolean
	@param push: boolean?
	@param direction: Vector3?
]]
function ragdoll.SetRagdoll(
	character: characterMarshaller.Character,
	value: boolean,
	push: boolean?,
	direction: Vector3?
)
	local humanoid = character.Humanoid
	assert(humanoid and humanoid.Health > 0, `Invalid humanoid : {humanoid}`)

	push = push or false
	direction = direction or Vector3.new(0, 0, 1)

	if value then
		-- ragdoll
		replaceJoints(character, humanoid)

		humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		-- apply push
		if push then
			applyPush(character, direction)
		end
	else
		-- unragdoll
		resetJoints(character, humanoid)

		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

		local player = playerMarshaller.getFromCharacter(character)
		if player then
			character.PrimaryPart:SetNetworkOwner(player)
		end
	end
end
-- Return the module
return ragdoll
