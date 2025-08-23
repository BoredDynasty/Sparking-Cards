--!strict

return function lerp(a: number, b: number, t: number)
	return a + (b - a) * math.clamp(t, 0, 1)
end