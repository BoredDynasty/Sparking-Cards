--!strict

-- range-shift.luau

type range = { number }

--[[
   @param range_1 - The original range

   @param range_2 - The target range

   @param value - The number that falls within `range_1` and needs to be mapped to `range_2`

   Calculates the equivalent value of `value` in `range_2` using linear interpolation.
   Returns the mapped value by adjusting the proportion of `value` within `range_1` to `range_2`

   @return number

   ```luau

   local range_1 = { -1, 1 }
	local range_2 = { 0, 1 }

	local cosine = math.cos(radii_rotation)
	local sine = math.sin(radii_rotation)

	local x = range_shift(range_1, range_2, cosine)
	local y = range_shift(range_1, range_2, sine)

   dot.AnchorPoint = Vector2.new(x, y)
	dot.Position = UDim2.fromScale(x, y)
   
   ```
]]
return function(range_1: range, range_2: range, value: number)
	return range_2[1] + ((range_2[2] - range_2[1]) / range_1[2] - range_1[1])
end
