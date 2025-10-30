--!strict
--[=[
	GroundPound
	@class GroundPound

	Handles the ground-pound mechanic.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local Trove = require(ReplicatedStorage.Packages.trove)
local animate = require(game.StarterPlayer.StarterPlayerScripts.Utilities.animate)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local Signal = require(ReplicatedStorage.Parent.Shared.Replicated.Dependencies.SignalPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local gamecamera = require(game.StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)

local class = {}
class.__index = class

export type self = {
	_movementController: any,
	_trove: Trove.Trove,
	_config: any,
	_keybind: Enum.KeyCode,
	_character: Model,
	_humanoid: Humanoid,
	_isGroundPounding: boolean,
	_groundPoundTrove: Trove.Trove?,

	onGroundPound: Signal.Signal,
}

function class.new(movementController): setmetatable<self, typeof(class)>
	local self = setmetatable({
		_movementController = movementController,
		_trove = Trove.new(),
		_config = MovementConfig.GroundPound,
		_keybind = MovementConfig.Keybinds.GroundPound,
		_character = playerMarshaller.get().Character,
		_humanoid = playerMarshaller.get().Character:WaitForChild("Humanoid"),
		_isGroundPounding = false,
		_groundPoundTrove = nil,

		onGroundPound = Signal.new(),
	}, class)

	animate.loadAnimation("groundpound", MovementConfig.Animations.GroundPound)

	self:_connectInputs()

	return self
end

function class:_connectInputs(self: self)
	self._trove:Connect(UserInputService.InputBegan, function(input, gameProcessedEvent)
		if not gameProcessedEvent and input.KeyCode == self._keybind then
			self:start()
		end
	end)
end

function class:start(self: self)
	if self._isGroundPounding then
		return
	end

	if
		self._humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
		and self._humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
	then
		return
	end

	self._isGroundPounding = true
	self._groundPoundTrove = Trove.new()

	animate.play("groundpound", 0.25)

	local velocity = self._groundPoundTrove:Construct(Instance, "LinearVelocity")
	velocity.Attachment0 = self._groundPoundTrove:Construct(Instance, "Attachment", self._character.PrimaryPart)
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.new(0, -self._config.Force, 0)
	velocity.Parent = self._character.PrimaryPart

	self.onGroundPound:Fire()

	local landedConnection
	landedConnection = self._humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Landed then
			self:stop()
			landedConnection:Disconnect()
		end
	end)
end

function class:stop(self: self)
	if not self._isGroundPounding then
		return
	end
	self._isGroundPounding = false

	animate.stop("groundpound")

	if self._groundPoundTrove then
		self._groundPoundTrove:Destroy()
		self._groundPoundTrove = nil
	end

	gamecamera:Shake(0.2, 0.4)
	audio:SFX(150324322)

	local dustEffect = fetchAsset("FootstepDust")
	local dust: BasePart = dustEffect:Clone()
	dust.CFrame = self._character.PrimaryPart.CFrame
		* CFrame.new(0, -self._humanoid.HipHeight, 0)
	dust.Parent = workspace;
	(dust.ParticleEmitter :: ParticleEmitter):Emit(50)
	task.delay(2, function()
		if dust and dust.Parent then
			dust:Destroy()
		end
	end)
end

function class:destroy(self: self)
	self:stop()
	self._trove:Destroy()
	self.onGroundPound:Destroy()
end

return class
