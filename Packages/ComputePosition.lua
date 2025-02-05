return function(a, b)
	local c = b <= 3 and 1 or math.ceil((math.pow(b, 1 / 3)))
	local ceil_ret = math.ceil(b / c)
	local floor_ret = math.floor(b / ceil_ret)
	c = b - ceil_ret * floor_ret
	local floor_ret2 = math.floor((a - 1) / ceil_ret)
	return Vector2.new((a - 1) % ceil_ret + 0.5) / (floor_ret2 < floor_ret and ceil_ret or c),
		Vector2.new(floor_ret2 % c + 0.5) / c
end
