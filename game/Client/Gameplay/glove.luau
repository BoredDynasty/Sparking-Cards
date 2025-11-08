--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)

-- glove.luau

-- just for applying glove models to the player character

local self = {
	gloveL = fetchAsset("GloveL") :: MeshPart,
	gloveR = fetchAsset("GloveR") :: MeshPart,
}

-- note: we are using R6

function self:Get(character: characterMarshaller.Character): (MeshPart?, MeshPart?)
	local leftHand = characterMarshaller.getLimb(character, "LeftHand")
	local rightHand = characterMarshaller.getLimb(character, "RightHand")

	if not leftHand or not rightHand then
		warn("where are the hands vro :skull:", leftHand, rightHand)

		return nil, nil
	end

	local gloveL, gloveR

	for i, v in pairs(character:GetDescendants()) do
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

function self:Apply(character: characterMarshaller.Character)
	local leftHand = characterMarshaller.getLimb(character, "LeftHand")
	local rightHand = characterMarshaller.getLimb(character, "RightHand")

	if not leftHand or not rightHand then
		warn("where are the hands vro :skull:", leftHand, rightHand)
	end

	if leftHand and rightHand then
		local gloveL = self.gloveL:Clone()
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

		local gloveR = self.gloveR:Clone()
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

return self
