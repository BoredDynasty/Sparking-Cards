--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- stun.luau

return function(player: playerMarshaller.player, duration: number)
	local character = player.Character
	local humanoid = character.Humanoid
	if humanoid then
		-- simple: walkspeed 0 for stun and apply Animation or tag
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			local oldWS = humanoid.WalkSpeed
			humanoid.WalkSpeed = 0
			task.delay(duration, function()
				if humanoid then
					humanoid.WalkSpeed = oldWS
				end
			end)
			Packet.DeductStamina.sendTo({ amount = 100 }, player)
		end
	end
end
--
