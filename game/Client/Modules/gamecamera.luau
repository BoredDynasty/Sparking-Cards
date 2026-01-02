--!nonstrict
--[=[
	GameCamera
	@module GameCamera

	A facade for the camera system. Initializes the CameraController and all its effects,
	and provides a public API for other scripts to interact with the camera.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraController = require("../Camera/CameraController")

local module = {}

local controller = CameraController.new()

module.updated = controller._update
module.camera = workspace.CurrentCamera

workspace.CurrentCamera.Changed:Connect(function()
	module.camera = workspace.CurrentCamera
end)

-- Add effects
controller:Add("Sway", require("../Camera/Sway"))
-- controller:Add("Follow", require("../Camera/Follow"))
controller:Add("Shake", require("../Camera/Shake"))

-- Start the camera controller
controller:Start()

-- Public API
function module:Shake(strength: number, duration: number)
	local shaker = controller:Get("Shake")
	if shaker then
		shaker:Shake(strength, duration)
	end
end

function module:Bind(name: string, f: (any) -> ...any?, ...: any)
	controller:Bind(name, f, ...)
end

function module:UnBind(name: string)
	controller:UnBind(name)
end

function module:GetCamera()
	return module.camera
end

function module:Destroy()
	controller:Destroy()
end

return module
