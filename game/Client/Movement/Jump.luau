--!strict
--[=[
	Jump
	@jump_controller Jump

	Handles the jumping mechanic, including stamina cost and double jump prevention.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local gamecamera = require(game.StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

local jump_controller = {}
jump_controller.__index = jump_controller

export type self = {
	_movementController: any,
	_trove: typeof(trove.new()),
	_config: any,
	_character: Model,
	_humanoid: Humanoid,
	_dustEffect: BasePart,

	landed: SignalPlus.Signal<>,
	jumped: SignalPlus.Signal<>,
}

function jump_controller.new(movementController): setmetatable<self, typeof(jump_controller)>
	local self = setmetatable({
		_movementController = movementController,
		_trove = trove.new(),
		_config = MovementConfig.Jump,
		_character = playerMarshaller.get().Character,
		_humanoid = playerMarshaller.get().Character:WaitForChild("Humanoid"),
		_dustEffect = fetchAsset("FootstepDust"),

		jumped = SignalPlus(),
		landed = SignalPlus(),
	}, jump_controller)

	self._trove:Add(self._dustEffect)

	self:_connectJumpRequest()
	self:_connectLanding()

	return self
end

function jump_controller:_connectJumpRequest(self: self)
	self._trove:Connect(UserInputService.JumpRequest, function()
		if self._humanoid.Health <= 0 then
			return
		end
		if not self._character.PrimaryPart then
			return
		end
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
		self.jumped:Fire()
	end)
end

function jump_controller:_connectLanding(self: self)
	self._trove:Connect(self._humanoid.StateChanged, function(oldState, newState)
		if newState == Enum.HumanoidStateType.Landed then
			-- Landing mechanic
			gamecamera:Shake(0.1, 0.2)
			audio:SFX(150324322)
			self.landed:Fire()
		end
	end)
end

function jump_controller:destroy(self: self)
	self._trove:Destroy()
	self.jumped:Destroy()
	self.landed:Destroy()
end

return jump_controller
