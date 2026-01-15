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

local function toOffset(udim: UDim | UDim2)
	local v = 0

	if typeof(udim) == "UDim2" then
		local camera = workspace.CurrentCamera
		local viewSize = camera.ViewportSize

		local newYOffset = udim.Y.Scale * viewSize.Y
		local newXOffset = udim.X.Scale * viewSize.X

		v = UDim2.fromOffset(newXOffset, newYOffset)
	elseif typeof(udim) == "UDim" then
		v = udim.Offset
	end

	return v
end

local function toCoordinate(vec: vector | Vector2 | Vector3)
	local value = CFrame.new()

	if type(vec) == "vector" then
		value = CFrame.new(vec.x, vec.x, vec.z)
	elseif typeof(vec) == "Vector2" then
		value = CFrame.new(vec.X, vec.Y, 0)
	elseif typeof(vec) == "Vector3" then
		value = CFrame.new(vec.X, vec.Y, vec.Z)
	end

	return value
end

return {
	toVector3 = toVector3,
	toVector2 = toVector2,
	toVec = toVec,
	toOffset = toOffset,
	toCoorinate = toCoordinate,
}
