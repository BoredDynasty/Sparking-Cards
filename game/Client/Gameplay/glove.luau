--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- glove.luau

-- just for applying glove models to the player character

local module = {
	gloveL = fetchAsset("GloveL") :: MeshPart,
	gloveR = fetchAsset("GloveR") :: MeshPart,
}

-- note: we are using R6

function module:Get(character: typemarshaller.Character): (MeshPart?, MeshPart?)
	local leftHand = character:WaitForChild("Left Arm")
	local rightHand = character:WaitForChild("Right Arm")

	if not leftHand or not rightHand then
		warn("where are the hands vro :skull:", leftHand, rightHand)

		return nil, nil
	end

	local gloveL, gloveR

	for i, v in ipairs(character:GetDescendants()) do
		if not v:IsA("MeshPart") then
			return nil, nil
		end
		if not CollectionService:HasTag(v, "Glove") then
			return nil, nil
		else
			if v.Name == "GloveL" then
				gloveL = v
			elseif v.Name == "GloveR" then
				gloveR = v
			end
		end
	end

	return gloveL, gloveR
end

function module:Apply(character: typemarshaller.Character)
	local leftHand = character:WaitForChild("Left Arm") :: BasePart
	local rightHand = character:WaitForChild("Right Arm") :: BasePart

	if not leftHand or not rightHand then
		warn("where are the hands vro :skull: ", leftHand, rightHand)
	end

	if leftHand and rightHand then
		local gloveL = module.gloveL:Clone()
		gloveL.Name = "GloveL"
		gloveL.CFrame = leftHand.CFrame
		gloveL.Parent = leftHand
		gloveL.Anchored = false
		gloveL.CanCollide = false
		gloveL.Massless = true
		local weldL = Instance.new("WeldConstraint")
		weldL.Part0 = leftHand
		weldL.Part1 = gloveL
		weldL.Parent = gloveL

		local gloveR = module.gloveR:Clone()
		gloveR.Name = "GloveR"
		gloveR.CFrame = rightHand.CFrame
		gloveR.Parent = rightHand
		gloveR.Anchored = false
		gloveR.CanCollide = false
		gloveR.Massless = true
		local weldR = Instance.new("WeldConstraint")
		weldR.Part0 = rightHand
		weldR.Part1 = gloveR
		weldR.Parent = gloveR

		gloveL:AddTag("Glove")
		gloveR:AddTag("Glove")

		-- set the positioning
		-- and orientation

		gloveL.CFrame = leftHand.CFrame * CFrame.new(0, 1, 0) * CFrame.Angles(0, math.rad(180), math.rad(90))
		gloveR.CFrame = rightHand.CFrame * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90))
	end
end

return module
