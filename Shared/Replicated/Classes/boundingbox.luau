--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local observer = require(ReplicatedStorage.Utility.observer)
local space = require(ReplicatedStorage.Modules.Serialization.space)
local trove = require(ReplicatedStorage.Packages.trove)
local url = require(ReplicatedStorage.Modules.Serialization.url)

export type BoundingBox = {
	Position: vector,
	Size: vector,
	Rotation: vector,
	OnEnter: SignalPlus.Signal<vector>, -- SignalPlus signal
	LastPoints: { [vector]: boolean }, -- Track points that were inside
	Id: string,
}

local BoundingBox = {
	boxes = {},
	_trove = trove.new(),
	updating = observer.new(false),
}
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
function BoundingBox.new(position: vector, size: vector, rotation: vector?): BoundingBox
	local data = {
		Position = position,
		Size = size,
		Rotation = rotation or vector.zero,
		OnEnter = SignalPlus() :: SignalPlus.Signal<vector>,
		LastPoints = {},
		Id = url.generateShortUniqueId(),
	}

	BoundingBox.boxes[data.Id] = data

	return data
end

-- Checks if a point is inside the bounding box
function BoundingBox.isPointInside(box: BoundingBox, point: vector): boolean
	-- Transform point to local space
	local relativePoint = point - box.Position

	-- If there's rotation, transform the point
	if box.Rotation ~= vector.zero then
		local cx = math.cos(box.Rotation.x)
		local sx = math.sin(box.Rotation.x)
		local cy = math.cos(box.Rotation.y)
		local sy = math.sin(box.Rotation.y)
		local cz = math.cos(box.Rotation.z)
		local sz = math.sin(box.Rotation.z)

		relativePoint = vector.create(
			cy * cz * relativePoint.x + (-cy * sz) * relativePoint.y + sy * relativePoint.z,
			(sx * sy * cz + cx * sz) * relativePoint.x
				+ (-sx * sy * sz + cx * cz) * relativePoint.y
				+ (-sx * cy) * relativePoint.z,
			(-cx * sy * cz + sx * sz) * relativePoint.x
				+ (cx * sy * sz + sx * cz) * relativePoint.y
				+ (cx * cy) * relativePoint.z
		)
	end

	-- Check if point is within bounds
	local halfSize = box.Size * 0.5
	return math.abs(relativePoint.x) <= halfSize.x
		and math.abs(relativePoint.y) <= halfSize.y
		and math.abs(relativePoint.z) <= halfSize.z
end

-- Checks if two bounding boxes intersect
function BoundingBox.intersects(box1: BoundingBox, box2: BoundingBox): boolean
	-- Simple AABB intersection check (without rotation for simplicity)
	-- For rotated boxes, you might want to implement Separating Axis Theorem
	local halfSize1 = box1.Size * 0.5
	local halfSize2 = box2.Size * 0.5

	return math.abs(box1.Position.x - box2.Position.x) <= (halfSize1.x + halfSize2.x)
		and math.abs(box1.Position.y - box2.Position.y) <= (halfSize1.y + halfSize2.y)
		and math.abs(box1.Position.z - box2.Position.z) <= (halfSize1.z + halfSize2.z)
end

-- Checks if a point is inside and fires OnEnter if it wasn't inside before
function BoundingBox.checkPoint(box: BoundingBox, point: vector): boolean
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

-- Returns all BaseParts within the bounding box
function BoundingBox.GetPartsInBox(box: BoundingBox, parent: Instance?): { BasePart }
	local region = Region3.new(
		space.toVector3(box.Position - box.Size * 0.5),
		space.toVector3(box.Position + box.Size * 0.5)
	)

	local parts = workspace:GetPartBoundsInBox(region.CFrame, region.Size)

	return parts
end

function BoundingBox.update(point: vector): { [string]: boolean }?
	local list = {}

	if BoundingBox.updating:Get() == false then
		BoundingBox._trove:Connect(RunService.Heartbeat, function()
			for id, box in pairs(BoundingBox.boxes) do
				if BoundingBox.checkPoint(box, point) then
					list[box.Id] = true
				else
					list[box.Id] = false
				end
			end
		end)
	else
		print("already updating bounding boxes")
		return nil
	end

	return list
end

function BoundingBox.halt()
	-- allow for final processing
	task.defer(BoundingBox._trove.Clean, BoundingBox._trove)
end

function BoundingBox.getBoxFromId(id: string): BoundingBox?
	return BoundingBox.boxes[id]
end

return BoundingBox
