--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local hydration = require(ReplicatedStorage.Utility.hydration)
local sound_ids = require("@self/sound-ids")
local spr = require(ReplicatedStorage.Modules.spr)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- movement-sounds.luau
-- excluded from audio.luau.

local module = {}
-- this works autonomously; there is a lack of public functions.

local camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root_part = humanoid.RootPart :: BasePart

local id = 0
local volume = 0
local playback_speed = 0

local floor_material = humanoid.FloorMaterial
local material = floor_material.Name

local current_sound = Instance.new("Sound")
current_sound.Parent = SoundService

do
	local default_sound = root_part:FindFirstChild("Running")
	if default_sound then
		default_sound:Destroy()
	end
end

local function getFloorMaterial()
	floor_material = humanoid.FloorMaterial
	material = floor_material.Name

	return material
end

local function getSoundProperties()
	for i, data in pairs(sound_ids :: { [string]: sound_ids.SoundData }) do
		if i == material then
			id = data.id
			volume = data.volume
			playback_speed = (humanoid.WalkSpeed / 14) * data.speed

			break
			-- prevent further execution
		end
	end
end

local function updateSoundProperties()
	current_sound.SoundId = `rbxassetid://{id}`

	spr.stop(current_sound)

	spr.target(current_sound, 0.8, 1.95, {
		Volume = volume,
		PlaybackSpeed = playback_speed,
	})
end

local last_camera_position = camera.CFrame.Position

local function updateVolume()
	if not character then
		return
	end

	if not root_part then
		return
	end

	local camera_position = camera.CFrame.Position

	if camera_position == last_camera_position then
		-- this will likely NEVER happen.
		-- we made it so the camera is always moving.

		return
	end

	local max_distance = 100
	local min_volume = 0
	local max_volume = volume

	local character_position = root_part.Position

	local distance = (camera_position - character_position).Magnitude

	local new_volume = math.clamp(volume - (distance / max_distance), min_volume, max_volume)
	spr.stop(current_sound, "Volume")
	spr.target(current_sound, 0.8, 1.95, {
		Volume = new_volume,
	})

	last_camera_position = camera_position
end

humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
	getFloorMaterial()
	getSoundProperties()
	updateSoundProperties()

	if humanoid.MoveDirection.magnitude > 0 then
		current_sound.Playing = true
	else
		current_sound:Stop()
	end
end)

humanoid.Running:Connect(function(speed)
	if humanoid.MoveDirection.Magnitude <= 0 then
		current_sound:Stop()

		return
	end

	if speed <= 0 then
		current_sound:Stop()

		return
	end

	if humanoid:GetState() == Enum.HumanoidStateType.Climbing then
		current_sound:Stop()

		return
	end

	-- proceed

	getSoundProperties()
	updateSoundProperties()

	current_sound.Playing = true
	current_sound.Looped = true
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	if current_sound.Playing then
		current_sound:Stop()
	end
end)

RunService.Heartbeat:Connect(updateVolume)
