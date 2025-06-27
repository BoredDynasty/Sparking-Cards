--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

-- states.luau

return {
	new = function(player: playerMarshaller.player)
		local state = statemachine.new({
			attacking = {
				name = "attacking",
				transitions = {
					neutral = "neutral",
					blocking = "blocking",
				},
			},
			neutral = {
				name = "neutral",
				transitions = {
					attacking = "attacking",
					blocking = "blocking",
				},
			},
			blocking = {
				name = "blocking",
				transitions = {
					attacking = "attacking",
					neutral = "neutral",
				},
			},
		}, "neutral")
		return state
	end,
}
