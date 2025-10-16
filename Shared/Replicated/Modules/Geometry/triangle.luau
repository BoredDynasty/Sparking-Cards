--!strict

-- triangle.luau

local triangle_module = {}

--[[
   Draws a triangle using two wedge parts.
   @param v1 Vector3 - First vertex of the triangle.
   @param v2 Vector3 - Second vertex of the triangle.
   @param v3 Vector3 - Third vertex of the triangle.
   @param p0 BasePart? - Optional first wedge part to use. If nil, a new part will be created.
   @param p1 BasePart? - Optional second wedge part to use. If nil, a new part will be created.
   @return BasePart, BasePart - The two wedge parts forming the triangle.

   I think sravant wrote this originally, I just added types.

   ```luau

   local triangle = require(path.to.triangle_module)
   local part1, part2 = triangle.draw(Vector3.new(0,0,0), Vector3.new(1,0,0), Vector3.new(0,1,0))
   part1.Parent = workspace
   part2.Parent = workspace

   ```
]]
function triangle_module.draw(v1: Vector3, v2: Vector3, v3: Vector3, p0: BasePart, p1: BasePart)
	local s1 = (v1 - v2).Magnitude
	local s2 = (v2 - v3).Magnitude
	local s3 = (v3 - v1).Magnitude

	local smax = math.max(s1, s2, s3)

	local A: Vector3, B: Vector3, C: Vector3

	if s1 == smax then
		A, B, C = v1, v2, v3
	elseif s2 == smax then
		A, B, C = v2, v3, v1
	elseif s3 == smax then
		A, B, C = v3, v1, v2
	end

	local para = ((B - A).X * (C - A).X + (B - A).Y * (C - A).Y + (B - A).Z * (C - A).Z) / (A - B).Magnitude

	local perp = math.sqrt((C - A).Magnitude ^ 2 - para * para)

	local dif_para = (A - B).Magnitude - para

	local st = CFrame.new(B, A)
	local za = CFrame.Angles(math.pi / 2, 0, 0)

	local cf0 = st

	local Top_Look = (cf0 * za).LookVector
	local Mid_Point = A + CFrame.new(A, B).LookVector * para
	local Needed_Look = CFrame.new(Mid_Point, C).LookVector

	local dot = Top_Look.X * Needed_Look.X + Top_Look.Y * Needed_Look.Y + Top_Look.Z * Needed_Look.Z

	local ac = CFrame.Angles(0, 0, math.acos(dot))

	cf0 = cf0 * ac

	if ((cf0 * za).LookVector - Needed_Look).Magnitude > 0.01 then
		cf0 = cf0 * CFrame.Angles(0, 0, -2 * math.acos(dot))
	end

	cf0 = cf0 * CFrame.new(0, perp / 2, -(dif_para + para / 2))

	local cf1 = st * ac * CFrame.Angles(0, math.pi, 0)

	if ((cf1 * za).LookVector - Needed_Look).Magnitude > 0.01 then
		cf1 = cf1 * CFrame.Angles(0, 0, 2 * math.acos(dot))
	end

	cf1 = cf1 * CFrame.new(0, perp / 2, dif_para / 2)

	if not p0 then
		p0 = Instance.new("Part")
		p0.Name = "TrianglePart0"
		p0.Anchored = true
		p0.CanCollide = false
		p0.CastShadow = false
		p0.Material = Enum.Material.Plastic
		p0.Size = Vector3.one * 0.2

		local mesh = Instance.new("SpecialMesh")
		mesh.Parent = p0
		mesh.MeshType = Enum.MeshType.Wedge
		mesh.Name = "WedgeMesh"
	end

	local wedge_mesh = p0:FindFirstChild("WedgeMesh") :: SpecialMesh
	if not wedge_mesh then
		wedge_mesh = Instance.new("SpecialMesh")
		wedge_mesh.Parent = p0
		wedge_mesh.MeshType = Enum.MeshType.Wedge
		wedge_mesh.Name = "WedgeMesh"
	end

	wedge_mesh.Scale = Vector3.new(0, perp / 0.2, para / 0.2)

	p0.CFrame = cf0

	if not p1 then
		p1 = p0:Clone()
	end

	wedge_mesh.Scale = Vector3.new(0, perp / 0.2, dif_para / 0.2)
	p1.CFrame = cf1
	return p0, p1
end

return triangle_module
