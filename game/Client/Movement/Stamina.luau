--!strict

-- Stamina.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local player = playerMarshaller.get()
local character = player.Character

local Stamina = {}

function Stamina:initialize()
	local regeneration_delay = 2.5
	-- time before stamina starts regenerating
	local regeneration_rate = 10
	-- regeneration rate per second
	local max_stamina = 100
	-- maximum stamina value
	local lastDrain = 0
	local isRegenerating = false

	-- Cache for attributes
	local currentStamina: number = character:GetAttribute("Stamina") :: number or max_stamina
	local isAntiRegenerate = false

	-- Set up attribute changed listeners outside the Heartbeat
	character:GetAttributeChangedSignal("Stamina"):Connect(function()
		currentStamina = character:GetAttribute("Stamina") :: number
	end)

	character:GetAttributeChangedSignal("AntiRegenerate"):Connect(function()
		isAntiRegenerate = character:GetAttribute("AntiRegenerate") :: boolean
	end)

	-- Accumulator for stamina changes
	local staminaAccumulator = 0
	-- local lastUpdate = tick()

	RunService.Heartbeat:Connect(function(deltaTime: number)
		--[[
         were using this chunk of code to prevent the
         stamina from regenerating too fast or
         while it's being drained
      ]]
		if isAntiRegenerate then
			lastDrain = 0
			isRegenerating = false
		else
			lastDrain += deltaTime
			if lastDrain >= regeneration_delay then
				isRegenerating = true
			end
		end
		if isRegenerating and currentStamina < max_stamina then
			local regenAmount = regeneration_rate * deltaTime
			staminaAccumulator += regenAmount
			currentStamina = math.min(currentStamina + regenAmount, max_stamina)
			-- Only update attribute if accumulated change is significant
			if staminaAccumulator >= 1 or currentStamina == max_stamina then
				character:SetAttribute("Stamina", currentStamina)
				staminaAccumulator = 0
			end
		end
	end)
	local changed = character:GetAttributeChangedSignal("Stamina")
	-- interface changes
	type interface = BillboardGui & {
		Frame: CanvasGroup & {
			Bar: Frame,
			TextLabel: TextLabel,
		},
	}
	local sprintBar = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("SprintBar") :: interface
	sprintBar = sprintBar:Clone()
	sprintBar.Parent = character
	sprintBar.Adornee = character.PrimaryPart

	local barSize = UDim2.fromScale(0.5, 0.97)
	changed:Connect(function()
		local stamina = character:GetAttribute("Stamina") :: number
		if not stamina then
			return
		end
		local percentage = stamina / max_stamina
		-- make it fit 0.97 y scale
		-- sprintBar.Frame.Bar.Size = UDim2.fromScale(barSize.X.Scale, barSize.Y.Scale * percentage)
		local scale = UDim2.fromScale(barSize.X.Scale, barSize.Y.Scale * percentage)
		TweenPlus(sprintBar.Frame.Bar, {
			Size = scale,
		}, {
			EasingDirection = "Out",
			EasingStyle = "Back",
		}):Start()
	end)
end
return Stamina
