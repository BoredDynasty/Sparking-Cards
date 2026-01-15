--strict

-- octree

--[[
    For an object be be stored in an octree it must implement:
        intersectsBoundingBox(min, max) : bool
    and:
        rayIntersection(origin, direction) : results
]]

local plane = require("./plane")

local Constants = {
	OctreeLeafCapacity = 5,
	MaxOctreeDepth = 5,
}

local Octree = {}
Octree.__index = Octree
function Octree.new(min: Vector3, max: Vector3, depth: number)
	local self = setmetatable({}, Octree)

	self.min = min
	self.max = max
	self.center = (max + min) / 2

	self.midPlanes = {
		plane.new(Vector3.xAxis, self.center.X),
		plane.new(Vector3.yAxis, self.center.Y),
		plane.new(Vector3.zAxis, self.center.Z),
	}

	self.depth = depth or 0
	self.empty = true
	self.objects = {}
	self.nodes = {}

	return self
end

function Octree:insertObject(object)
	if object:intersectsBoundingBox(self.min, self.max) then
		self.empty = false
		if #self.nodes > 0 then
			for index, node in self.nodes do
				node:insertObject(object)
			end
		else
			table.insert(self.objects, object)

			if #self.objects > Constants.OctreeLeafCapacity and self.depth < Constants.MaxOctreeDepth then
				-- Make new nodes
				local values = { false, true }
				for xindex, xSide in values do
					for yindex, ySide in values do
						for zindex, zSide in values do
							local xMin = xSide and self.center.X or self.min.X
							local xMax = xSide and self.max.X or self.center.X

							local yMin = ySide and self.center.Y or self.min.Y
							local yMax = ySide and self.max.Y or self.center.Y

							local zMin = zSide and self.center.Z or self.min.Z
							local zMax = zSide and self.max.Z or self.center.Z

							table.insert(
								self.nodes,
								Octree.new(
									Vector3.new(xMin, yMin, zMin),
									Vector3.new(xMax, yMax, zMax),
									self.depth + 1
								)
							)
						end
					end
				end

				-- Add objects to the new nodes
				for nodeIndex, node in self.nodes do
					for objectIndex, object in self.objects do
						node:insertObject(object)
					end
				end
				self.objects = {}
			end
		end
	end
end

function Octree:findObject(object)
	for objectIndex, testObject in self.objects do
		if testObject == object then
			return true
		end
	end
	for nodeIndex, node in self.nodes do
		if node:findObject(object) then
			return true
		end
	end
	return false
end

function Octree:containsPoint(point: Vector3)
	return point.X >= self.min.X
		and point.X <= self.max.X
		and point.Y >= self.min.Y
		and point.Y <= self.max.Y
		and point.Z >= self.min.Z
		and point.Z <= self.max.Z
end

function Octree:rayBoxIntersection(origin: Vector3, direction: Vector3)
	-- Adapted from https://github.com/stackgl/ray-aabb-intersection
	local low = -math.huge
	local high = math.huge

	for _, axis in { "X", "Y", "Z" } do
		local dimLow = (self.min[axis] - origin[axis]) / direction[axis]
		local dimHigh = (self.max[axis] - origin[axis]) / direction[axis]

		if dimLow > dimHigh then
			local temp = dimLow
			dimLow = dimHigh
			dimHigh = temp
		end

		if dimHigh < low or dimLow > high then
			return math.huge
		end

		if dimLow > low then
			low = dimLow
		end
		if dimHigh < high then
			high = dimHigh
		end
	end

	return low > high and math.huge or low
end

function Octree:rayIntersection(origin: Vector3, direction: Vector3, castOrigin: Vector3)
	-- Implementation derived from https://daeken.svbtle.com/a-stupidly-simple-fast-octree-traversal-for-ray-intersection
	-- Note that the code implementation presented there is not correct, the inner loop should run 4 times, not 3
	if self.empty then
		return nil
	end

	if #self.objects > 0 and #self.nodes > 0 then
		error("Node is leaf and container")
	end

	if #self.objects > 0 then
		local closestResult = nil

		for id, object in self.objects do
			local result = object:rayIntersection(origin, direction)
			if result then
				if closestResult == nil or result.distance < closestResult.distance then
					closestResult = result
				end
			end
		end

		if closestResult ~= nil and self:containsPoint(origin + direction * closestResult.distance) then
			return closestResult
		else
			return nil
		end
	end

	if #self.nodes == 0 then
		return nil
	end

	if castOrigin == nil then
		if self:containsPoint(origin) then
			castOrigin = origin
		else
			local intersectionDistance = self:rayBoxIntersection(origin, direction)
			if intersectionDistance == math.huge then
				return nil
			end
			castOrigin = origin + direction * intersectionDistance
		end
	end

	local side = {}

	for i = 1, 3 do
		table.insert(side, castOrigin:Dot(self.midPlanes[i].normal) - self.midPlanes[i].distance >= 0)
	end

	local distances = {
		(side[1] == (direction.X < 0)) and self.midPlanes[1]:rayIntersectionDistance(castOrigin, direction)
			or math.huge,
		(side[2] == (direction.Y < 0)) and self.midPlanes[2]:rayIntersectionDistance(castOrigin, direction)
			or math.huge,
		(side[3] == (direction.Z < 0)) and self.midPlanes[3]:rayIntersectionDistance(castOrigin, direction)
			or math.huge,
	}

	if distances[1] < 0 or distances[2] < 0 or distances[3] < 0 then
		warn("Negative distance detected")
	end

	local currentOrigin = castOrigin
	for i = 1, 4 do
		local nodeIndex = 1
		if side[1] then
			nodeIndex = nodeIndex + 4
		end
		if side[2] then
			nodeIndex = nodeIndex + 2
		end
		if side[3] then
			nodeIndex = nodeIndex + 1
		end

		local results = self.nodes[nodeIndex]:rayIntersection(origin, direction, currentOrigin)
		if results ~= nil then
			return results
		end

		local minimumDistance = math.min(distances[1], distances[2], distances[3])
		if minimumDistance == math.huge then
			return nil
		end

		currentOrigin = castOrigin + direction * minimumDistance

		if not self:containsPoint(currentOrigin) then
			return nil
		end

		for j = 1, 3 do
			if minimumDistance == distances[j] then
				side[j] = not side[j]
				distances[j] = math.huge
				break
			end
		end
	end
	return nil
end

return Octree
