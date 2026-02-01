--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local trove = require(ReplicatedStorage.Packages.trove)

-- camera-drag.luau

local module = {}

-- TODO) attune these values
local speed = 0
local base_height = 0
local orientation = 0
local zoom_step = 0
local height_range = NumberRange.new(0, 0)
local dynamic_speed = 0

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local camera_orientation = CFrame.Angles(math.rad(orientation), 0, 0)
local origin = Vector3.new(326.5, 1.5, 8)
local pan_current = Vector3.new(origin.X, 0, origin.Z)
local pan_target = pan_current
local zoom_target = math.clamp(base_height, height_range.Min, height_range.Max)
local zoom_current = math.clamp(base_height, height_range.Min, height_range.Max)
local smoothing = 1 / 8 -- default: 0.12
local connections: { RBXScriptConnection } = {}

-- controller
local pan_speed = 2.5
local zoom_speed = 0.25

-- mobile touch variables
local initial_pinch_distance = nil
local initial_zoom = nil
local is_pinching = false
local pan_target_before_pinch = nil

local _trove = trove.new()

function module:Start()
	if UserInputService.TouchEnabled then
		-- TODO) implement a touch gui
		-- enable the touch gui
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(pan_current.X, zoom_current, pan_current.Z) * camera_orientation

	_trove:Connect(mouse.WheelForward, function()
		zoom_target = math.clamp(zoom_target - zoom_step, height_range.Min, height_range.Max)
	end)

	_trove:Connect(mouse.WheelBackward, function()
		zoom_target = math.clamp(zoom_target - zoom_step, height_range.Min, height_range.Max)
	end)

	_trove:Connect(mouse.Button1Down, function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition

		local dragging = true

		local release_connection

		release_connection = mouse.Button1Up:Connect(function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default

			if release_connection then
				release_connection:Disconnect()
			end

			dragging = false
		end)

		while dragging do
			-- we should really put this in a RunService connection
			-- TODO) wrap this in a RunService event

			RunService.PreRender:Wait()

			local delta = UserInputService:GetMouseDelta()
			local new_speed = speed

			if dynamic_speed then
				new_speed = zoom_target / base_height * speed
			end

			pan_target += Vector3.new(-delta.X * new_speed, 0, -delta.Y * new_speed)
		end
	end)

	if UserInputService.TouchEnabled then
		_trove:Connect(
			UserInputService.TouchPan,
			function(
				touch_positions: { any },
				total_translation: Vector2,
				velocity: Vector2,
				state: Enum.UserInputState
			)
				if
					not is_pinching
					and (state == Enum.UserInputState.Change or state == Enum.UserInputState.End)
				then
					local new_speed = speed

					if dynamic_speed then
						new_speed = zoom_target / base_height * speed
					end

					pan_target += Vector3.new(
						total_translation.X * new_speed * 0.01,
						0,
						total_translation.Y * new_speed * 0.01
					)
				end
			end
		)

		_trove:Connect(
			UserInputService.TouchPinch,
			function(touch_positions: { any }, scale: number, velocity: number, state: Enum.UserInputState)
				if state == Enum.UserInputState.Begin then
					is_pinching = true
					initial_pinch_distance = 1
					initial_zoom = zoom_target
					pan_target_before_pinch = pan_target
				elseif state == Enum.UserInputState.Change then
					if initial_pinch_distance and initial_zoom then
						pan_target = pan_target_before_pinch

						local zoom_change = (1 - scale) * (height_range.Max - height_range.Min) * 0.8
						zoom_target =
							math.clamp(initial_zoom + zoom_change, height_range.Min, height_range.Max)
					end
				elseif state == Enum.UserInputState.End then
					is_pinching = false
					initial_pinch_distance = nil
					initial_zoom = nil
					pan_target_before_pinch = nil
				end
			end
		)
	end

	_trove:Connect(RunService.RenderStepped, function(delta_time: number)
		if UserInputService.GamepadEnabled then
			local thumbstick_state = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)

			local left_thumbstick = Vector2.zero
			local right_thumbstick = Vector2.zero

			for i, input in ipairs(thumbstick_state) do
				if input.KeyCode == Enum.KeyCode.Thumbstick1 then
					left_thumbstick = Vector2.new(input.Position.X, -input.Position.Y)
				elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
					left_thumbstick = Vector2.new(input.Position.X, input.Position.Y)
				end
			end

			if left_thumbstick.Magnitude > 0.1 then
				-- gulp! deadzone!

				local new_speed = speed * pan_speed
				if dynamic_speed then
					new_speed = zoom_target / base_height * speed * pan_speed
				end

				pan_target += Vector3.new(
					left_thumbstick.X * new_speed * delta_time * 60,
					0,
					left_thumbstick.Y * new_speed * delta_time * 60
				)
			end
		end

		if UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.DPadUp) then
			zoom_target =
				math.clamp(zoom_target - zoom_speed * delta_time * 60, height_range.Min, height_range.Max)
		end

		if UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.DPadDown) then
			zoom_target =
				math.clamp(zoom_target + zoom_speed * delta_time * 60, height_range.Min, height_range.Max)
		end

		local alpha = 1 - math.pow(1 - smoothing, delta_time * 60)
		pan_current = pan_current:Lerp(pan_target, alpha)
		zoom_current = zoom_current + (zoom_target - zoom_current) * alpha

		camera.CFrame = CFrame.new(pan_current.X, zoom_current, pan_current.Z) * camera_orientation
	end)
end

function module:Stop()
	if UserInputService.TouchEnabled then
		-- TODO) implement a touch gui
		-- enable the touch gui
	end

	_trove:Destroy()

	pan_current = Vector3.new(origin.X, 0, origin.Z)
	pan_target = pan_current
	zoom_target = math.clamp(base_height, height_range.Min, height_range.Max)
	zoom_current = math.clamp(base_height, height_range.Min, height_range.Max)

	camera.CFrame = CFrame.new(pan_current.X, zoom_current, pan_current.Z) * camera_orientation

	initial_pinch_distance = nil
	initial_zoom = nil
	is_pinching = false
	pan_target_before_pinch = nil

	connections = {}

	camera.CameraType = Enum.CameraType.Custom
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

return module
