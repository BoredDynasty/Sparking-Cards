--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local camera_controller = require(StarterPlayer.StarterPlayerScripts.Camera["camera-controller"])
local observer = require(ReplicatedStorage.Utility.observer)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- over-shoulder.luau
-- a smooth-shiftlock!

local module = {}
module.Toggled = SignalPlus()

local player = Players.LocalPlayer
local camera = workspace.Camera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root = character:WaitForChild("HumanoidRootPart") :: BasePart
local head = character:WaitForChild("Head") :: BasePart

local config = {
	-- does the character rotate smoothly?
	smooth_rotation = true,
	rotation_speed = 3,
	spring_damper = 0.7,
	transition_in_speed = 10,
	transition_out_speed = 14,
	camera_offset = Vector3.new(1.75, 0.25, 0),

	mouse_icon = "rbxasset://textures/MouseLockedCursor.png",

	keybinds = { Enum.KeyCode.RightShift },
}

local active = observer.new(false)

local _trove = trove.new()

-- internal state
local transition_alpha = 0

local current_cframe = camera.CFrame

local previous_camera_type = camera.CameraType
local previous_mouse_icon = UserInputService.MouseIconEnabled
local previous_mouse_behavior = UserInputService.MouseBehavior

local function set_mouse_locked(locked: boolean)
	if locked then
		UserInputService.MouseIconEnabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		UserInputService.MouseIconEnabled = previous_mouse_icon
		UserInputService.MouseBehavior = previous_mouse_behavior
	end
end

local function update_camera(dt: number)
	-- update transition alpha
	if active:Get() then
		transition_alpha = math.clamp(transition_alpha + config.transition_in_speed * dt, 0, 1)
	else
		transition_alpha = math.clamp(transition_alpha - config.transition_out_speed * dt, 0, 1)
	end

	-- if fully inactive, restore default camera and return
	if transition_alpha <= 0 then
		if camera.CameraType == Enum.CameraType.Scriptable then
			camera.CameraType = previous_camera_type
		end
		return
	end

	-- ensure we are in scriptable mode while transitioning/active
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		previous_camera_type = camera.CameraType

		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- calculate desired camera position and orientation
	local offset_world = root.CFrame:VectorToWorldSpace(config.camera_offset)
	local desired_pos = head.Position + offset_world

	-- look target is slightly above root to center on torso
	local look_target = root.Position + Vector3.new(0, 1.5, 0)

	local desired_cframe = CFrame.new(desired_pos, look_target)

	-- smooth interpolation of camera cframe based on transition_alpha
	local lerp_alpha = 1 - math.exp(-(config.transition_in_speed * transition_alpha) * dt)
	current_cframe = current_cframe:Lerp(desired_cframe, lerp_alpha)

	camera.CFrame = current_cframe

	-- optional smooth character rotation to face camera forward
	if config.smooth_rotation and active:Get() then
		local cam_forward = (look_target - desired_pos).Unit

		local target_yaw = math.atan2(cam_forward.X, cam_forward.Z)

		-- get current root yaw
		local _, _, rz = root.CFrame:ToOrientation()
		-- compute shortest angle difference
		local diff = target_yaw - rz
		while diff > math.pi do
			diff -= 2 * math.pi
		end
		while diff < -math.pi do
			diff += 2 * math.pi
		end

		local ang = rz + diff * math.clamp(config.rotation_speed * dt, 0, 1)

		local pos = root.Position

		root.CFrame = CFrame.new(pos) * CFrame.Angles(0, ang, 0)
	end
end

-- register the camera updater with the global camera controller
camera_controller.new("over-shoulder", function(dt)
	update_camera(dt)
end)

-- input handling to toggle shiftlock
_trove:Connect(UserInputService.InputBegan, function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		for _, key in ipairs(config.keybinds) do
			if input.KeyCode == key then
				local new_state = not active:Get()

				active:Set(new_state)

				set_mouse_locked(new_state)

				-- notify listeners
				if module.Toggled and typeof(module.Toggled.Fire) == "function" then
					module.Toggled:Fire(new_state)
				end

				break
			end
		end
	end
end)

-- cleanup on character removal or humanoid death
local function cleanup()
	set_mouse_locked(false)
	if camera and camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = previous_camera_type
	end
end

humanoid.Died:Connect(function()
	active:Set(false)
	cleanup()
end)

-- expose API
function module.Enable()
	active:Set(true)
	set_mouse_locked(true)
	if module.Toggled and typeof(module.Toggled.Fire) == "function" then
		module.Toggled:Fire(true)
	end
end

function module.Disable()
	active:Set(false)
	set_mouse_locked(false)
	if module.Toggled and typeof(module.Toggled.Fire) == "function" then
		module.Toggled:Fire(false)
	end
end

function module.Toggle()
	if active:Get() then
		module.Disable()
	else
		module.Enable()
	end
end

-- tidy up trove when script is disabled/destroyed
_trove:Add(function()
	cleanup()
end)

return module
