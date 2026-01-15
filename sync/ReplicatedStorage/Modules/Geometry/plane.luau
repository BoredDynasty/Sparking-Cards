--!strict

-- plane.luau

local plane = {}
plane.__index = plane

type self = {
	normal: Vector3,
	distance: number,
	position: Vector3?,
	direction: Vector3?,
	origin: Vector3?,
}

export type metatable = setmetatable<self, typeof(plane)>

function plane.new(
	normal: Vector3?,
	distance: number?,
	position: Vector3?,
	direction: Vector3?,
	origin: Vector3?
): metatable
	local self = setmetatable({}, plane)

	self.normal = normal or Vector3.new(0, 1, 0)
	self.distance = distance or 0

	if position then
		self.position = position
	end
	if direction then
		self.direction = direction
	end
	if origin then
		self.origin = origin
	end

	return self
end

function plane:rayIntersectionDistance(self: metatable, origin: Vector3, direction: Vector3)
	local denominator = direction:Dot(self.normal)

	return (self.distance - origin:Dot(self.normal)) / denominator
end

function plane:rayPlaneIntersect(self: metatable)
	if not (self.position and self.direction and self.origin) then
		error("Missing position, direction, or origin for ray-plane intersection calculation")
	end

	local numerator = self.normal.X * (self.origin.X - self.position.X)
		+ self.normal.Y * (self.origin.Y - self.position.Y)
		+ self.normal.Z * (self.origin.Z - self.position.Z)

	local denominator = self.normal.X * self.direction.X
		+ self.normal.Y * self.direction.Y
		+ self.normal.Z * self.direction.Z

	return self.origin + (numerator / denominator) * self.direction, numerator / denominator
end

return plane
