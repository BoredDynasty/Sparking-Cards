--!strict

return function(root: BasePart, opponent_root: BasePart, range: number?, limit: number)
	range = range or 5
	limit = limit or 45

	local look_vec = root.CFrame.LookVector

	local resultant = opponent_root.Position - root.Position
	local distance = resultant.Magnitude

	local dot = look_vec:Dot(resultant.Unit)

	local radii_angle = math.acos(dot) -- arc cosine of the dot product
	local deg_angle = math.deg(radii_angle)

	local in_range = distance < range
	local in_view = deg_angle < limit
	-- are we looking the correct way to hit the opponent?

	local is_hit = in_range and in_view

	return is_hit
end
