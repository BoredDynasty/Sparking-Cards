--!strict
local Players = game:GetService("Players")

-- nearest
-- a function for finding the nearest player within a radius

export type NearestOptions = {
	exclude_player: Player?,
	field_of_view: number?,
	require_alive: boolean?,
}

local function is_in_view(root: BasePart, other_root: BasePart, field_of_view: number?): boolean
	if not field_of_view then
		return true
	end

	local resultant = other_root.Position - root.Position
	if resultant.Magnitude <= 0 then
		return true
	end

	local dot = math.clamp(root.CFrame.LookVector:Dot(resultant.Unit), -1, 1)
	local angle = math.deg(math.acos(dot))

	return angle <= field_of_view
end

return function(root: BasePart?, max_distance: number, options: NearestOptions?)
	local nearest_players: { Player }, distances: { number } = {}, {}
	if not root then
		return nearest_players, distances
	end

	for i, player in ipairs(Players:GetPlayers()) do
		if options and options.exclude_player == player then
			continue
		end

		local character = player.Character
		if not character then
			continue
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if options and options.require_alive and (not humanoid or humanoid.Health <= 0) then
			continue
		end

		local other_root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not other_root then
			continue
		end

		local distance = (other_root.Position - root.Position).Magnitude

		if distance > max_distance then
			continue
		end

		if not is_in_view(root, other_root, options and options.field_of_view or nil) then
			continue
		end

		table.insert(nearest_players, player)
		table.insert(distances, distance)
	end

	return nearest_players, distances
end
