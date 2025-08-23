--!strict
--[=[
	Jump
	@class Jump

	Handles the jumping mechanic, including stamina cost and double jump prevention.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local audio = require(ReplicatedStorage.Modules.audio)
local gamecamera = require(game.StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local Jump = {}
Jump.__index = Jump

function Jump.new(movementController)
	local self = setmetatable({}, Jump)

	self._movementController = movementController
	self._trove = require(ReplicatedStorage.Packages.trove).new()
	self._config = MovementConfig.Jump
	self._character = playerMarshaller.get().Character
	self._humanoid = self._character:WaitForChild("Humanoid")

	self._dustEffect = self:_createDustEffect()

	self:_connectJumpRequest()
	self:_connectLanding()

	return self
end

function Jump:_createDustEffect()
	local dustEffect = Instance.new("Part")
	dustEffect.Name = "DustEffect"
	dustEffect.Size = Vector3.new(1, 1, 1)
	dustEffect.Anchored = true
	dustEffect.CanCollide = false
	dustEffect.Transparency = 1

	local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
	dustEffect.Parent = assetsFolder
	self._trove:Add(dustEffect)

	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(196, 178, 142))
	particleEmitter.LightEmission = 0
	particleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5, 0),
		NumberSequenceKeypoint.new(1, 2, 0),
	})
	particleEmitter.Texture = "rbxassetid://137952435" -- Smoke texture
	particleEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0, 0),
		NumberSequenceKeypoint.new(0.5, 0.5, 0),
		NumberSequenceKeypoint.new(1, 1, 0),
	})
	particleEmitter.Lifetime = NumberRange.new(0.5, 1)
	particleEmitter.Rate = 0
	particleEmitter.Speed = NumberRange.new(1, 3)
	particleEmitter.SpreadAngle = Vector2.new(360, 360)
	particleEmitter.Parent = dustEffect

	return dustEffect
end

function Jump:_connectJumpRequest()
	self._trove:Connect(UserInputService.JumpRequest, function()
		if
			self._humanoid:GetState() == Enum.HumanoidStateType.Jumping
			or self._humanoid:GetState() == Enum.HumanoidStateType.Freefall
		then
			return
		end

		local currentStamina = self._character:GetAttribute("Stamina") or 0
		if currentStamina < self._config.StaminaCost then
			return
		end

		gamecamera:Shake(0.5, 0.1)

		self._humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		self._character:SetAttribute("Stamina", currentStamina - self._config.StaminaCost)
		self._character:SetAttribute("AntiRegenerate", true)
		task.delay(0.5, function()
			if self._character and self._character.Parent then
				self._character:SetAttribute("AntiRegenerate", false)
			end
		end)

		local dust: BasePart = self._dustEffect:Clone()
		dust.CFrame = self._character.PrimaryPart.CFrame
			* CFrame.new(0, -self._humanoid.HipHeight :: number, 0)
		dust.Parent = workspace;
		(dust.ParticleEmitter :: ParticleEmitter):Emit(20)
		task.delay(2, function()
			if dust and dust.Parent then
				dust:Destroy()
			end
		end)
	end)
end

function Jump:_connectLanding()
	self._trove:Connect(self._humanoid.StateChanged, function(oldState, newState)
		if newState == Enum.HumanoidStateType.Landed then
			-- Landing mechanic
			gamecamera:Shake(1.2, 0.2)
			audio:SFX("LandingSound", 150324322)
		end
	end)
end

function Jump:Destroy()
	self._trove:Destroy()
end

return Jump
