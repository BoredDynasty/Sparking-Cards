--!nonstrict

-- Stamina.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local characterUtility = require(ReplicatedStorage.Utility.character)

local player = Players.LocalPlayer
local character = characterUtility.get(player)

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
	RunService.Heartbeat:Connect(function(deltaTime: number)
		local stamina = character:GetAttribute("Stamina") :: number
		local anti_regenerate = character:GetAttribute("AntiRegenerate") :: boolean
		--[[
         were using this chunk of code to prevent the
         stamina from regenerating too fast or
         while it's being drained
      ]]
		if anti_regenerate then
			lastDrain = 0
			isRegenerating = false
		else
			lastDrain += deltaTime
			if lastDrain >= regeneration_delay then
				isRegenerating = true
			end
		end
		if isRegenerating and stamina < max_stamina then
			local regenAmount = regeneration_rate * deltaTime
			stamina = math.min(stamina + regenAmount, max_stamina)
			character:SetAttribute("Stamina", stamina)
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
		sprintBar.Frame.Bar.Size = UDim2.fromScale(barSize.X.Scale, barSize.Y.Scale * percentage)
		if stamina == 100 then
			TweenPlus(sprintBar.Frame, {
				GroupTransparency = 0,
			}, {
				Time = 1.5,
			}):Start()
		end
	end)
end
return Stamina
