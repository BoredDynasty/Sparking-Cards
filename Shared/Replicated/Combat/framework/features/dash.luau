--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local damage = require(ReplicatedStorage.Combat.Strike.damage)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- dash.luau

local dash = {}

local dashLength = 10

function dash.execute(player: playerMarshaller.player, direction: Vector3)
	-- Placeholder for dash execution logic
	-- This function would handle the player's dash action in the specified direction
	print(player.Name .. " dashes in direction: " .. tostring(direction))

	-- Implement dash logic here

	-- raycast in direction to see if theres a player

	local rootPart = player.Character.HumanoidRootPart

	local rayOrigin = rootPart.Position
	local rayDirection = direction.Unit * dashLength -- Cast the ray dashLength studs forward
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection)

	if raycastResult and raycastResult.Instance then
		local otherCharacter = raycastResult.Instance.Parent :: Model
		local hitPlayer = Players:GetPlayerFromCharacter(otherCharacter) :: playerMarshaller.player?
		if hitPlayer then
			print(player.Name .. " hit " .. hitPlayer.Name .. " while dashing!")
			-- Handle the hit player logic here, e.g., apply damage or effects
			damage.__call({ amount = 10, source = player, target = hitPlayer })
		end
	end

	-- move the player in the direction
	rootPart.CFrame += direction.Unit * dashLength
end
