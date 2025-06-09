--!optimize 2
--!native

-- Elastic constants.
local elasticInP = 0.3
local elasticInA = 1.0
local elasticInS = elasticInP / 4
local elasticOutP = 0.3
local elasticOutA = 1.0
local elasticOutS = elasticOutP / 4
local elasticInOutP = 0.45
local elasticInOutA = 1.0
local elasticInOutS = elasticInOutP / 4

-- Back constants.
local backS = 1.70158
local backInOutS = backS * 1.525

-- Linear easing.
local function linear(alpha: number)
	return alpha
end

-- Quad easing.
local function inQuad(alpha: number)
	return alpha ^ 2
end
local function outQuad(alpha: number)
	return alpha * (2 - alpha)
end
local function inOutQuad(alpha: number)
	return if alpha < 0.5 then 0.5 * (alpha * 2) ^ 2 else 1 - 0.5 * ((1 - alpha) * 2) ^ 2
end
local function outInQuad(alpha: number)
	return if alpha < 0.5 then 0.5 * (alpha * 2) * (2 - alpha * 2) else 0.5 * ((2 * alpha - 1) ^ 2) + 0.5
end

-- Cubic easing.
local function inCubic(alpha: number)
	return alpha ^ 3
end
local function outCubic(alpha: number)
	return 1 + (alpha - 1) ^ 3
end
local function inOutCubic(alpha: number)
	alpha *= 2
	return if alpha < 1 then 0.5 * alpha ^ 3 else 0.5 * ((alpha - 2) ^ 3 + 2)
end
local function outInCubic(alpha: number)
	return if alpha < 0.5 then 0.5 * ((2 * alpha - 1) ^ 3 + 1) else 0.5 * (2 * alpha - 1) ^ 3 + 0.5
end

-- Quart easing.
local function inQuart(alpha: number)
	return alpha ^ 4
end
local function outQuart(alpha: number)
	return 1 - (alpha - 1) ^ 4
end
local function inOutQuart(alpha: number)
	alpha *= 2
	return if alpha < 1 then 0.5 * alpha ^ 4 else -0.5 * ((alpha - 2) ^ 4 - 2)
end
local function outInQuart(alpha: number)
	return if alpha < 0.5 then 0.5 * (1 - (alpha * 2 - 1) ^ 4) else 0.5 * ((2 * alpha - 1) ^ 4) + 0.5
end

-- Quint easing.
local function inQuint(alpha: number)
	return alpha ^ 5
end
local function outQuint(alpha: number)
	return 1 + (alpha - 1) ^ 5
end
local function inOutQuint(alpha: number)
	alpha *= 2
	return if alpha < 1 then 0.5 * alpha ^ 5 else 0.5 * ((alpha - 2) ^ 5 + 2)
end
local function outInQuint(alpha: number)
	return if alpha < 0.5 then 0.5 * ((2 * alpha - 1) ^ 5 + 1) else 0.5 * (2 * alpha - 1) ^ 5 + 0.5
end

-- Sine easing.
local function inSine(alpha: number)
	return 1 - math.cos(alpha * math.pi * 0.5)
end
local function outSine(alpha: number)
	return math.sin(alpha * math.pi * 0.5)
end
local function inOutSine(alpha: number)
	return 0.5 * (1 - math.cos(math.pi * alpha))
end
local function outInSine(alpha: number)
	return if alpha < 0.5
		then 0.5 * math.sin(alpha * math.pi)
		else 0.5 * (1 - math.cos((2 * alpha - 1) * math.pi * 0.5)) + 0.5
end

-- Exponential easing.
local function inExponential(alpha: number)
	return if alpha == 0 then 0 else 2 ^ (10 * (alpha - 1)) - 1e-3
end
local function outExponential(alpha: number)
	return if alpha == 1 then 1 else 1.001 * (1 - 2 ^ (-10 * alpha))
end
local function inOutExponential(alpha: number)
	if alpha == 0 then
		return 0
	end
	if alpha == 1 then
		return 1
	end
	return if alpha < 0.5
		then 0.5 * 2 ^ (10 * (2 * alpha - 1)) - 5e-4
		else 0.5 * 1.0005 * (2 - 2 ^ (-10 * (2 * alpha - 1)))
end
local function outInExponential(alpha: number)
	return if alpha < 0.5 then 0.5 * outExponential(alpha * 2) else 0.5 * (inExponential(2 * alpha - 1) + 1)
end

-- Circular easing.
local function inCircular(alpha: number)
	return 1 - math.sqrt(1 - alpha ^ 2)
end
local function outCircular(alpha: number)
	return math.sqrt(1 - (alpha - 1) ^ 2)
end
local function inOutCircular(alpha: number)
	alpha *= 2
	return if alpha < 1
		then 0.5 * (1 - math.sqrt(1 - alpha ^ 2))
		else 0.5 * (math.sqrt(1 - (alpha - 2) ^ 2) + 1)
