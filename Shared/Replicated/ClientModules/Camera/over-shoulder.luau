--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local camera_controller = require(ReplicatedStorage.ClientModules.Camera["camera-controller"])

-- over-shoulder.luau
-- a smooth shiftlock-style over-shoulder camera

local module = {}
module.Toggled = SignalPlus() :: SignalPlus.Signal<boolean>
module.Enabled = false

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera :: Camera

local state = {
	enabled = false,
	yaw = 0,
	pitch = 0,
	look_height = 1.6,
	shoulder_height = 1.75,
	distance = 4.25,
	sensitivity = 0.0025,
	character = nil :: Model?,
	humanoid = nil :: Humanoid?,
	root = nil :: BasePart?,
	head = nil :: BasePart?,
}

local function resolve_character(): Model?
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local head = character:FindFirstChild("Head") :: BasePart?

	if not humanoid or not root or not head then
		return nil
	end

	state.character = character
	state.humanoid = humanoid
	state.root = root
	state.head = head

	return character :: Model?
end

local function update_character_refs()
	if resolve_character() then
		return
	end

	local character = player.Character or player.CharacterAdded:Wait()
	character:WaitForChild("Humanoid")
	character:WaitForChild("HumanoidRootPart")
	character:WaitForChild("Head")
	resolve_character()
end

local function update_camera(delta_time: number): CFrame
	if not state.enabled or not camera then
		return camera.CFrame
	end

	if not state.root or not state.humanoid then
		return camera.CFrame
	end

	if state.humanoid.Health <= 0 then
		return camera.CFrame
	end

	local mouse_delta = UserInputService:GetMouseDelta()
	state.yaw = state.yaw - mouse_delta.X * state.sensitivity
	state.pitch = math.clamp(state.pitch - mouse_delta.Y * state.sensitivity, -80, 80)

	local root_position = state.root.Position
	local look_position = root_position + Vector3.new(0, state.look_height, 0)
	local rotation = CFrame.Angles(0, math.rad(state.yaw), 0) * CFrame.Angles(math.rad(state.pitch), 0, 0)
	local target_position = root_position + rotation * Vector3.new(0, state.shoulder_height, -state.distance)
	local target_cframe = CFrame.lookAt(target_position, look_position)

	local smoothing = math.clamp(delta_time * 8, 0.1, 1)
	camera.CFrame = camera.CFrame:Lerp(target_cframe, smoothing)

	return camera.CFrame
end

function module:Enable()
	if state.enabled then
		return
	end

	update_character_refs()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	camera.CameraType = Enum.CameraType.Custom
	state.enabled = true
	module.Enabled = true
	module.Toggled:Fire(true)
end

function module:Disable()
	if not state.enabled then
		return
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	state.enabled = false
	module.Enabled = false
	module.Toggled:Fire(false)
end

function module:Toggle()
	if state.enabled then
		self:Disable()
	else
		self:Enable()
	end
end

local function on_input_began(input: InputObject, game_processed: boolean)
	if game_processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		module:Toggle()
	end
end

player.CharacterAdded:Connect(function(character: Model)
	character:WaitForChild("Humanoid")
	character:WaitForChild("HumanoidRootPart")
	character:WaitForChild("Head")
	resolve_character()
end)

player.CharacterRemoving:Connect(function()
	state.character = nil
	state.humanoid = nil
	state.root = nil
	state.head = nil
end)

RunService.PreRender:Connect(function(delta_time: number)
	update_camera(delta_time)
end)

UserInputService.InputBegan:Connect(on_input_began)

camera_controller.new("over-shoulder", update_camera)

return module
