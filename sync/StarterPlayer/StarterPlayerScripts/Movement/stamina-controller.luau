--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local physical_bar = require(StarterPlayer.StarterPlayerScripts.Components["physical-bar"])
local spr = require(ReplicatedStorage.Modules.spr)
local sway = require(StarterPlayer.StarterPlayerScripts.Interface.sway)

local observer = require(ReplicatedStorage.Utility.observer)
local trove = require(ReplicatedStorage.Packages.trove)

-- stamina-controller.luau

local _trove = trove.new()

local controller = {}
controller._trove = _trove

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local max_stamina = 100
local regeneration_delay = 2.5
local regeneration_rate = 10
local last_drain = observer.new(0)
local is_regenerating = observer.new(false)

local bar_size = UDim2.fromScale(0.5, 0.97)

character:SetAttribute("Stamina", max_stamina)
character:SetAttribute("AntiRegenerate", false)

local bar = physical_bar.new()
bar:SetAdornee(bar, character.PrimaryPart)

player.CharacterAdded:Connect(function(new_character)
	if new_character:FindFirstChild("SprintBar") then
		return
	end

	if bar then
		bar:Destroy()
	end

	bar = physical_bar.new()
	bar:SetAdornee(bar, character.PrimaryPart)
end)

_trove:Connect(character:GetAttributeChangedSignal("Stamina"), function()
	local stamina = character:GetAttribute("Stamina") :: number?
	if not stamina then
		return
	end

	local percentage = math.clamp(stamina / max_stamina, 0, 1)

	local scale = UDim2.fromScale(bar_size.X.Scale, bar_size.Y.Scale * percentage)

	bar:SetValue(bar, percentage)
end)

function controller:Update(deltaTime: number)
	local anti_regenerate = character:GetAttribute("AntiRegenerate") :: boolean
	local current_stamina = character:GetAttribute("Stamina") :: number or max_stamina

	-- TODO) fix this

	if anti_regenerate then
		last_drain:Set(0)
		is_regenerating:Set(false)
	else
		last_drain:Map(function(current)
			return current :: number * deltaTime
		end)

		if last_drain:Get() :: number >= regeneration_delay then
			is_regenerating:Set(true)
		end
	end

	if is_regenerating:Get() and current_stamina < max_stamina then
		local regenerate_amount = regeneration_rate * deltaTime

		current_stamina = math.min(current_stamina + regenerate_amount, max_stamina)

		character:SetAttribute("Stamina", current_stamina)
	end
end

return controller
