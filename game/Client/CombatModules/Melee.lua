--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local mousecast = require(StarterPlayer.StarterPlayerScripts.Utilities.mousecast)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local player = playerMarshaller.get()

return function(player: Player)
	local character = player.Character
	local maxDistance = 5
	local raycast = mousecast({ character })
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
