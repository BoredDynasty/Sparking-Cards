--!strict
--[=[
	Sprint
	@class Sprint

	Handles the sprinting mechanic, including stamina drain, speed increase, and animations.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local Trove = require(ReplicatedStorage.Packages.trove)
local animate = require(game.StarterPlayer.StarterPlayerScripts.Utilities.animate)
local gamecamera = require(game.StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local spr = require(ReplicatedStorage.Modules.spr)

local Sprint = {}
Sprint.__index = Sprint

function Sprint.new(movementController)
	local self = setmetatable({}, Sprint)

	self._movementController = movementController
	self._trove = Trove.new()
	self._config = MovementConfig.Sprint
	self._keybind = MovementConfig.Keybinds.Sprint
	self._character = playerMarshaller.get().Character
	self._humanoid = self._character:WaitForChild("Humanoid")
	self._isSprinting = false
	self._speedForceEffect = nil

	self._originalWalkSpeed = MovementConfig.Character.BaseSpeed
	self._sprintWalkSpeed = self._originalWalkSpeed + self._config.SpeedIncrease

	self._originalFOV = 70
	self._sprintFOV = self._originalFOV + self._config.FieldOfViewIncrease

	animate.loadAnimation("run", MovementConfig.Animations.Run)

	self:_connectInputs()

	return self
end

function Sprint:_connectInputs()
	self._trove:Connect(UserInputService.InputBegan, function(input, gameProcessedEvent)
		if not gameProcessedEvent and input.KeyCode == self._keybind then
			self:Start()
		end
	end)

	self._trove:Connect(UserInputService.InputEnded, function(input, gameProcessedEvent)
		if not gameProcessedEvent and input.KeyCode == self._keybind then
			self:Stop()
		end
	end)
end

function Sprint:Start()
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

	dialogue.client:speak({
		speaker = "You",
		text = "Weee!",
	})

	local visualEffects = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("VisualEffects")
	self._speedForceEffect = visualEffects:WaitForChild("SpeedForce"):Clone()
	self._speedForceEffect.Parent = self._character.PrimaryPart
end

function Sprint:Stop()
	if not self._isSprinting then
		return
	end

	self._isSprinting = false
	self._humanoid.WalkSpeed = self._originalWalkSpeed
	self._character:SetAttribute("AntiRegenerate", false)
	animate.stop("run")

	gamecamera:TweenFOV(self._originalFOV, 0.5)

	if self._speedForceEffect then
		self._speedForceEffect:Destroy()
		self._speedForceEffect = nil
	end
end

function Sprint:Update(deltaTime: number)
	if not self._isSprinting then
		return
	end

	local currentStamina = self._character:GetAttribute("Stamina") :: number? or 0
	local newStamina = currentStamina - (self._config.StaminaDrainRate :: number * deltaTime)
	self._character:SetAttribute("Stamina", newStamina)

	if newStamina <= 0 or self._humanoid.MoveDirection.Magnitude == 0 then
		self:Stop()
	end
end

function Sprint:Destroy()
	self:Stop()
	self._trove:Destroy()
end

return Sprint
