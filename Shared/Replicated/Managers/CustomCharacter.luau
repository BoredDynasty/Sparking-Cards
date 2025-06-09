--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local random = require(ReplicatedStorage.Utility.random)
local trove = require(ReplicatedStorage.Utility.trove)

local CustomCharacter = {}
CustomCharacter.__index = CustomCharacter

export type customCharacter = Model & {
	Humanoid: Humanoid & {
		HumanoidDescription: HumanoidDescription,
		Animator: Animator,
	},
	HumanoidRootPart: BasePart,
	BodyColors: BodyColors,
	PrimaryPart: BasePart,
	Animate: LocalScript,
	Head: BasePart & {
		FaceDecals: BasePart & {
			Eyes: Decal,
			Mouth: Decal,
			Overlay: Decal,
		},
	},
	LocalAnimation: Animation?,
}

function CustomCharacter.new(character: customCharacter)
	-- Ensure the character is a valid custom character
	assert(character and character:IsA("Model"), "Invalid character model provided")
	assert(character:FindFirstChild("Humanoid"), "Character must have a Humanoid")
	assert(character:FindFirstChild("HumanoidRootPart"), "Character must have a HumanoidRootPart")
	-- assert(character:FindFirstChild("BodyColors"), "Character must have BodyColors")

	local self = setmetatable({
		character = character,
		blinkTexture = "12520204479",
		defaultEyesTexture = character.Head.FaceDecals.Eyes.Texture, -- Default eyes texture
		_trove = trove.new(),
	}, CustomCharacter)

	self._trove:Add(character, "Destroy")

	return self
end

function CustomCharacter:blink()
	local character = self.character
	local split_frame = 0.032 -- // 2 frames at 60 FPS
	local accumulated = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		accumulated += deltaTime
		local wait_time = split_frame + random.integer(-split_frame, split_frame)
		if accumulated >= wait_time then
			-- blink logic
			task.wait(random.integer() + 0.15 * 0.25) -- random time between blinks
			character.Head.FaceDecals.Eyes.Texture = "rbxassetid://" .. self.blinkTexture
			task.wait(random.integer() + 0.15 * 0.25) -- Random delay between 0.15 and 0.25 seconds
			character.Head.FaceDecals.Eyes.Texture = self.defaultEyesTexture -- Reset to default texture
			accumulated -= wait_time
		end
	end)
end

function CustomCharacter:destroy()
	self._trove:Destroy()
end

CustomCharacter.__tostring = function(self): string
	return "CustomCharacter: " .. self.character.Name
end

return CustomCharacter
