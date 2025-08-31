--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)

export type BoundingBox = {
	Position: Vector3,
	Size: Vector3,
	Rotation: Vector3,
	OnEnter: SignalPlus.Signal<Vector3>, -- SignalPlus signal
	LastPoints: { [Vector3]: boolean }, -- Track points that were inside
}

local BoundingBox = {}
--[[
   Creates a new bounding box with the given parameters
   ```luau
   local BoundingBox = require(path.to.boundingbox)

   -- Create a bounding box
   local box = BoundingBox.new(
      Vector3.new(0, 0, 0),  -- position
      Vector3.new(2, 2, 2),  -- size
      Vector3.new(0, 0, 0)   -- rotation
   ```
)
   ]]
function BoundingBox.new(position: Vector3, size: Vector3, rotation: Vector3?): BoundingBox
	return {
		Position = position,
		Size = size,
		Rotation = rotation or Vector3.new(0, 0, 0),
		OnEnter = SignalPlus(), -- Create new signal
		LastPoints = {},
	}
end

-- Checks if a point is inside the bounding box
function BoundingBox.isPointInside(box: BoundingBox, point: Vector3): boolean
	-- Transform point to local space
	local relativePoint = point - box.Position

	-- If there's rotation, transform the point
	if box.Rotation ~= Vector3.new(0, 0, 0) then
		local cx = math.cos(box.Rotation.X)
		local sx = math.sin(box.Rotation.X)
		local cy = math.cos(box.Rotation.Y)
		local sy = math.sin(box.Rotation.Y)
		local cz = math.cos(box.Rotation.Z)
		local sz = math.sin(box.Rotation.Z)

		relativePoint = Vector3.new(
			cy * cz * relativePoint.X + (-cy * sz) * relativePoint.Y + sy * relativePoint.Z,
			(sx * sy * cz + cx * sz) * relativePoint.X
				+ (-sx * sy * sz + cx * cz) * relativePoint.Y
				+ (-sx * cy) * relativePoint.Z,
			(-cx * sy * cz + sx * sz) * relativePoint.X
				+ (cx * sy * sz + sx * cz) * relativePoint.Y
				+ (cx * cy) * relativePoint.Z
		)
	end

	-- Check if point is within bounds
	local halfSize = box.Size * 0.5
	return math.abs(relativePoint.X) <= halfSize.X
		and math.abs(relativePoint.Y) <= halfSize.Y
		and math.abs(relativePoint.Z) <= halfSize.Z
end

-- Checks if two bounding boxes intersect
function BoundingBox.intersects(box1: BoundingBox, box2: BoundingBox): boolean
	-- Simple AABB intersection check (without rotation for simplicity)
	-- For rotated boxes, you might want to implement Separating Axis Theorem
	local halfSize1 = box1.Size * 0.5
	local halfSize2 = box2.Size * 0.5

	return math.abs(box1.Position.X - box2.Position.X) <= (halfSize1.X + halfSize2.X)
		and math.abs(box1.Position.Y - box2.Position.Y) <= (halfSize1.Y + halfSize2.Y)
		and math.abs(box1.Position.Z - box2.Position.Z) <= (halfSize1.Z + halfSize2.Z)
end

-- Checks if a point is inside and fires OnEnter if it wasn't inside before
function BoundingBox.checkPoint(box: BoundingBox, point: Vector3): boolean
	local isInside = BoundingBox.isPointInside(box, point)

	-- If point is inside and wasn't before, fire OnEnter signal
	if isInside and not box.LastPoints[point] then
		box.LastPoints[point] = true
		box.OnEnter:Fire(point)
	elseif not isInside and box.LastPoints[point] then
		box.LastPoints[point] = nil
	end

	return isInside
end

return BoundingBox
