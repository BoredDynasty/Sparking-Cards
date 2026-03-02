--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)
local brick_particle = require(StarterPlayer.StarterPlayerScripts.Gameplay["brick-particle"])

local input = require(ReplicatedStorage.Packages.input)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local speed_lines = require(ReplicatedStorage.Effects["speed-lines"])
local spr = require(ReplicatedStorage.Modules.spr)
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

local rate_limit = ratelimit(3, 0.5)

local run_animations = {
	121791117079049,
	111852268003786,
}

-- TODO) make this in compliance with user data.
-- and the players skill tree.
local running_speed = 15

local function onBegan()
	if is_sprinting then
		return
	end

	local current_stamina = character:GetAttribute("Stamina") :: number or 0

	character:SetAttribute("AntiRegenerate", true)

	animate.play(run_animations[1], 0.25)

	humanoid.WalkSpeed += running_speed
end

local function onEnded()
	-- have we already stopped sprinting?
	if not is_sprinting then
		return
	end

	is_sprinting = false

	-- allow for regeneration
	character:SetAttribute("AntiRegenerate", false)

	local animation_id = 111852268003786
	animate.stop(run_animations[1], 0.25)

	-- reset walkspeed

	humanoid.WalkSpeed -= running_speed
end

function module:Update(delta_time: number)
	-- have we already stopped sprinting?
	if not is_sprinting then
		return
	end

	local move_direction = humanoid.MoveDirection

	-- are we even moving?
	if move_direction.Magnitude <= 0 then
		return
	end

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
