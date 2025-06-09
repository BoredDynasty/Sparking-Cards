--!nonstrict
--[[
	Packet.luau
	bytenet packet definitions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local bytenet = require(ReplicatedStorage.Packages.bytenet)

return bytenet.defineNamespace("MainNet", function()
	local newMatch = bytenet.struct({
		[1] = bytenet.nothing,
	}) -- lol
	local removeMatch = bytenet.struct({
		[1] = bytenet.inst,
	})
	local requestStream = bytenet.struct({
		[1] = bytenet.vec3, -- Area to stream
	})
	local sendNotification = bytenet.struct({
		[1] = bytenet.string, -- Notification
		[2] = bytenet.string, -- Title
	})
	local buyCard = bytenet.struct({
		[1] = bytenet.string, -- Card Name
	})
	local giveExperience = bytenet.struct({
		[1] = bytenet.int16, -- reward
	})
	local rankUp = bytenet.struct({
		[1] = bytenet.string,
		[2] = bytenet.int32,
	})
	local sellCard = bytenet.struct({
		[1] = bytenet.inst,
		[2] = bytenet.string,
	})
	local payBigCardsStruct = bytenet.struct({
		[1] = bytenet.int16,
		[2] = bytenet.string, -- username
	})
	local sprint = bytenet.struct({
		[1] = bytenet.int8,
		[2] = bytenet.bool,
	})
	local raycastValidation = bytenet.struct({
		[1] = bytenet.string,
	})
	return {
		createMatch = bytenet.definePacket({
			value = newMatch,
		}),
		cancelMatch = bytenet.definePacket({
			value = removeMatch,
		}),
		streamArea = bytenet.definePacket({
			value = requestStream,
		}),
		sendNotification = bytenet.definePacket({
			value = sendNotification,
		}),
		buyCard = bytenet.definePacket({
			value = buyCard,
		}),
		rewardExperience = bytenet.definePacket({
			value = giveExperience,
		}),
		ascendRank = bytenet.definePacket({
			value = rankUp,
		}),
		sellCard = bytenet.definePacket({
			value = sellCard,
		}),
		payBigCards = bytenet.definePacket({
			value = payBigCardsStruct,
		}),
		sprintRemote = bytenet.definePacket({
			value = sprint,
		}),
		rayValidation = bytenet.definePacket({
			value = raycastValidation,
		}),
	}
end)
