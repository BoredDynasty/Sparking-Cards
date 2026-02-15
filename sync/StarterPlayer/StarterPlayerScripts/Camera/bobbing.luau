--!strict
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local lerp = require(StarterPlayer.StarterPlayerScripts.Utilities.lerp)

-- bobbing.luau

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root_part = humanoid.RootPart :: BasePart

local camera = workspace.CurrentCamera
local roll_offset = 0
local pitch_offset = 0
local tilt_angle = 0
local bob_intensity = 0
local sway_offset = 0
local horizontal_sway = 0
local bob_frequency = 5
local sway_frequency = 5
local camera_direction = Vector3.zero

return function(deltaTime: number)
	deltaTime *= 60

	if humanoid.Health <= 0 then
		return CFrame.new()
	end

	local root_velocity = root_part.AssemblyLinearVelocity

	local root_magnitude = Vector3.new(root_velocity.X, 0, root_velocity.Z).Magnitude or 0
	local min_root_magnitude = math.min(root_magnitude, 25)

	local current_time = os.clock()

	if deltaTime > 1.5 then
		roll_offset, pitch_offset = 0, 0
	else
		roll_offset = lerp(
			roll_offset,
			math.cos(current_time / 2 * math.random(5, 7.5)) * (math.random(2.5, 10) / 100) * deltaTime,
			0.05 * deltaTime
		)
		pitch_offset = lerp(
			pitch_offset,
			math.cos(current_time * 0.5 * math.random(2.5, 5)) * (math.random(1, 5) / 100) * deltaTime,
			0.05 * deltaTime
		)
	end

	local _coordinate = camera.CFrame
		* (
			CFrame.fromEulerAnglesXYZ(0, 0, math.rad(tilt_angle))
			* CFrame.fromEulerAnglesXYZ(
				math.rad(bob_intensity * deltaTime),
				math.rad(sway_offset * deltaTime),
				horizontal_sway
			)
			* CFrame.Angles(0, 0, math.rad(bob_intensity * deltaTime * (min_root_magnitude / 5)))
			* CFrame.fromEulerAnglesXYZ(
				math.rad(roll_offset),
				math.rad(pitch_offset),
				math.rad(pitch_offset * 10)
			)
		)

	horizontal_sway = math.clamp(
		lerp(
			horizontal_sway,
			-camera.CFrame:VectorToObjectSpace(
					(root_velocity or Vector3.new()) / math.max(humanoid.WalkSpeed, 0.01)
				).X * 0.04,
			0.1 * deltaTime
		),
		-0.12,
		0.1
	)

	local mouse_delta = UserInputService:GetMouseDelta()

	tilt_angle = lerp(tilt_angle, math.clamp(mouse_delta.X, -2.5, 2.5), 0.25 * deltaTime)
	bob_intensity = lerp(
		bob_intensity,
		math.sin(current_time * bob_frequency) / 5 * math.min(1, sway_frequency / 10),
		0.25 * deltaTime
	)

	if root_magnitude > 1 then
		sway_offset = lerp(
			sway_offset,
			math.cos(tick() * 0.5 * math.floor(bob_frequency)) * (bob_frequency / 200),
			0.25 * deltaTime
		)
	else
		sway_offset = lerp(sway_offset, 0, 0.05 * deltaTime)
	end

	if root_magnitude > 6 then
		bob_frequency = 10
		sway_frequency = 9
	elseif root_magnitude > 0.1 then
		bob_frequency = 6
		sway_frequency = 7
	else
		sway_frequency = 0
	end

	camera_direction = lerp(camera_direction, camera.CFrame.LookVector, 0.125 * deltaTime)

	camera.CFrame = _coordinate

	return _coordinate
end
