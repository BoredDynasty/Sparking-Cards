--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

-- grip.luau
export type GripInfo = {
	offset: CFrame,
	joint: Motor6D?,
	model: Model,
	attachment: Attachment?,
	hand: "Left" | "Right",
}

-- // objects
local motors: { [Model]: GripInfo } = {}

--[[

   ```luau

   local grip = require(path.to.grip)

   -- When equipping a weapon:
   local weapon = weaponModel -- your weapon model
   local character = playerCharacter -- the character model
   local gripInfo = grip.createGrip(character, weapon, "Right", CFrame.new(0, 0, 0))
   ```
]]
local function createGrip(character: Model, model: Model, hand: "Left" | "Right", offset: CFrame?): GripInfo?
	if not character then
		return nil
	end

	local handName = hand .. "Hand"
	local handPart = character:FindFirstChild(handName)
	if not handPart or not handPart:IsA("BasePart") then
		return nil
	end

	-- Create attachment for grip point
	local attachment = Instance.new("Attachment")
	attachment.Name = "GripAttachment"
	attachment.CFrame = offset or CFrame.new(0, 0, 0)
	attachment.Parent = handPart

	-- Create motor for weapon model
	local joint = Instance.new("Motor6D")
	joint.Name = "GripJoint"
	joint.Part0 = handPart
	joint.Part1 = model.PrimaryPart
	joint.C0 = attachment.CFrame
	joint.C1 = CFrame.new()
	joint.Parent = handPart

	local gripInfo: GripInfo = {
		offset = offset or CFrame.new(),
		joint = joint,
		model = model,
		attachment = attachment,
		hand = hand,
	}

	motors[model] = gripInfo
	return gripInfo
end

--[[

   ```luau

   -- When unequipping:
   grip.removeGrip(weapon)
   ```
]]
local function removeGrip(model: Model)
	local gripInfo = motors[model]
	if not gripInfo then
		return
	end

	if gripInfo.joint then
		gripInfo.joint:Destroy()
	end

	if gripInfo.attachment then
		gripInfo.attachment:Destroy()
	end

	motors[model] = nil
end

--[[

   ```luau
    
   -- Update grips (call this regularly, e.g., in heartbeat):
   grip.update(character)
   ```
]]
local function update(character: Model?)
	if not character then
		return
	end

	debug.profilebegin("update-grip")

	for model, gripInfo in motors do
		if not model.PrimaryPart then
			continue
		end

		local handName = gripInfo.hand .. "Hand"

		local handPart = character:FindFirstChild(handName)

		if not handPart or not handPart:IsA("BasePart") then
			removeGrip(model)
			continue
		end

		-- Update joint if needed
		if gripInfo.joint and gripInfo.joint.Parent ~= handPart then
			removeGrip(model)
		end
	end

	debug.profileend()
end

local function auto_update()
	RunService.PreAnimation:Connect(function()
		debug.profilebegin("update-grips")

		if not next(motors) then
			return -- if empty
		end

		for i, grip in pairs(motors) do
			update(grip.model)
		end

		debug.profileend()
	end)
end

return table.freeze({
	createGrip = createGrip,
	removeGrip = removeGrip,
	update = update,
	auto_update = auto_update,
})
