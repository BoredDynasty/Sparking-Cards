--!strict
--[=[
	Stamina
	@class Stamina

	Manages the player's stamina, including regeneration and UI updates.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local Signal = require(ReplicatedStorage.Parent.Shared.Replicated.Dependencies.SignalPlus)
local Trove = require(ReplicatedStorage.Packages.trove)

local player = playerMarshaller.get()
local character = player.Character

local class = {}
class.__index = class

local max_stamina = 100

export type self = {
	_movementController: any,
	_trove: Trove.Trove,
	_regeneration_delay: number,
	_regeneration_rate: number,
	_lastDrain: number,
	_isRegenerating: boolean,

	staminaChanged: Signal.Signal,
}

function class.new(movementController): setmetatable<self, typeof(class)>
	local self = setmetatable({
		_movementController = movementController,
		_trove = Trove.new(),
		_regeneration_delay = 2.5,
		_regeneration_rate = 10,
		_lastDrain = 0,
		_isRegenerating = false,

		staminaChanged = Signal.new(),
	}, class)

	character:SetAttribute("Stamina", max_stamina)
	character:SetAttribute("AntiRegenerate", false)

	self:_createUI()

	return self
end

function class:_createUI(self: self)
	type interface = BillboardGui & {
		Frame: CanvasGroup & {
			Bar: Frame,
			TextLabel: TextLabel,
		},
	}
	local sprintBar = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("SprintBar") :: interface
	sprintBar = self._trove:Clone(sprintBar)
	sprintBar.Parent = character
	sprintBar.Adornee = character.PrimaryPart

	local barSize = UDim2.fromScale(0.5, 0.97)
	self._trove:Connect(character:GetAttributeChangedSignal("Stamina"), function()
		local stamina = character:GetAttribute("Stamina") :: number
		if not stamina then
			return
		end
		local percentage = stamina / max_stamina
		local scale = UDim2.fromScale(barSize.X.Scale, barSize.Y.Scale * percentage)
		TweenPlus(sprintBar.Frame.Bar, {
			Size = scale,
		}, {
			EasingDirection = "Out",
			EasingStyle = "Back",
		}):Start()
		self.staminaChanged:Fire(stamina)
	end)
end

function class:update(self: self, deltaTime: number)
	local isAntiRegenerate = character:GetAttribute("AntiRegenerate") :: boolean or false
	local currentStamina = character:GetAttribute("Stamina") :: number? or max_stamina

	if isAntiRegenerate then
		self._lastDrain = 0
		self._isRegenerating = false
	else
		self._lastDrain += deltaTime
		if self._lastDrain >= self._regeneration_delay then
			self._isRegenerating = true
		end
	end

	if self._isRegenerating and currentStamina < max_stamina then
		local regenAmount = self._regeneration_rate :: number * deltaTime
		currentStamina = math.min(currentStamina + regenAmount, max_stamina)
		character:SetAttribute("Stamina", currentStamina)
	end
end

function class:destroy(self: self)
	self._trove:Destroy()
	self.staminaChanged:Destroy()
end

return class
