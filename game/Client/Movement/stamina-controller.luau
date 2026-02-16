--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local observer = require(ReplicatedStorage.Utility.observer)
local physical_bar = require(StarterPlayer.StarterPlayerScripts.Components["physical-bar"])
local spr = require(ReplicatedStorage.Modules.spr)
local sway = require(StarterPlayer.StarterPlayerScripts.Interface.sway)
local trove = require(ReplicatedStorage.Packages.trove)

-- stamina-controller.luau

local _trove = trove.new()

local controller = {}
controller._trove = _trove

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root_part = character:WaitForChild("HumanoidRootPart") :: BasePart

local max_stamina = 100
local regeneration_delay = 1.5
local regeneration_rate = 15
local last_drain = 0
local is_regenerating = false

local bar_size = UDim2.fromScale(0.5, 0.97)

local bar = physical_bar.new()
local previous_stamina = max_stamina
local character_trove = _trove:Extend()

local function setupCharacter(new_character: Model)
	character_trove:Clean()

	character = new_character
	character:SetAttribute("Stamina", max_stamina)
	character:SetAttribute("AntiRegenerate", false)

	if bar then
		bar:Destroy()
	end

	bar = physical_bar.new()
	bar:SetAdornee(root_part)

	previous_stamina = max_stamina
	last_drain = 0
	is_regenerating = false

	character_trove:Connect(character:GetAttributeChangedSignal("Stamina"), function()
		local stamina = character:GetAttribute("Stamina") :: number?
		if not stamina then
			return
		end

		if stamina < previous_stamina then
			last_drain = 0
			is_regenerating = false
		end

		previous_stamina = stamina

		local percentage = stamina / max_stamina

		task.wait(1.5)

		bar:SetValue(percentage)
	end)
end

if character then
	setupCharacter(character)
end

player.CharacterAdded:Connect(setupCharacter)

function controller:Update(deltaTime: number)
	local anti_regenerate = character:GetAttribute("AntiRegenerate") :: boolean
	local current_stamina = character:GetAttribute("Stamina") :: number or max_stamina

	if anti_regenerate then
		last_drain = 0
		is_regenerating = false
	else
		last_drain += deltaTime

		if last_drain >= regeneration_delay then
			is_regenerating = true
		end
	end

	if is_regenerating and current_stamina < max_stamina then
		local regenerate_amount = regeneration_rate * deltaTime

		current_stamina = math.min(current_stamina + regenerate_amount, max_stamina)

		character:SetAttribute("Stamina", current_stamina)
	end
end

return controller
