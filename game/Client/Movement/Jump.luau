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
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
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
	local dustEffect = fetchAsset("FootstepDust")
	self._trove:Add(dustEffect)

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

		gamecamera:Shake(0.05, 0.1)

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
			gamecamera:Shake(0.1, 0.2)
			audio:SFX(150324322)
		end
	end)
end

function Jump:Destroy()
	self._trove:Destroy()
end

return Jump
