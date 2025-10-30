--!strict
--[=[
	Sprint
	@class Sprint

	Handles the sprinting mechanic, including stamina drain, speed increase, and animations.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local Trove = require(ReplicatedStorage.Packages.trove)
local animate = require(game.StarterPlayer.StarterPlayerScripts.Utilities.animate)
local dialogue = require(ReplicatedStorage.ClientModules.dialogue)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local speed_lines = require(ReplicatedStorage.Effects["speed-lines"])
local spr = require(ReplicatedStorage.Modules.spr)
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
	_isSprinting: boolean,
	_speedForceEffect: any,
	_originalWalkSpeed: number,
	_sprintWalkSpeed: number,
	_originalFOV: number,
	_sprintFOV: number,

	sprintStarted: Signal.Signal,
	sprintStopped: Signal.Signal,
}

function class.new(movementController): setmetatable<self, typeof(class)>
	local self = setmetatable({
		_movementController = movementController,
		_trove = Trove.new(),
		_config = MovementConfig.Sprint,
		_keybind = MovementConfig.Keybinds.Sprint,
		_character = playerMarshaller.get().Character,
		_humanoid = playerMarshaller.get().Character:WaitForChild("Humanoid"),
		_isSprinting = false,
		_speedForceEffect = nil,

		_originalWalkSpeed = MovementConfig.Character.BaseSpeed,
		_sprintWalkSpeed = MovementConfig.Character.BaseSpeed + MovementConfig.Sprint.SpeedIncrease,

		_originalFOV = 70,
		_sprintFOV = 70 + MovementConfig.Sprint.FieldOfViewIncrease,

		sprintStarted = Signal.new(),
		sprintStopped = Signal.new(),
	}, class)

	animate.loadAnimation("run", MovementConfig.Animations.Run)

	self:_connectInputs()

	return self
end

function class:_connectInputs(self: self)
	self._trove:Connect(UserInputService.InputBegan, function(input, gameProcessedEvent)
		if not gameProcessedEvent and input.KeyCode == self._keybind then
			self:start()
		end
	end)

	self._trove:Connect(UserInputService.InputEnded, function(input, gameProcessedEvent)
		if not gameProcessedEvent and input.KeyCode == self._keybind then
			self:stop()
		end
	end)
end

function class:start(self: self)
	if self._isSprinting then
		return
	end
	if (self._character:GetAttribute("Stamina") or 0) <= 0 then
		return
	end
	if self._humanoid.MoveDirection.Magnitude == 0 then
		return
	end

	self._isSprinting = true
	self._humanoid.WalkSpeed = self._sprintWalkSpeed
	self._character:SetAttribute("AntiRegenerate", true)
	animate.play("run", 0.25)

	-- tween fovspr.target(self._sprintFOV, 0.5, gamecamera.getFOV, gamecamera.setFOV)

	--dialogue:speak("You", "Woohoo!")

	self._speedForceEffect = fetchAsset("Speedlines") :: speed_lines.lines
	speed_lines:On(gamecamera.camera, self._speedForceEffect)
	self.sprintStarted:Fire()
end

function class:stop(self: self)
	if not self._isSprinting then
		return
	end

	self._isSprinting = false
	self._humanoid.WalkSpeed = self._originalWalkSpeed
	self._character:SetAttribute("AntiRegenerate", false)
	animate.stop("run")

	speed_lines:Off(self._speedForceEffect)
	task.defer(function()
		self._speedForceEffect = nil
	end)
	self.sprintStopped:Fire()
end

function class:update(self: self, deltaTime: number)
	if not self._isSprinting then
		return
	end

	local currentStamina = self._character:GetAttribute("Stamina") :: number? or 0
	local newStamina = currentStamina - (self._config.StaminaDrainRate :: number * deltaTime)
	self._character:SetAttribute("Stamina", newStamina)

	if newStamina <= 0 or self._humanoid.MoveDirection.Magnitude == 0 then
		self:stop()
	end
end

function class:destroy(self: self)
	self:stop()
	self._trove:Destroy()
	self.sprintStarted:Destroy()
	self.sprintStopped:Destroy()
end

return class
