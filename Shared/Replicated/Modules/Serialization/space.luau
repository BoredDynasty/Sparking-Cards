--!strict

-- space.luau
-- for converting between different vector representations

local function toVector3(vec: vector | CFrame): Vector3
	if typeof(vec) == "CFrame" then
		return vec.Position
	else
		return Vector3.new(vec.x, vec.y, vec.z)
	end
end

local function toVector2(vec: vector | CFrame): Vector2
	if typeof(vec) == "CFrame" then
		return Vector2.new(vec.Position.X, vec.Position.Y)
	else
		return Vector2.new(vec.x, vec.y)
	end
end

local function toVec(vec: Vector3 | Vector2): vector
	local v = vector.zero
	if typeof(vec) == "Vector3" then
		v = vector.create(vec.X, vec.Y, vec.Z)
	elseif typeof(vec) == "Vector2" then
		v = vector.create(vec.X, vec.Y)
	end
	return v
end

return {
	toVector3 = toVector3,
	toVector2 = toVector2,
	toVec = toVec,
}
