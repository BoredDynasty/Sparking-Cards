--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local trove = require(ReplicatedStorage.Packages.trove)

-- sprint-controller.luau
-- this single module has had a million rewrites
-- send help

local module = {}

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root_part = humanoid.RootPart :: BasePart

local _trove = trove.new()

local max_stamina = 100
local is_sprinting = false

local character_trove = _trove:Extend()

local function setupCharacter(new_character: Model)
	character_trove:Clean()
	character = new_character
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	root_part = humanoid.RootPart :: BasePart

	is_sprinting = false

	character_trove:Connect(humanoid.Died, function()
		is_sprinting = false
	end)
end

local function sigmoid(x: number)
	return 1 / (1 + math.exp(-x))
end

local function getSpeedFromStamina(current_stamina: number): number
	local x = (current_stamina - 50) * 0.1

	return sigmoid(x)
end

-- TODO) we are going to add a keybind configuration in the player profile.
local default_keybinds = {
	sprint = Enum.KeyCode.LeftShift,
}

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if humanoid.MoveDirection == Vector3.zero then
		return
	end

	if input.KeyCode == default_keybinds.sprint then
		is_sprinting = true
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == default_keybinds.sprint then
		is_sprinting = false
	end
end)

function module:Update(delta_time: number)
	if is_sprinting then
		-- 1. calculate stamina deduction
		-- 2. deduct stamina from character using :SetAttribute
		-- 3. set walkspeed

		local current_stamina = character:GetAttribute("Stamina") :: number or 0
		-- TODO) add a skill tree multipliier for stamina and drain rate.
		local drain_rate = MovementConfig.Sprint.StaminaDrainRate

		local new_stamina = math.max(0, current_stamina - (drain_rate * delta_time))

		character:SetAttribute("Stamina", new_stamina)
		character:SetAttribute("AntiRegenerate", true)

		local speed_multiplier = getSpeedFromStamina(new_stamina)
		humanoid.WalkSpeed = 12 + (speed_multiplier * 24)
	else
		-- allow for regeneration when not sprinting
		-- the stamina-controller already handles most of this

		character:SetAttribute("AntiRegenerate", false)
	end
end

return module
