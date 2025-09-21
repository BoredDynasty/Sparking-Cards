--!strict

-- plane.luau

local plane = {}
plane.__index = plane

type self = {
	normal: Vector3,
	distance: number,
}

export type metatable = setmetatable<self, typeof(plane)>

function plane.new(normal: Vector3, distance: number): metatable
	local self = setmetatable({}, plane)

	self.normal = normal or Vector3.new(0, 1, 0)
	self.distance = distance or 0

	return self
end

function plane:rayIntersectionDistance(self: metatable, origin: Vector3, direction: Vector3)
	local denominator = direction:Dot(self.normal)

	return (self.distance - origin:Dot(self.normal)) / denominator
end

return plane
