--!strict

-- spline.luau

-- a catmullrom spline

return function(p0: vector, p1: vector, p2: vector, p3: vector, t: number): vector
	local t2 = t * t
	local t3 = t2 * t

	local x = 0.5
		* (
			(2 * p1.x)
			+ (-p0.x + p2.x) * t
			+ (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2
			+ (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3
		)

	local y = 0.5
		* (
			(2 * p1.y)
			+ (-p0.y + p2.y) * t
			+ (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2
			+ (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3
		)

	local z = 0.5
		* (
			(2 * p1.z)
			+ (-p0.z + p2.z) * t
			+ (2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t2
			+ (-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t3
		)

	return vector.create(x, y, z)
end
