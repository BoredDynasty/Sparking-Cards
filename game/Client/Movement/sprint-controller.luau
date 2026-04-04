--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local skill_functions = require(ReplicatedStorage.Modules["skill-functions"])
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

player.CharacterAdded:Connect(setupCharacter)

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

local function updateInternalValues()
	-- get how many stamina upgrades the player has and apply it
	local profile = fetchProfile()
	if not profile then
		print("no profile found for sprint controller, defaulting to 0 upgrades.")
		return
	end

	local stamina_upgrades = skill_functions:GetTechniquesUnlocked(profile, "Stamina")
	if stamina_upgrades > 0 then
		local multiplier = skill_functions:GetTotalMultiplierFromTechniques(profile, "Stamina")
		max_stamina = max_stamina * (1 + multiplier)

		print("max stamina after applying upgrades: ", max_stamina)
	else
		print("no stamina upgrades found, using default max stamina: ", max_stamina)
	end
end

task.spawn(updateInternalValues)

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

		if humanoid.MoveDirection == Vector3.zero then
			is_sprinting = false

			return
		end

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
		-- smoothly transition back to normal speed when stopping sprinting
		humanoid.WalkSpeed = humanoid.WalkSpeed - ((humanoid.WalkSpeed - 12) * 0.1)
	end
end

return module
