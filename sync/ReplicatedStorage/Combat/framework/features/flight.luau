--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)
local audio = require(ReplicatedStorage.Modules.audio)
local future = require(ReplicatedStorage.Packages.future)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- flight.luau
-- to be ran on the client

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local camera = workspace.CurrentCamera

local module = {}

local conn = nil :: RBXScriptConnection?

local fly_track = animate.load(126501858389663)
local hover_track = animate.load(88656927831375)

local function getCameraRelativeDirection()
	local move_direction = humanoid.MoveDirection

	if move_direction == Vector3.zero then
		return Vector3.zero
	end

	local coordinate = camera.CFrame

	local flat_look_vector = Vector3.new(coordinate.LookVector.X, 0, coordinate.LookVector.Z)
	local relative_direction = (coordinate * CFrame.new(
		(CFrame.new(coordinate.Position, coordinate.Position + flat_look_vector)):VectorToObjectSpace(
			move_direction
		)
	)).Position - coordinate.Position

	if relative_direction == Vector3.zero then
		return Vector3.zero
	end

	return relative_direction.Unit
end

function module.setup(character: typemarshaller.Character)
	local primary_part = character.PrimaryPart or character:WaitForChild("HumanoidRootPart", 3)
	if not primary_part then
		print("no root")
		return
	end

	local velocity = Instance.new("BodyVelocity")
	velocity.Name = "FlightVelocity"
	velocity.MaxForce = Vector3.one * 1e5
	velocity.Velocity = Vector3.zero
	velocity.P = 1e4
	velocity.Parent = primary_part

	local gyro = Instance.new("BodyGyro")
	gyro.Name = "FlightGyro"
	gyro.MaxTorque = Vector3.one * 1e5
	gyro.CFrame = character.PrimaryPart.CFrame
	gyro.P = 3000
	gyro.D = 500
	gyro.Parent = primary_part

	character:SetAttribute("Flying", false)
end

function module:On()
	if conn then
		return
	end

	local velocity = character:FindFirstChild("FlightVelocity") :: BodyVelocity
	local gyro = character:FindFirstChild("FlightGyro") :: BodyGyro
	if not velocity or not gyro then
		warn("FlightVelocity or FlightGyro not found. Make sure to call module.setup(character) first.")

		return
	end

	character:SetAttribute("Flying", true)
	animate.stop_all()

	if hover_track then
		hover_track:Play(0.1, 1, 1)
	else
		warn("no hover animation track")
	end

	for i, state in ipairs {
		{
			Enum.HumanoidStateType.Running,
			Enum.HumanoidStateType.Climbing,
			Enum.HumanoidStateType.FallingDown,
			Enum.HumanoidStateType.Freefall,
		},
	} do
		humanoid:SetStateEnabled(state, false)
	end

	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	conn = RunService.Heartbeat:Connect(function(delta_time)
		if not character or not character.PrimaryPart then
			character:SetAttribute("Flying", false)
			return
		end
		if humanoid.Health <= 0 then
			character:SetAttribute("Flying", false)
			return
		end

		gyro.CFrame = camera.CFrame

		local move_direction = getCameraRelativeDirection()
		local target_velocity = move_direction * 90

		-- smoothly interpolate the velocity towards the target velocity
		velocity.Velocity = velocity.Velocity:Lerp(target_velocity, 0.2)

		-- smoothly interpolate the winds volume and pitch based on the velocity magnitude
		local wind_volume = math.clamp(velocity.Velocity.Magnitude / 90, 0, 1.5)
		local wind_pitch = math.clamp(velocity.Velocity.Magnitude / 90, 0.5, 2)
		audio:ConfigureMusic("flight-wind", {
			volume = wind_volume,
			pitch = wind_pitch,
		})

		if move_direction.Magnitude > 0 then
			-- animate the character
			if not fly_track.IsPlaying then
				fly_track:Play()
				hover_track:Stop()

				audio:PlayMusic("flight-wind")
			end
		else
			if not hover_track.IsPlaying then
				hover_track:Play()
				fly_track:Stop()

				audio:StopMusic("flight-wind")
			end
		end

		-- the camera is already being altered by the client; no need for additional computation
	end)
end

function module:Off()
	if conn then
		conn:Disconnect()
	end

	conn = nil

	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end

	if character then
		character:SetAttribute("Flying", false)
	end

	if hover_track and fly_track then
		hover_track:Stop()
		fly_track:Stop()
	end

	audio:StopMusic("flight-wind")

	future.Try(function()
		for i, state in ipairs {
			{
				Enum.HumanoidStateType.Running,
				Enum.HumanoidStateType.Climbing,
				Enum.HumanoidStateType.FallingDown,
				Enum.HumanoidStateType.Freefall,
			},
		} do
			humanoid:SetStateEnabled(state, true)
		end
	end)
end

humanoid.Died:Connect(function()
	module:Off()
end)

return module
