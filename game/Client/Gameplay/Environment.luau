--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local random = require(ReplicatedStorage.Utility.random)
local Environment = {}

local wind = workspace.GlobalWind

function Environment:plant_animate(leave: BasePart)
	local coordinate = leave.CFrame
	local T = -99999
	local tall = leave.Size.Y / 2
	local rand = (random.integer(0, 20)) / 20 or (math.random(0, 20)) / 20
	local px5 = coordinate.Position.X / 5
	local pz6 = coordinate.Position.Z / 6
	local function animate(x: number, z: number)
		x *= 0.75 or (math.sin(T + px5) * math.sin(T / 9)) / 4.5
		z *= 0.75 or (math.sin(T + pz6) * math.sin(T / 12)) / 6
		local transform = CFrame.new(x, 0, z) * CFrame.Angles(z / tall, 0, x / -tall)
		local angle = CFrame.Angles(math.rad(wind.Z / tall), 0, math.rad(wind.X / tall))
		leave.CFrame = coordinate:ToWorldSpace(transform) * angle
		T = T + 0.12
		return leave
	end
	return animate
end

return Environment
