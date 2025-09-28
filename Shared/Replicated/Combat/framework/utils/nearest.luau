--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- nearest
-- a function for finding the nearest player within a radius

return function(root: BasePart, maxDistance: number)
	local nearestPlayer, nearestDistance
	for _, player in pairs(playerMarshaller.all()) do
		local character = player.Character
		local distance = player:DistanceFromCharacter(root.Position)
		if not character or distance > maxDistance or (nearestDistance and distance >= nearestDistance) then
			continue
		end
		nearestDistance = distance
		nearestPlayer = player
	end
	return nearestPlayer, nearestDistance
end
