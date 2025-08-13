--!strict

-- magnitude.luau

local function update(player: BasePart, victim: BasePart, range: number, limit: number)
	local lookVector = player.CFrame.LookVector
	local resultant = victim.Position - player.Position
	local distance = resultant.Magnitude

	-- calculate
	local dot = lookVector:Dot(resultant.Unit)
	local arcCosine = math.acos(dot)
	local angle = math.deg(arcCosine)

	local hit = distance < range and angle < limit
	-- check
	if hit then
		return true
	else
		return false
	end
end

return {
	magnitude = update,
}
