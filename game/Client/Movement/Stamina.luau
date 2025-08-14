--!strict
--[=[
	Stamina
	@class Stamina

	Manages the player's stamina, including regeneration and UI updates.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local player = playerMarshaller.get()
local character = player.Character

local Stamina = {}
Stamina.__index = Stamina

local max_stamina = 100

function Stamina.new(movementController)
	local self = setmetatable({}, Stamina)

	self._movementController = movementController
	self._trove = require(ReplicatedStorage.Packages.trove).new()

	self._regeneration_delay = 2.5
	self._regeneration_rate = 10
	self._lastDrain = 0
	self._isRegenerating = false

	character:SetAttribute("Stamina", max_stamina)
	character:SetAttribute("AntiRegenerate", false)

	self:_createUI()

	return self
end

function Stamina:_createUI()
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
	end)
end

function Stamina:Update(deltaTime: number)
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

function Stamina:Destroy()
	self._trove:Destroy()
end

return Stamina
