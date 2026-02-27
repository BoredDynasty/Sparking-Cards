--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)

local input = require(ReplicatedStorage.Packages.input)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local speed_lines = require(ReplicatedStorage.Effects["speed-lines"])
local trove = require(ReplicatedStorage.Packages.trove)

-- sprint-controller.luau

local _trove = trove.new()

local module = {}
module._trove = _trove

local keyboard = input.Keyboard.new()

_trove:Add(keyboard :: any)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root_part = humanoid.RootPart :: BasePart
local root_joint = root_part:WaitForChild("RootJoint") :: Motor6D

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

if character then
	setupCharacter(character)
end

local rate_limit = ratelimit(1, 0.5)

local run_animations = {
	121791117079049,
	111852268003786,
}

-- TODO) make this in compliance with user data.
-- and the players skill tree.
local running_speed = 32
local acceleration = 60
local deceleration = 80

local rotation_power_back = 0.5
local rotation_power_left = 0.5
local rotation_speed = 0.1
local original_c0 = root_joint.C0

for i, id in ipairs(run_animations) do
	animate.load(`rbxassetid://{id}`)
end

local function onBegan()
	if not rate_limit(player.UserId) then
		return
	end

	-- are we even in a running motion?
	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		return
	end

	local stamina = character:GetAttribute("Stamina") :: number or 0

	-- are we out of breath?
	if stamina <= 0 then
		return
	end

	-- are we even moving?
	if humanoid.MoveDirection.Magnitude <= 0 then
		return
	end

	is_sprinting = true
	character:SetAttribute("IsSprinting", is_sprinting)

	-- remove regeneration
	character:SetAttribute("AntiRegenerate", true)

	speed_lines:On()

	-- play a random animation

	local animation_id = run_animations[math.random(1, #run_animations)]
	animate.play(`rbxassetid://{animation_id}`)
end

local function onEnded()
	-- have we already stopped sprinting?
	if not is_sprinting then
		return
	end

	is_sprinting = false
	character:SetAttribute("IsSprinting", is_sprinting)

	-- allow for regeneration
	character:SetAttribute("AntiRegenerate", false)

	animate.stop_all()

	speed_lines:Off()
end

function module:Update(delta_time: number)
	-- have we already stopped sprinting?
	if not is_sprinting then
		return
	end

	-- are we even running?
	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		onEnded()

		return
	end

	local move_direction = humanoid.MoveDirection

	-- are we even moving?
	if move_direction.Magnitude <= 0 then
		return
	end

	local walk_speed = humanoid.WalkSpeed

	if walk_speed < running_speed then
		humanoid.WalkSpeed += (acceleration * delta_time)
	else
		humanoid.WalkSpeed -= (deceleration * delta_time)
	end

	-- tilt the character
	local root_part_cf = root_part.CFrame

	local dot_back = root_part_cf.LookVector:Dot(move_direction)
	local dot_left = root_part_cf.RightVector:Dot(move_direction)

	root_joint.C0:Lerp(
		original_c0 * CFrame.Angles(dot_back * rotation_power_back, dot_left * rotation_power_left, 0),
		rotation_speed
	)

	-- drain stamina
	local current_stamina = character:GetAttribute("Stamina") :: number or 0

	-- TODO) add a skill tree multipliier for stamina and drain rate.
	local drain_rate = MovementConfig.Sprint.StaminaDrainRate

	local new_stamina = math.max(0, current_stamina - (drain_rate * delta_time))

	character:SetAttribute("Stamina", new_stamina)

	-- if not enough stamina or not moving, stop.
	if new_stamina <= 0 or humanoid.MoveDirection.Magnitude == 0 then
		onEnded()
	end
end

player.CharacterAdded:Connect(setupCharacter);
(keyboard.KeyDown :: RBXScriptSignal<Enum.KeyCode, boolean>):Connect(function(key, processed)
	if key ~= MovementConfig.Keybinds.Sprint then
		return
	end

	if processed then
		return
	end

	onBegan()
end);
(keyboard.KeyUp :: RBXScriptSignal<Enum.KeyCode, boolean>):Connect(function(key, processed)
	if key ~= MovementConfig.Keybinds.Sprint then
		return
	end

	if processed then
		return
	end

	onEnded()
end)

return module
