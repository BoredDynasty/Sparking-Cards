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
local Signal = require(ReplicatedStorage.Parent.Shared.Replicated.Dependencies.SignalPlus)

local class = {}
class.__index = class

export type self = {
	_movementController: any,
	_trove: Trove.Trove,
	_config: any,
	_keybinds: any,
	_character: Model,
	_humanoid: Humanoid,
	_isSliding: boolean,
	_onCooldown: boolean,
	_slideTrove: Trove.Trove?,
	_raycastParams: RaycastParams,
	_slideVelocity: LinearVelocity?,
	_slideAlign: AlignOrientation?,
	_currentMultiplier: number,

	slideStarted: Signal.Signal,
	slideStopped: Signal.Signal,
}

function class.new(movementController): setmetatable<self, typeof(class)>
	local self = setmetatable({
		_movementController = movementController,
		_trove = Trove.new(),
		_config = MovementConfig.Slide,
		_keybinds = MovementConfig.Keybinds,
		_character = playerMarshaller.get().Character,
		_humanoid = playerMarshaller.get().Character:WaitForChild("Humanoid"),
		_isSliding = false,
		_onCooldown = false,
		_slideTrove = nil,

		_raycastParams = RaycastParams.new(),

		slideStarted = Signal.new(),
		slideStopped = Signal.new(),
	}, class)

	self._raycastParams.FilterDescendantsInstances = { self._character }
	self._raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	animate.loadAnimation("slide", MovementConfig.Animations.Slide)

	self:_connectInputs()

	return self
end

function class:_connectInputs(self: self)
	self._trove:Connect(UserInputService.InputBegan, function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if input.KeyCode == self._keybinds.Slide then
			self:start()
		elseif input.KeyCode == self._keybinds.CancelSlide then
			self:cancel()
		end
	end)
end

function class:start(self: self)
	if self._isSliding or self._onCooldown then
		return
	end

	local direction: Vector3 = -self._character.PrimaryPart.CFrame.UpVector :: Vector3 * 10
	local ray = workspace:Raycast(self._character.PrimaryPart.Position, direction, self._raycastParams)
	if not ray then
		return
	end

	local settings = self._movementController:get("DirectionalSettings"):getSettings("Slide", self._humanoid.MoveDirection)

	self._isSliding = true
	self._onCooldown = true
	task.delay(settings.Cooldown, function()
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
	velocity.VectorVelocity = self._character.PrimaryPart.CFrame.LookVector * settings.BaseSpeed
	velocity.Parent = self._character.PrimaryPart

	local align = self._slideTrove:Construct(Instance, "AlignOrientation")
	align.Attachment0 = attachment
	align.MaxTorque = Vector3.new(3e5, 3e5, 3e5)
	align.Responsiveness = 200
	align.Parent = self._character.PrimaryPart

	self._slideVelocity = velocity
	self._slideAlign = align
	self._currentMultiplier = 1

	self.slideStarted:Fire()
end

function class:stop(self: self)
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

	self.slideStopped:Fire()
end

function class:cancel(self: self)
	if not self._isSliding then
		return
	end

	local settings = self._movementController:get("DirectionalSettings"):getSettings("Slide", self._humanoid.MoveDirection)
	local cancelMultiplier = self._currentMultiplier
	self:stop()

	local vectorVelocity: Vector3 = (
		self._character.PrimaryPart.CFrame.LookVector :: Vector3
		* (settings.CancelPushForward :: number * cancelMultiplier :: number)
	)
		+ (self._character.PrimaryPart.CFrame.UpVector :: Vector3 * settings.CancelPushUpward :: number)

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

function class:update(self: self, deltaTime: number)
	if not self._isSliding then
		return
	end

	local settings = self._movementController:get("DirectionalSettings"):getSettings("Slide", self._humanoid.MoveDirection)
	local direction = -self._character.PrimaryPart.CFrame.UpVector :: Vector3 * 10
	local ray = workspace:Raycast(self._character.PrimaryPart.Position, direction, self._raycastParams)
	-- TODO) make this more performant

	if not ray then
		self:stop()
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
			math.max(0, self._currentMultiplier - (settings.SpeedLossFlat :: number * deltaTime))
	elseif verticalChange < 0.99 and verticalChange > 0 then -- Downhill
		self._currentMultiplier =
			math.min(2, self._currentMultiplier + (settings.SpeedGainDown :: number * deltaTime))
	else -- Uphill
		self._currentMultiplier =
			math.max(0, self._currentMultiplier - (settings.SpeedLossUp :: number * deltaTime))
	end

	if self._slideVelocity :: LinearVelocity then
		self._slideVelocity.VectorVelocity = self._character.PrimaryPart.CFrame.LookVector :: Vector3
			* (settings.BaseSpeed :: number * self._currentMultiplier :: number)
	end

	if self._currentMultiplier <= 0 then
		self:stop()
	end
end

function class:destroy(self: self)
	self:stop()
	self._trove:Destroy()
	self.slideStarted:Destroy()
	self.slideStopped:Destroy()
end

return class
