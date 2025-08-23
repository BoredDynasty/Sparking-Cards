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

local Dash = {}
Dash.__index = Dash

function Dash.new(movementController)
	local self = setmetatable({}, Dash)

	self._movementController = movementController
	self._trove = Trove.new()
	self._config = MovementConfig.Dash
	self._keybind = MovementConfig.Keybinds.Dash
	self._character = playerMarshaller.get().Character
	self._humanoid = self._character:WaitForChild("Humanoid")
	self._onCooldown = false

	animate.loadAnimation("dash", MovementConfig.Animations.Dash)

	self:_connectInputs()

	return self
end

function Dash:_connectInputs()
	self._trove:Connect(UserInputService.InputBegan, function(input, gameProcessedEvent)
		if not gameProcessedEvent and input.KeyCode == self._keybind then
			self:Start()
		end
	end)
end

function Dash:Start()
	if self._onCooldown then
		return
	end

	local currentStamina = self._character:GetAttribute("Stamina") :: number? or 0
	if currentStamina < self._config.StaminaCost then
		return
	end

	self._onCooldown = true
	task.delay(self._config.Cooldown, function()
		self._onCooldown = false
	end)

	self._character:SetAttribute("Stamina", currentStamina - self._config.StaminaCost)
	self._character:SetAttribute("AntiRegenerate", true)

	animate.play("dash", 0.25)

	local dashTrove = Trove.new()

	local velocity: LinearVelocity = dashTrove:Construct(Instance, "LinearVelocity")
	velocity.Attachment0 =
		dashTrove:Construct(Instance, "Attachment", self._character.PrimaryPart) :: Attachment
	velocity.MaxForce = 30000
	velocity.VectorVelocity = workspace.CurrentCamera.CFrame.LookVector * self._config.Force :: number
	--self._character.PrimaryPart.CFrame.LookVector :: Vector3
	velocity.Parent = self._character.PrimaryPart

	local visualEffects = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("VisualEffects")
	local windForce = dashTrove:Clone(visualEffects:WaitForChild("WindForce"))
	windForce.Parent = self._character.PrimaryPart

	task.delay(self._config.Duration, function()
		dashTrove:Destroy()
		if self._character :: Model? and self._character.Parent then
			self._character:SetAttribute("AntiRegenerate", false)
		end
	end)
end

function Dash:Destroy()
	self._trove:Destroy()
end

return Dash
