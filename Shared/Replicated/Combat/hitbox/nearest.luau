--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- nearest
-- a function for finding the nearest player within a radius

return function(root: BasePart, max_distance: number)
	local nearest_players, distances = {}, {}

	for i, player in ipairs(playerMarshaller.all()) do
		local character = player.Character
		if not character then
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

		table.insert(player, nearest_players)
		table.insert(distances, distance)
	end

	return nearest_players, distances
end
