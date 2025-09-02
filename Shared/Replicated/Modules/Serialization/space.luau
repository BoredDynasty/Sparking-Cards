--!strict

-- space.luau
-- for converting between different vector representations

local function toVector3(vec: vector): Vector3
	return Vector3.new(vec.x, vec.y, vec.z)
end

local function toVector2(vec: vector): Vector2
	return Vector2.new(vec.x, vec.y)
end

return {
	toVector3 = toVector3,
	toVector2 = toVector2,
}
