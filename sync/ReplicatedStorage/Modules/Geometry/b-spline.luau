--!strict

-- b-spline.luau

local module = {}
module.__index = module

export type BSpline = {
	Degree: number,
	ControlPoints: { Vector3 },
	Knots: { number },
	Evaluate: (self: BSpline, t: number) -> Vector3,
	GetPoints: (self: BSpline, resolution: number) -> { Vector3 },
}

-- Create uniform knot vector
local function createUniformKnots(n: number, degree: number)
	local knots = {}
	local m = n + degree + 1

	for i = 0, m do
		table.insert(knots, i)
	end

	return knots
end

-- Cox–de Boor recursion formula
local function basis(i: number, k: number, t: number, knots: { number })
	if k == 0 then
		if knots[i] <= t and t < knots[i + 1] then
			return 1
		end
		return 0
	end

	local denom1 = knots[i + k] - knots[i]
	local denom2 = knots[i + k + 1] - knots[i + 1]

	local term1 = 0
	local term2 = 0

	if denom1 ~= 0 then
		term1 = (t - knots[i]) / denom1 * basis(i, k - 1, t, knots)
	end

	if denom2 ~= 0 then
		term2 = (knots[i + k + 1] - t) / denom2 * basis(i + 1, k - 1, t, knots)
	end

	return term1 + term2
end

--[[
   ```luau
   
   local b_spline = require(path.To.b_spline)

   local spline = b_spline.new({
       Vector3.new(0,0,0),
       Vector3.new(10,5,0),
       Vector3.new(20,0,0),
       Vector3.new(30,10,0),
       Vector3.new(40,0,0)
   }, 3)

   local points = spline:GetPoints(50)

   for _, p in ipairs(points) do
      local part = Instance.new("Part")
      part.Position = p
      part.Size = Vector3.one
      part.Anchored = true
      part.Parent = workspace
   end
   ```
]]
function module.new(controlPoints: { Vector3 }, degree: number?): BSpline
	local self = setmetatable({}, module)

	self.ControlPoints = controlPoints
	self.Degree = degree or 3
	self.Knots = createUniformKnots(#controlPoints, self.Degree)

	return self
end

function module:Evaluate(t: number): Vector3
	local n = #self.ControlPoints
	local degree = self.Degree
	local knots = self.Knots

	local minT = knots[degree + 1]
	local maxT = knots[n + 1]

	local scaledT = minT + (maxT - minT) * t

	local point = Vector3.zero

	for i = 1, n do
		local b = basis(i, degree, scaledT, knots)
		point += self.ControlPoints[i] * b
	end

	return point
end

function module:GetPoints(resolution: number): { Vector3 }
	local points = {}

	for i = 0, resolution do
		local t = i / resolution
		table.insert(points, self:Evaluate(t))
	end

	return points
end

return module
