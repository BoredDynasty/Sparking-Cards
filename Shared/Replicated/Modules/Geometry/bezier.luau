--!strict

-- bezier.luau

local BezierCurve = {}
BezierCurve.__index = BezierCurve

-- Cache for factorial results
local factorialCache: { [number]: number } = {}

export type BezierCurve = {
	controlPoints: { vector },
	new: (controlPoints: { vector }) -> BezierCurve,
	getPoint: (self: BezierCurve, t: number) -> vector,
	bernstein: (self: BezierCurve, n: number, i: number, t: number) -> number,
	binomial: (self: BezierCurve, n: number, i: number) -> number,
	factorial: (self: BezierCurve, n: number) -> number,
}

type self = {
	controlPoints: { vector },
}

export type meta = {
	__index: meta,
	new: typeof(BezierCurve.new),
	getPoint: typeof(BezierCurve.getPoint),
	bernstein: typeof(BezierCurve.bernstein),
	binomial: typeof(BezierCurve.binomial),
	factorial: typeof(BezierCurve.factorial),
}

export type Curve = setmetatable<self, meta>

function BezierCurve.new(controlPoints: { vector }): Curve
	assert(#controlPoints >= 2, "At least two control points are required")

	local self = setmetatable({}, BezierCurve)

	self.controlPoints = controlPoints

	return self
end

function BezierCurve:getPoint(t: number): vector
	assert(t >= 0 and t <= 1, "Parameter t must be between 0 and 1")

	local n = #self.controlPoints

	local point = vector.zero

	for i = 1, n do
		local b = self:bernstein(n - 1, i - 1, t)
		point += self.controlPoints[i] * b
	end
	return point
end

function BezierCurve:bernstein(n: number, i: number, t: number): number
	return self:binomial(n, i) * math.pow(t, i) * math.pow(1 - t, n - i)
end

function BezierCurve:binomial(n: number, i: number): number
	return self:factorial(n) / (self:factorial(i) * self:factorial(n - i))
end

function BezierCurve:factorial(n: number): number
	assert(n >= 0, "Factorial is only defined for non-negative integers")

	if factorialCache[n] then
		return factorialCache[n]
	end

	if n == 0 then
		return 1
	end

	local result = n * self:factorial(n - 1)
	factorialCache[n] = result
	return result
end

return BezierCurve
