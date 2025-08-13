--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local orion = require(ReplicatedStorage.Combat.orion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- block.luau

return function(player: playerMarshaller.player)
	local character = player.Character
	local state = orion.player_data[player.UserId].states
	if state:getCurrentState() == "Blocking" then
		return
	else
		state:transition("Blocking")
	end
	damage.incoming:Connect(function(target: damage.Damage)
		if target.target == player then
			target.amount = 0 -- yep...
			-- just to make sure
			damage.cancel:Fire()
		end
	end)
	-- play the animation
	Packet.ReplicateAnimation.sendTo({ identification = "15069707005" }, player)
end
