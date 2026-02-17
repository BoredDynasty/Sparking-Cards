--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local input = require(ReplicatedStorage.Packages.input)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local speed_lines = require(ReplicatedStorage.Effects["speed-lines"])
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- sprint-controller.luau

local _trove = trove.new()

local controller = {}
controller._trove = _trove

local keyboard = input.Keyboard.new()

_trove:Add(keyboard :: any)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root_part = humanoid.RootPart :: BasePart

local is_sprinting = false
local character_trove = _trove:Extend()

local current_speed = 14
local target_speed = 14
local previous_speed = 0

local sprint_speed = 32

local acceleration = 60
local deceleration = 80

local max_deceleration_tilt = math.rad(10)
local tilt_smoothing = 12
local current_tilt = 0

local root_joint = root_part:FindFirstChild("RootJoint") :: Motor6D?
local root_joint_c0 = if root_joint then root_joint.C0 else nil

local function resetTilt()
	current_tilt = 0

	if root_joint and root_joint_c0 then
		root_joint.C0 = root_joint_c0
	end
end

local function setupCharacter(new_character: Model)
	character_trove:Clean()
	character = new_character
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	root_part = humanoid.RootPart :: BasePart
	root_joint = root_part:FindFirstChild("RootJoint") :: Motor6D?
	root_joint_c0 = if root_joint then root_joint.C0 else nil
	is_sprinting = false
	previous_speed = 0
	resetTilt()

	character_trove:Connect(humanoid.Died, function()
		is_sprinting = false
	end)
end

if character then
	setupCharacter(character)
end

player.CharacterAdded:Connect(setupCharacter)

local rate_limit = ratelimit(1, 0.5)

animate.load(MovementConfig.Animations.Run.Id)

local function onBegan()
	if not rate_limit(player.UserId) then
		return
	end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		return
	end

	local stamina = character:GetAttribute("Stamina") :: number or 0

	if stamina <= 0 then
		return
	end

	if humanoid.MoveDirection.Magnitude == 0 then
		return
	end

	is_sprinting = true
	character:SetAttribute("AntiRegenerate", true)

	-- calculate animation speed
	local animation_speed = (current_speed / sprint_speed) * 2

	animate.stop(MovementConfig.Animations.Walk.Id)
	animate.play(MovementConfig.Animations.Run.Id, nil, nil, animation_speed)

	local lines = fetchAsset("speed_lines") :: speed_lines.lines

	speed_lines:On(workspace.CurrentCamera, lines)
end

local function onEnded()
	if not is_sprinting then
		return
	end

	is_sprinting = false

	character:SetAttribute("AntiRegenerate", false)

	animate.stop(MovementConfig.Animations.Run.Id)

	speed_lines:Off()
	resetTilt()
end

-- TODO) blend diagonal movement using forward/right weights.
function getRelativeMovementDirection()
	local move_direction = humanoid.MoveDirection
	if move_direction.Magnitude < 0.1 then
		return "Idle"
	end

	local forward_dot = move_direction:Dot(root_part.CFrame.LookVector)
	local right_dot = move_direction:Dot(root_part.CFrame.RightVector)

	if forward_dot > 0.5 then
		return "Forward"
	elseif forward_dot < -0.5 then
		return "Backward"
	elseif right_dot > 0 then
		return "Right"
	else
		return "Left"
	end
end

function controller:Update(deltaTime: number)
	if not is_sprinting then
		return
	end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		onEnded()

		return
	end

	if humanoid.MoveDirection.Magnitude == 0 then
		target_speed = 24
	end

	if current_speed < target_speed then
		current_speed += acceleration * deltaTime
	else
		current_speed -= deceleration * deltaTime
	end

	current_speed = math.clamp(current_speed, 14, sprint_speed)
	humanoid.WalkSpeed = current_speed

	local speed_drop = math.max(0, previous_speed - current_speed)
	local frame_deceleration = math.max(deltaTime * deceleration, 0.001)
	local deceleration_ratio = math.clamp(speed_drop / frame_deceleration, 0, 1)
	local target_tilt = max_deceleration_tilt * deceleration_ratio
	local blend_alpha = math.clamp(deltaTime * tilt_smoothing, 0, 1)

	current_tilt += (target_tilt - current_tilt) * blend_alpha

	if root_joint and root_joint_c0 then
		root_joint.C0 = root_joint_c0 * CFrame.Angles(current_tilt, 0, 0)
	end

	previous_speed = current_speed
	-- TODO) Add a ground check for different friction on surfaces.

	-- drain stamina
	local current_stamina = character:GetAttribute("Stamina") :: number or 0

	local drain_rate = MovementConfig.Sprint.StaminaDrainRate

	local new_stamina = math.max(0, current_stamina - (drain_rate * deltaTime))

	character:SetAttribute("Stamina", new_stamina)

	-- if not enough stamina or not moving, stop.
	if new_stamina <= 0 or humanoid.MoveDirection.Magnitude == 0 then
		onEnded()
	end
end

(keyboard.KeyDown :: RBXScriptSignal<Enum.KeyCode, boolean>):Connect(function(key)
	if key ~= MovementConfig.Keybinds.Sprint then
		return
	end

	onBegan()
end);
(keyboard.KeyUp :: RBXScriptSignal<Enum.KeyCode, boolean>):Connect(function(key)
	if key ~= MovementConfig.Keybinds.Sprint then
		return
	end

	onEnded()
end)

return controller
