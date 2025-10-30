--!strict
--[=[
	Dash
	@class Dash

	Handles the dashing mechanic, including speed, effects, and animations.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local Trove = require(ReplicatedStorage.Packages.trove)
local animate = require(game.StarterPlayer.StarterPlayerScripts.Utilities.animate)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local Signal = require(ReplicatedStorage.Parent.Shared.Replicated.Dependencies.SignalPlus)

local class = {}
class.__index = class

export type self = {
	_movementController: any,
	_trove: Trove.Trove,
	_config: any,
	_keybind: Enum.KeyCode,
	_character: Model,
	_humanoid: Humanoid,
	_onCooldown: boolean,

	dashed: Signal.Signal,
}

function class.new(movementController): setmetatable<self, typeof(class)>
	local self = setmetatable({
		_movementController = movementController,
		_trove = Trove.new(),
		_config = MovementConfig.Dash,
		_keybind = MovementConfig.Keybinds.Dash,
		_character = playerMarshaller.get().Character,
		_humanoid = playerMarshaller.get().Character:WaitForChild("Humanoid"),
		_onCooldown = false,

		dashed = Signal.new(),
	}, class)

	animate.loadAnimation("dash", MovementConfig.Animations.Dash)

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
	if self._onCooldown then
		return
	end

	local settings = self._movementController:get("DirectionalSettings"):getSettings("Dash", self._humanoid.MoveDirection)

	local currentStamina = self._character:GetAttribute("Stamina") :: number? or 0
	if currentStamina < settings.StaminaCost then
		return
	end

	self._onCooldown = true
	task.delay(settings.Cooldown, function()
		self._onCooldown = false
	end)

	self._character:SetAttribute("Stamina", currentStamina - settings.StaminaCost)
	self._character:SetAttribute("AntiRegenerate", true)

	animate.play("dash", 0.25)

	local dashTrove = Trove.new()

	local velocity: LinearVelocity = dashTrove:Construct(Instance, "LinearVelocity")
	velocity.Attachment0 =
		dashTrove:Construct(Instance, "Attachment", self._character.PrimaryPart) :: Attachment
	velocity.MaxForce = 30000
	velocity.VectorVelocity = workspace.CurrentCamera.CFrame.LookVector * settings.Force :: number
	--self._character.PrimaryPart.CFrame.LookVector :: Vector3
	velocity.Parent = self._character.PrimaryPart

	local visualEffects = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("VisualEffects")
	local windForce = dashTrove:Clone(visualEffects:WaitForChild("WindForce"))
	windForce.Parent = self._character.PrimaryPart

	task.delay(settings.Duration, function()
		dashTrove:Destroy()
		if self._character :: Model? and self._character.Parent then
			self._character:SetAttribute("AntiRegenerate", false)
		end
	end)

	self.dashed:Fire()
end

function class:destroy(self: self)
	self._trove:Destroy()
	self.dashed:Destroy()
end

return class
