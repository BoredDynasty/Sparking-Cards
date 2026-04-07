--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local spr = require(ReplicatedStorage.Modules.spr)

-- object-zoom.luau
-- zooms the camera in on an object.

local module = {}

local camera = workspace.CurrentCamera

local conn = nil :: RBXScriptConnection?

local SMOOTHNESS = 0.1
local MIN_FOV = 20 -- Max zoom (when far)
local MAX_FOV = 70 -- Wide angle (when close)
local MIN_DIST = 10 -- Distance where FOV is widest
local MAX_DIST = 100 -- Distance where FOV is narrowest

function module:Zoom(part: BasePart, set_position: Vector3?)
	camera.CameraType = Enum.CameraType.Scriptable

	-- smoothly make the camera look at the part
	set_position = set_position or camera.CFrame.Position

	conn = RunService.PreRender:Connect(function()
		local distance = (set_position - part.Position).Magnitude

		-- where the distance falls between min and max
		local alpha = math.clamp((distance - MIN_DIST) / (MAX_DIST - MIN_DIST), 0, 1)

		-- flip it
		local target_fov = MAX_FOV - (alpha * (MAX_FOV - MIN_FOV))

		local target = CFrame.lookAt(set_position, part.Position)

		camera.CFrame = camera.CFrame:Lerp(target, SMOOTHNESS)
		camera.FieldOfView = camera.FieldOfView + (target_fov - camera.FieldOfView) * SMOOTHNESS
	end)
end

function module:Revert()
	if conn then
		conn:Disconnect()
		conn = nil
	end

	local profile = fetchProfile()
	if profile then
		local saved_fov = profile.Data.options.fov :: number
		if saved_fov then
			spr.target(camera, 0.8, 5, {
				FieldOfView = saved_fov,
			})
		else
			spr.target(camera, 0.8, 5, {
				FieldOfView = 70,
			})
		end
	else
		spr.target(camera, 0.8, 5, {
			FieldOfView = 70,
		})
	end

	camera.CameraType = Enum.CameraType.Custom
end

return module
