--!nonstrict
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
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local input = require(ReplicatedStorage.Packages.input)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local speed_lines = require(ReplicatedStorage.Effects["speed-lines"])

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
	self._onCooldown = observer.new(false)
	self._camera = workspace.CurrentCamera
	self._mouse = input.Mouse.new()

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
	if self._onCooldown:Get() then
		return
	end

	if not self._character then
		return
	end
	if self._humanoid.Health <= 0 then
		return
	end

	local currentStamina = self._character:GetAttribute("Stamina") :: number? or 0
	if currentStamina < self._config.StaminaCost then
		return
	end

	self._onCooldown:Set(true)
	task.delay(self._config.Cooldown, function()
		self._onCooldown:Set(false)
	end)

	self._character:SetAttribute("Stamina", currentStamina - self._config.StaminaCost)
	self._character:SetAttribute("AntiRegenerate", true)

	animate.play("dash", 0.25)

	-- get dash direction
	local direction = nil

	local head = self._character:FindFirstChild("Head") :: BasePart
	if not head then
		animate.stop("dash")

		if self._character then
			self._character:SetAttribute("AntiRegenerate", false)
		end

		self._onCooldown:Set(false)

		return
	end

	if head.LocalTransparencyModifier == 1 then
		-- we are in first person
		direction = (self._camera :: Camera).CFrame.LookVector
	else
		-- we are not in first person
		local ray = self._mouse:GetRay() :: Ray
		if not ray then
			direction = (self._camera :: Camera).CFrame.LookVector -- lmao
		end

		local unit_ray = ray.Unit
		direction = unit_ray.Direction
	end

	local attachment0 =
		self._trove:Construct(Instance, "Attachment", self._character.PrimaryPart) :: Attachment

	local velocity: LinearVelocity = self._trove:Construct(Instance, "LinearVelocity")
	velocity.Attachment0 = attachment0
	velocity.MaxForce = 30000
	velocity.VectorVelocity = direction * self._config.Force :: number
	velocity.Parent = self._character.PrimaryPart

	local lines = fetchAsset("Speedlines")

	speed_lines:On(gamecamera.camera, lines)

	task.delay(self._config.Duration, function()
		self._trove:Remove(velocity)
		self._trove:Remove(attachment0)

		if self._character then
			self._character:SetAttribute("AntiRegenerate", false)
		end

		speed_lines:Off(lines)
	end)
end

function Dash:Destroy()
	self._trove:Destroy()
	self._onCooldown:Destroy()
	speed_lines:Off()
end

return Dash
