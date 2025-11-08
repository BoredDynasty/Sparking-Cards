--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local random = require(ReplicatedStorage.Utility.random)

--[[
   Returns a point inside a rectangular prism Part with a given inset from the edge

   @param part 
   @param inset

   @return Vector3
]]
return function(part: BasePart, inset: number): Vector3
	local x = (part.Size.X - inset) * (random.float() - 0.5)
	local y = (part.Size.Y - inset) * (random.float() - 0.5)
	local z = (part.Size.Z - inset) * (random.float() - 0.5)

	local vec3 = Vector3.new(x, y, z)

	return part.CFrame:PointToWorldSpace(vec3)
end
