--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(ReplicatedStorage.ClientModules.Utilities.animate)
local fetchProfile = require(ReplicatedStorage.ClientModules.Utilities.fetchProfile)
local lerp = require(ReplicatedStorage.ClientModules.Utilities.lerp)
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
local unlocked_bhop = false

local character_trove = _trove:Extend()

local sprint_animation = 111852268003786

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
		print("no profile found for sprint controller; defaulting to 0 upgrades.")
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

	local bhop_upgrade = skill_functions:GetTechniquesUnlocked(profile, "Bunny Hop")
	if bhop_upgrade > 0 then
		unlocked_bhop = true
		print("player has unlocked bhop")
	else
		unlocked_bhop = false
		print("player has not unlocked bhop")
	end
end

task.spawn(function()
	updateInternalValues()

	-- todo) listen for changes in the profile and update values accordingly
end)

-- allow for bunny hopping

local ground_acceleration = 16
local ground_deceleration = 12
local air_acceleration = 1

local player_velocity = Vector3.zero

local linear_velocity = Instance.new("LinearVelocity")
linear_velocity.Attachment0 = root_part:WaitForChild("RootAttachment") :: Attachment
linear_velocity.MaxForce = math.huge
linear_velocity.RelativeTo = Enum.ActuatorRelativeTo.World
linear_velocity.Parent = root_part
linear_velocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
linear_velocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)

local function move(direction: Vector3, speed: number, rate_1: number, rate_2: number)
	local current_velocity = player_velocity
	local target_speed = direction * speed

	local add = (target_speed - current_velocity)

	local rate = if current_velocity.Magnitude < speed or direction.Magnitude > 0 then rate_1 else rate_2

	player_velocity += add * rate * RunService.Heartbeat:Wait()
end

local function airMove(wish_direction: Vector3, wish_speed: number, acceleration: number)
	local current_velocity = player_velocity:Dot(wish_direction)
	local add = wish_speed - current_velocity

	if add <= 0 then
		return
	end

	local rate = add * (RunService.Heartbeat:Wait() * wish_speed)
	rate = math.clamp(rate, -0.001, add)

	player_velocity += rate * wish_direction
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if humanoid.MoveDirection == Vector3.zero then
		return
	end

	if input.KeyCode == default_keybinds.sprint then
		is_sprinting = true

		animate.stop(MovementConfig.Animations.Walk.Id)
		animate.play(sprint_animation)
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
		local drain_rate = MovementConfig.Sprint.StaminaDrainRate

		local new_stamina = math.max(0, current_stamina - (drain_rate * delta_time))

		character:SetAttribute("Stamina", new_stamina)
		character:SetAttribute("AntiRegenerate", true)

		local speed_multiplier = getSpeedFromStamina(new_stamina)
		humanoid.WalkSpeed = 12 + (speed_multiplier * 24)

		local track = animate.getTrack(sprint_animation)
		if track then
			track:AdjustSpeed(math.clamp(humanoid.WalkSpeed, 0, 1))
		end
	else
		-- allow for regeneration when not sprinting
		-- the stamina-controller already handles most of thisd

		character:SetAttribute("AntiRegenerate", false)
		-- smoothly transition back to normal speed when stopping sprinting
		humanoid.WalkSpeed = lerp(humanoid.WalkSpeed, 14, 0.05)
		local track = animate.getTrack(sprint_animation)
		if track then
			track:AdjustSpeed(math.clamp(humanoid.WalkSpeed, 0, 1))
		end

		animate.stop(sprint_animation, 1)
	end

	if not unlocked_bhop then
		return
	end

	-- bunnyhop logic
	for i, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0, 100, 100)
		end
	end

	humanoid.UseJumpPower = true

	local grounded = humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
	if grounded then
		move(humanoid.MoveDirection, humanoid.WalkSpeed, ground_acceleration, ground_deceleration)
	else
		airMove(humanoid.MoveDirection, humanoid.WalkSpeed, air_acceleration)
	end

	if not (humanoid:GetState() == Enum.HumanoidStateType.Climbing) then
		linear_velocity.PlaneVelocity = Vector2.new(player_velocity.X, player_velocity.Z)
	else
		linear_velocity.PlaneVelocity = Vector2.zero
	end
end

return module
