--!strict

-- waypoints.luau
-- value specific waypoint methods

local module = {}

function module:FromVec3(...: Vector3)
	local args = { ... }
	local waypoints = {}

	for i, arg in ipairs(args) do
		if typeof(arg) == "Vector3" then
			table.insert(waypoints, arg)
		else
			warn(`Argument {i} is not a Vector3: {arg}`)
		end
	end
end

function module:FromParts(...: BasePart)
	local args = { ... }
	local waypoints = {}

	for i, arg in ipairs(args) do
		if typeof(arg) == "Instance" and arg:IsA("BasePart") then
			table.insert(waypoints, arg.Position)
		else
			warn(`Argument {i} is not a BasePart: {arg}`)
		end
	end

	return waypoints
end

function module:FromCFrames(...: CFrame)
	local args = { ... }
	local waypoints = {}

	for i, arg in ipairs(args) do
		if typeof(arg) == "CFrame" then
			table.insert(waypoints, arg.Position)
		else
			warn(`Argument {i} is not a CFrame: {arg}`)
		end
	end

	return waypoints
end

return module
