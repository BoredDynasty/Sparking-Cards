--!strict

-- We've sunsetted the UIEffect Module.
-- We've replaced it with this.

local Easing = {}
Easing.__index = Easing

function Easing.new()
	local self = setmetatable({
		__tostring = "Easing",
		emphasized = 0.500, -- Begin and end on screen
		emphasized_decelerate = 0.400, -- Enter the screen
		emphasized_accelerate = 0.200, -- Exit the screen
		standard = 0.300, -- Begin and end on screen
		standard_decelerate = 0.250, -- Enter the screen
		standard_accelerate = 0.200, -- Exit the screen
	}, Easing)
	self.duration = 0.300 -- Measured in milliseconds
	-- Default duration
	return self
end

function Easing:Emphasized(alpha: number)
	-- Finely tuned parameters to do an emphasized curve

	local steepness = 5 -- Higher values make the initial drop steeper
	local offset = 0.1 -- Adjusts the starting point of the curve

	-- Exponential decay-like
	local easedAlpha = 1 - math.exp(-steepness * (alpha + offset))

	-- Normalize to the 0-1 range
	easedAlpha = easedAlpha / (1 - math.exp(-steepness * offset))

	return easedAlpha
end

function Easing:Emphasized_Accelerate(alpha: number): number
	-- Circular like
	return math.sqrt(1 - (alpha - 1) * (alpha - 1))
end

function Easing:Emphasized_Decelerate(alpha: number): number
	-- Something of a inverse quadratic ease out
	-- Very sigma
	return 1 - (1 - alpha) * (1 - alpha)
end

function Easing:Standard(alpha: number): number
	-- Softened ease out
	local power = 1.5 -- Controls curve sharpness

	return 1 - (1 - alpha) ^ power
end

function Easing:Standard_Accelerate(alpha: number): number
	-- Quad ease out
	return alpha * (2 - alpha)
end

function Easing:Standard_Decelerate(alpha: number): number
	-- same thing :skull:
	return self:Standard_Accelerate(alpha)
end

function Easing:Legacy(alpha: number): number
	-- Smooth step ease out
	return 1 - (1 - alpha) * (1 - alpha) * (3 - 2 * (1 - alpha))
end

return Easing
