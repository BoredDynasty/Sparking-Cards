--!strict

-- magnitude.luau

local function update(player: BasePart?, victim: BasePart?, range: number?, limit: number?): boolean
	if not player or not victim then
		return false
	end

	range = range or 5
	limit = limit or 45

	local lookVector = player.CFrame.LookVector
	local resultant = victim.Position - player.Position
	local distance = resultant.Magnitude
	if distance <= 0 then
		return true
	end

	-- calculate
	local dot = math.clamp(lookVector:Dot(resultant.Unit), -1, 1)
	local arcCosine = math.acos(dot)
	local angle = math.deg(arcCosine)

	local hit = distance < range and angle < limit

	return hit
end

return {
	magnitude = update,
}
