--!strict
local RunService = game:GetService("RunService")

-- object-orbit.luau
-- makes a part orbit around a point.

local module = {}
module._connections = {} :: { RBXScriptConnection }

--[[
   ```luau
   -- usage

   local orbit = require(path.to.object-orbit)

   local index = orbit:On(workspace.Part, 67, 41, 2)

   task.wait(10)

   -- after you're done, make sure to:
   orbit:Off(index)
]]
function module:On(part: BasePart, max_orbs: number, distance: number, cycle_duration: number)
	local orbs = {}

	local angle_step = 2 * math.pi / max_orbs

	local i = 0

	for orb_i = 1, max_orbs do
		local base_part = part:Clone()
		base_part.Parent = part
		base_part.Anchored = true

		table.insert(orbs, base_part)
	end

	local conn = nil

	conn = RunService.PreRender:Connect(function(deltaTime)
		i += (deltaTime / cycle_duration) % 1

		for orb_i, orb in ipairs(orbs) do
			local alpha = 2 * math.pi * i + (orb_i - 2) * angle_step

			orb.CFrame = CFrame.Angles(0, alpha, 0) * CFrame.new(0, 0, distance) + part.Position
		end
	end)

	table.insert(module._connections, conn)

	return table.find(module._connections, conn) :: number -- i swear if ts errors
end

function module:Off(i: number)
	local conn = table.remove(module._connections, i)

	if conn then
		conn:Disconnect()
	end
end

return module
