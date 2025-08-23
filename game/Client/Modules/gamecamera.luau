--!strict
--[=[
	GameCamera
	@module GameCamera

	A facade for the camera system. Initializes the CameraController and all its effects,
	and provides a public API for other scripts to interact with the camera.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraController = require(game.StarterPlayer.StarterPlayerScripts.Camera.CameraController)

local GameCamera = {}

local controller = CameraController.new()

-- Add effects
controller:Add("Sway", require(game.StarterPlayer.StarterPlayerScripts.Camera.Sway))
controller:Add("Follow", require(game.StarterPlayer.StarterPlayerScripts.Camera.Follow))
controller:Add("Trail", require(game.StarterPlayer.StarterPlayerScripts.Camera.Trail))
controller:Add("Shake", require(game.StarterPlayer.StarterPlayerScripts.Camera.Shake))
controller:Add("Recoil", require(game.StarterPlayer.StarterPlayerScripts.Camera.Recoil))
controller:Add("Offset", require(game.StarterPlayer.StarterPlayerScripts.Camera.Offset))
controller:Add("Idle", require(game.StarterPlayer.StarterPlayerScripts.Camera.Idle))
local fovManager = controller:Add("DynamicFOV", require(game.StarterPlayer.StarterPlayerScripts.Camera.DynamicFOV))

-- Start the camera controller
controller:Start()

-- Public API
function GameCamera:Shake(strength: number, duration: number)
	local shaker = controller:Get("Shake")
	if shaker then
		shaker:Shake(strength, duration)
	end
end

function GameCamera:Recoil(strength: number)
	local recoiler = controller:Get("Recoil")
	if recoiler then
		recoiler:Recoil(strength)
	end
end

function GameCamera:TweenFOV(targetFOV: number, duration: number, override: boolean?)
	fovManager:TweenFOV(targetFOV, duration, override)
end

function GameCamera:GetBaseFOV(): number
	return fovManager:GetBaseFOV()
end

function GameCamera:Destroy()
	controller:Destroy()
end

return GameCamera