end
local function outInCircular(alpha: number)
	return if alpha < 0.5 then 0.5 * outCircular(alpha * 2) else 0.5 * (inCircular(2 * alpha - 1) + 1)
end

-- Elastic easing.
local function inElastic(alpha: number)
	if alpha == 0 then
		return 0
	end
	if alpha == 1 then
		return 1
	end
	local t = alpha - 1
	return -elasticInA * 2 ^ (10 * t) * math.sin((t - elasticInS) * (2 * math.pi / elasticInP))
end
local function outElastic(alpha: number)
	if alpha == 0 then
		return 0
	end
	if alpha == 1 then
		return 1
	end
	return elasticOutA * 2 ^ (-10 * alpha) * math.sin((alpha - elasticOutS) * (2 * math.pi / elasticOutP)) + 1
end
local function inOutElastic(alpha: number)
	if alpha == 0 then
		return 0
	end
	if alpha == 1 then
		return 1
	end
	alpha *= 2
	local t = alpha - 1
	return if alpha < 1
		then -0.5 * elasticInOutA * 2 ^ (10 * t) * math.sin(
			(t - elasticInOutS) * (2 * math.pi / elasticInOutP)
		)
		else 0.5 * elasticInOutA * 2 ^ (-10 * t) * math.sin(
			(t - elasticInOutS) * (2 * math.pi / elasticInOutP)
		) + 1
end
local function outInElastic(alpha: number)
	return if alpha < 0.5 then 0.5 * outElastic(alpha * 2) else 0.5 * (inElastic(2 * alpha - 1) + 1)
end

-- Back easing.
local function inBack(alpha: number)
	return alpha ^ 2 * ((backS + 1) * alpha - backS)
end
local function outBack(alpha: number)
	local a = alpha - 1
	return a ^ 2 * ((backS + 1) * a + backS) + 1
end
local function inOutBack(alpha: number)
	alpha *= 2
	if alpha < 1 then
		return 0.5 * alpha ^ 2 * ((backInOutS + 1) * alpha - backInOutS)
	else
		alpha -= 2
		return 0.5 * (alpha ^ 2 * ((backInOutS + 1) * alpha + backInOutS) + 2)
	end
end
local function outInBack(alpha: number)
	return if alpha < 0.5 then 0.5 * outBack(alpha * 2) else 0.5 * (inBack(2 * alpha - 1) + 1)
end

-- Bounce easing.
local function outBounce(alpha: number)
	return if alpha < 1 / 2.75
		then 7.5625 * alpha ^ 2
		elseif alpha < 2 / 2.75 then 7.5625 * (alpha - 1.5 / 2.75) ^ 2 + 0.75
		elseif alpha < 2.5 / 2.75 then 7.5625 * (alpha - 2.25 / 2.75) ^ 2 + 0.9375
		else 7.5625 * (alpha - 2.625 / 2.75) ^ 2 + 0.984375
end
local function inBounce(alpha: number)
	return 1 - outBounce(1 - alpha)
end
local function inOutBounce(alpha: number)
	return if alpha < 0.5 then 0.5 * inBounce(2 * alpha) else 0.5 * outBounce(2 * alpha - 1) + 0.5
end
local function outInBounce(alpha: number)
	return if alpha < 0.5 then 0.5 * outBounce(2 * alpha) else 0.5 * inBounce(2 * alpha - 1) + 0.5
end

-- Map and return easing functions.
return {
	Linear = linear,
	Quad = {
		In = inQuad,
		Out = outQuad,
		InOut = inOutQuad,
		OutIn = outInQuad,
	},
	Cubic = {
		In = inCubic,
		Out = outCubic,
		InOut = inOutCubic,
		OutIn = outInCubic,
	},
	Quart = {
		In = inQuart,
		Out = outQuart,
		InOut = inOutQuart,
		OutIn = outInQuart,
	},
	Quint = {
		In = inQuint,
		Out = outQuint,
		InOut = inOutQuint,
		OutIn = outInQuint,
	},
	Sine = {
		In = inSine,
		Out = outSine,
		InOut = inOutSine,
		OutIn = outInSine,
	},
	Exponential = {
		In = inExponential,
		Out = outExponential,
		InOut = inOutExponential,
		OutIn = outInExponential,
	},
	Circular = {
		In = inCircular,
		Out = outCircular,
		InOut = inOutCircular,
		OutIn = outInCircular,
	},
	Elastic = {
		In = inElastic,
		Out = outElastic,
		InOut = inOutElastic,
		OutIn = outInElastic,
	},
	Back = {
		In = inBack,
		Out = outBack,
		InOut = inOutBack,
		OutIn = outInBack,
	},
	Bounce = {
		In = inBounce,
		Out = outBounce,
		InOut = inOutBounce,
		OutIn = outInBounce,
	},
}
