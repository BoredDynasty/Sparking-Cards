--!strict
local RunService = game:GetService("RunService")

-- orbit.luau

local module = {}

--[[
   ## Usage Example
   ```luau
   local orbit = require(path.to.orbit)

   local part = workspace.Part

   local orbiting = orbit.new(part, Vector3.new(0,0,0), 10, 1)

   -- To stop the orbiting
   orbiting:Destroy()
   ```
]]
function module.new(part: BasePart, center: Vector3, radius: number, speed: number, axis: Vector3?)
	local angle = 0

	local function orbit(deltaTime: number): Vector3
		angle += math.rad(90) * speed * deltaTime

		local x = center.X + radius * math.cos(angle)
		local z = center.Z + radius * math.sin(angle)
		local y = center.Y

		return Vector3.new(x, y, z)
	end

	local conn = nil

	conn = RunService.PreRender:Connect(function(deltaTime)
		part.Position = orbit(deltaTime)
	end)

	return {
		Destroy = function()
			if conn then
				conn:Disconnect()
			end
		end,
	}
end

return module
