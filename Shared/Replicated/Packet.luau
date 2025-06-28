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
	local raycastValidation = bytenet.struct({
		[1] = bytenet.string, -- Model name that was hit
	})
	local sprint = bytenet.struct({
		[1] = bytenet.int8,
		[2] = bytenet.bool,
	})

	-- Orion Combat Framework Packets
	local orionExecuteAttackRequest = bytenet.struct({
		attackName = bytenet.string,
		equippedIdentifier = bytenet.string, -- e.g., card name or weapon ID
		targetInfo = bytenet.optional(bytenet.dictionary({ -- For things like mouse.Hit.p
			targetPosition = bytenet.optional(bytenet.vec3),
			targetInstanceId = bytenet.optional(bytenet.uint32), -- if targeting an instance
		})),
	})

	local orionPlayerStateChangedNotif = bytenet.struct({
		playerId = bytenet.uint32, -- Player.UserId
		newState = bytenet.string,
		stateParams = bytenet.optional(bytenet.dictionary(bytenet.any)), -- e.g., { stunDuration = 2 }
	})

	local orionClientHitNotif = bytenet.struct({
		targetInstanceId = bytenet.uint32, -- Instance ID of the character model hit (or relevant part)
		hitPosition = bytenet.vec3, -- World position of the hit
		attackName = bytenet.string, -- Which attack registered the hit
		weaponIdentifier = bytenet.string, -- Identifier for the weapon/card that made the attack
		validationRaycastData = bytenet.optional(bytenet.dictionary(bytenet.any)), -- For clientcast's ValidateRaycast
	})

	local orionPlayEffectNotif = bytenet.struct({
		effectName = bytenet.string, -- Identifier for the effect to play
		effectParams = bytenet.dictionary({ -- Parameters for the effect
			position = bytenet.optional(bytenet.vec3),
			sourcePlayerId = bytenet.optional(bytenet.uint32),
			targetPlayerId = bytenet.optional(bytenet.uint32),
			attachToInstanceId = bytenet.optional(bytenet.uint32),
			-- Add other common effect parameters as needed
			customData = bytenet.optional(bytenet.dictionary(bytenet.any)),
		}),
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
		rayValidation = bytenet.definePacket({
			value = raycastValidation,
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
		rayValidation = bytenet.definePacket({ -- This is likely used by clientcast, ensure it's compatible or adapt
			value = raycastValidation,
		}),

		-- Orion Packets
		Orion_ExecuteAttackRequest = bytenet.definePacket({
			value = orionExecuteAttackRequest,
		}),
		Orion_PlayerStateChangedNotif = bytenet.definePacket({
			value = orionPlayerStateChangedNotif,
		}),
		Orion_ClientHitNotif = bytenet.definePacket({
			value = orionClientHitNotif,
		}),
		Orion_PlayEffectNotif = bytenet.definePacket({
			value = orionPlayEffectNotif,
		}),
	}
end)
