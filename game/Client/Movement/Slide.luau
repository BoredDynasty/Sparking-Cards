--!strict
--[=[
	Slide
	@class Slide

	Handles the sliding mechanic, including speed, hip height, and animations.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local Trove = require(ReplicatedStorage.Packages.trove)
local animate = require(game.StarterPlayer.StarterPlayerScripts.Utilities.animate)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local Slide = {}
Slide.__index = Slide

function Slide.new(movementController)
	local self = setmetatable({}, Slide)

	self._movementController = movementController
	self._trove = Trove.new()
	self._config = MovementConfig.Slide
	self._keybinds = MovementConfig.Keybinds
	self._character = playerMarshaller.get().Character
	self._humanoid = self._character:WaitForChild("Humanoid")
	self._isSliding = false
	self._onCooldown = false
	self._slideTrove = nil

	self._raycastParams = RaycastParams.new()
	self._raycastParams.FilterDescendantsInstances = { self._character }
	self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	animate.loadAnimation("slide", MovementConfig.Animations.Slide)

	self:_connectInputs()

	return self
end

function Slide:_connectInputs()
	self._trove:Connect(UserInputService.InputBegan, function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if input.KeyCode == self._keybinds.Slide then
			self:Start()
		elseif input.KeyCode == self._keybinds.CancelSlide then
			self:Cancel()
		end
	end)
end

function Slide:Start()
	if self._isSliding or self._onCooldown then
		return
	end

	local direction: Vector3 = -self._character.PrimaryPart.CFrame.UpVector :: Vector3 * 10
	local ray = workspace:Raycast(self._character.PrimaryPart.Position, direction, self._raycastParams)
	if not ray then
		return
	end

	self._isSliding = true
	self._onCooldown = true
	task.delay(self._config.Cooldown, function()
		self._onCooldown = false
	end)

	self._slideTrove = Trove.new()

	self._humanoid.HipHeight = MovementConfig.HipHeight.Slide
	animate.play("slide", 0.25)

	local attachment = self._slideTrove:Construct(Instance, "Attachment")
	attachment.Parent = self._character.PrimaryPart

	local velocity = self._slideTrove:Construct(Instance, "LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = self._character.PrimaryPart.CFrame.LookVector * self._config.BaseSpeed
	velocity.Parent = self._character.PrimaryPart

	local align = self._slideTrove:Construct(Instance, "AlignOrientation")
	align.Attachment0 = attachment
	align.MaxTorque = Vector3.new(3e5, 3e5, 3e5)
	align.Responsiveness = 200
	align.Parent = self._character.PrimaryPart

	self._slideVelocity = velocity
	self._slideAlign = align
	self._currentMultiplier = 1
end

function Slide:Stop()
	if not self._isSliding then
		return
	end
	self._isSliding = false

	self._humanoid.HipHeight = MovementConfig.HipHeight.Normal
	animate.stop("slide")

	if self._slideTrove then
		self._slideTrove:Destroy()
		self._slideTrove = nil
	end
end

function Slide:Cancel()
	if not self._isSliding then
		return
	end

	local cancelMultiplier = self._currentMultiplier
	self:Stop()

	local vectorVelocity: Vector3 = (
		self._character.PrimaryPart.CFrame.LookVector :: Vector3
		* (self._config.CancelPushForward :: number * cancelMultiplier :: number)
	)
		+ (self._character.PrimaryPart.CFrame.UpVector :: Vector3 * self._config.CancelPushUpward :: number)

	local pushVelocity = Instance.new("LinearVelocity")
	pushVelocity.Parent = self._character.PrimaryPart
	pushVelocity.Attachment0 = Instance.new("Attachment", self._character.PrimaryPart :: BasePart)
	pushVelocity.MaxForce = math.huge
	pushVelocity.VectorVelocity = vectorVelocity

	task.delay(0.2, function()
		if pushVelocity and pushVelocity.Parent then
			pushVelocity:Destroy()
		end
	end)
end

function Slide:Update(deltaTime: number)
	if not self._isSliding then
		return
	end

	local direction = -self._character.PrimaryPart.CFrame.UpVector :: Vector3 * 10
	local ray = workspace:Raycast(self._character.PrimaryPart.Position, direction, self._raycastParams)

	if not ray then
		self:Stop()
		return
	end

	-- Align character to slope
	local currentRightVector = self._character.PrimaryPart.CFrame.RightVector
	local upVector = ray.Normal
	local newFacialVector = currentRightVector:Cross(upVector)
	local translation =
		CFrame.fromMatrix(self._character.PrimaryPart.Position, currentRightVector, upVector, newFacialVector)
	if self._slideAlign then
		(self._slideAlign :: AlignOrientation).CFrame = translation
	end

	-- Update velocity based on slope
	local verticalChange = ray.Normal.Y
	if verticalChange > 0.99 then -- Flat ground
		self._currentMultiplier =
			math.max(0, self._currentMultiplier - (self._config.SpeedLossFlat :: number * deltaTime))
	elseif verticalChange < 0.99 and verticalChange > 0 then -- Downhill
		self._currentMultiplier =
			math.min(2, self._currentMultiplier + (self._config.SpeedGainDown :: number * deltaTime))
	else -- Uphill
		self._currentMultiplier =
			math.max(0, self._currentMultiplier - (self._config.SpeedLossUp :: number * deltaTime))
	end

	if self._slideVelocity :: LinearVelocity then
		self._slideVelocity.VectorVelocity = self._character.PrimaryPart.CFrame.LookVector :: Vector3
			* (self._config.BaseSpeed :: number * self._currentMultiplier :: number)
	end

	if self._currentMultiplier <= 0 then
		self:Stop()
	end
end

function Slide:Destroy()
	self:Stop()
	self._trove:Destroy()
end

return Slide
