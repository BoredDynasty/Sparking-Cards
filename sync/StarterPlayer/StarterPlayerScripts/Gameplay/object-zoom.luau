--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local spr = require(ReplicatedStorage.Modules.spr)

-- object-zoom.luau
-- zooms the camera in on an object.

local module = {}

local camera = workspace.CurrentCamera

function module:Zoom(part: BasePart)
	camera.CameraType = Enum.CameraType.Scriptable

	local distance = math.max(part.Size.X, part.Size.Y, part.Size.Z) * 1.5
	local direction = (camera.CFrame.Position - part.Position).Unit

	local target_coordinate = CFrame.new(part.Position + direction * distance, part.Position)

	spr.target(camera, 1, 0.9, {
		CFrame = target_coordinate,
	})
end

function module:Revert()
	spr.stop(camera, "CFrame")

	camera.CameraType = Enum.CameraType.Custom
end

return module
