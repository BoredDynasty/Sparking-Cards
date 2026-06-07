--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local custom_lighting = require(ReplicatedStorage.ClientModules["custom-lighting"])

-- motion-blur.luau
-- we're not gonna use the camera controller for ts.

local camera = workspace.CurrentCamera

-- track it less frequently
local lastCheck: number = 0.0
local checkInterval = 0.1 -- seconds

local last_position = camera.CFrame.Position

local conn = nil :: RBXScriptConnection?

local module = {}

function module:On(default_size: number?, max_size: number?, intensity: number?)
	default_size = default_size or 0
	max_size = max_size or 10
	intensity = intensity or 10

	if conn ~= nil then
		conn:Disconnect()
	end

	conn = RunService.RenderStepped:Connect(function(deltaTime: number)
		debug.profilebegin("motion-blur")

		lastCheck += deltaTime :: number
		if lastCheck < checkInterval then
			debug.profileend()

			return
		end
		lastCheck = 0

		local position = camera.CFrame.Position
		local size = (position - last_position).Magnitude * intensity :: number

		local blur_size = math.clamp(size, default_size :: number, max_size :: number)

		custom_lighting.blur(blur_size)

		last_position = position
	end)
end

function module:Off()
	if conn ~= nil then
		conn:Disconnect()
		conn = nil
	end
end

return module
