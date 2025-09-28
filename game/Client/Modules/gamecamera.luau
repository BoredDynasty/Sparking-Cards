--!strict
--[=[
	GameCamera
	@module GameCamera

	A facade for the camera system. Initializes the CameraController and all its effects,
	and provides a public API for other scripts to interact with the camera.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraController = require("../Camera/CameraController")

local GameCamera = {}

local controller = CameraController.new()

GameCamera.updated = controller._update
GameCamera.camera = workspace.CurrentCamera

-- Add effects
controller:Add("Sway", require("../Camera/Sway"))
-- controller:Add("Follow", require("../Camera/Follow"))
controller:Add("Trail", require("../Camera/Trail"))
controller:Add("Shake", require("../Camera/Shake"))
local fovManager = controller:Add("DynamicFOV", require("../Camera/DynamicFOV"))

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

function GameCamera:Bind(name: string, f: (any) -> ...any?, ...)
	controller:Bind(name, f, ...)
end

function GameCamera:UnBind(name: string)
	controller:UnBind(name)
end

function GameCamera:Destroy()
	controller:Destroy()
end

return GameCamera
