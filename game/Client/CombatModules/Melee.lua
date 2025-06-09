--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MouseRaycast = require(StarterPlayer.StarterPlayerScripts.Utilities.MouseRaycast)
local characterUtility = require(ReplicatedStorage.Utility.character)

return function(player: Player)
	local character = characterUtility.get(player)
	local maxDistance = 5
	local raycast = MouseRaycast({ character })
	if not raycast then
		return
	end
	if not raycast.Instance or not raycast.Position then
		return
	end
	if math.floor(raycast.Distance) <= maxDistance then
		task.delay(10, function()
			print("punch")
			print(raycast.Instance, raycast.Position)
		end)
	end
end
