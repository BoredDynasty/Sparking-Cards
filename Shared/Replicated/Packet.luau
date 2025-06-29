--!strict
--[[
	Packet.luau
	bytenet packet definitions for network communication.
	This module defines the structure of data sent between server and client.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local bytenet = require(ReplicatedStorage.Packages.bytenet)

-- Define a type for the TargetInfo dictionary to improve clarity
type TargetInfo = {
	targetPosition: Vector3?, -- Optional world position (e.g., mouse hit)
	targetInstanceId: number?, -- Optional InstanceId of a target object (e.g., for targeted abilities)
}

-- Define a type for common effect parameters
type EffectParams = {
	position: Vector3?, -- World position for the effect
	sourcePlayerId: number?, -- UserId of the player initiating the effect
	targetPlayerId: number?, -- UserId of the player targeted by the effect
	attachToInstanceId: number?, -- InstanceId to attach the effect to
	customData: { [string]: any }?, -- For any other effect-specific data
}

return bytenet.defineNamespace("MainNet", function()
	-- General Game Packets (Non-Combat)
	local newMatchStruct = bytenet.struct({
		[1] = bytenet.nothing, -- Placeholder, structure can be expanded
	})
	local removeMatchStruct = bytenet.struct({
		matchInstance = bytenet.inst, -- Instance of the match to be removed
	})
	local requestStreamStruct = bytenet.struct({
		areaCenter = bytenet.vec3, -- Center of the area to stream
	})
	local sendNotificationStruct = bytenet.struct({
		message = bytenet.string, -- Notification message content
		title = bytenet.optional(bytenet.string), -- Optional title for the notification
	})
	local buyCardStruct = bytenet.struct({
		cardName = bytenet.string, -- Name/ID of the card to purchase
	})
	local giveExperienceStruct = bytenet.struct({
		amount = bytenet.int16, -- Amount of experience to reward
	})
	local rankUpStruct = bytenet.struct({
		rankName = bytenet.string, -- New rank name
		rankLevel = bytenet.int32, -- New rank level
	})
	local sellCardStruct = bytenet.struct({
		playerInstance = bytenet.inst, -- Player instance selling the card (server might get this from packet sender)
		cardName = bytenet.string, -- Name/ID of the card to sell
	})
	local payBigCardsStruct = bytenet.struct({ -- Assuming "Big Cards" is a currency or item
		amount = bytenet.int16,
		recipientUsername = bytenet.string,
	})
	local raycastValidationStruct = bytenet.struct({ -- For general raycast validation, e.g. client interactions
		hitModelName = bytenet.string, -- Name of the model that was hit
	})
	local sprintStruct = bytenet.struct({
		staminaCost = bytenet.int8, -- Stamina cost of the sprint action
		isSprinting = bytenet.bool, -- True if starting to sprint, false if stopping
	})

	-- Orion Combat Framework Packets
	local orionExecuteAttackRequest = bytenet.struct({
		attackName = bytenet.string, -- Unique identifier for the attack being executed
		equippedIdentifier = bytenet.string, -- Identifier for the equipped item (e.g., card name, weapon ID)
		-- Optional dictionary for targeting information, like mouse position or target entity.
		targetInfo = bytenet.optional(bytenet.dictionary(bytenet.any)), -- `bytenet.any` used for flexibility; ensure consistent usage. Corresponds to TargetInfo type.
	})

	local orionPlayerStateChangedNotif = bytenet.struct({
		playerId = bytenet.uint32, -- UserId of the player whose state changed
		newState = bytenet.string, -- Name of the new state (e.g., "Attacking", "Stunned")
		-- Optional parameters for the new state, e.g., { stunDuration = 2 }.
		-- Using `bytenet.any` for flexibility. Careful handling required by sender/receiver.
		stateParams = bytenet.optional(bytenet.dictionary(bytenet.any)),
	})

	local orionClientHitNotif = bytenet.struct({
		targetInstanceId = bytenet.uint32, -- InstanceId of the character model (or relevant part) that was hit
		hitPosition = bytenet.vec3, -- Precise world position of the hit
		attackName = bytenet.string, -- Identifier of the attack that registered the hit
		weaponIdentifier = bytenet.string, -- Identifier for the weapon/card that made the attack
		-- Optional data for server-side validation of the client's raycast (e.g., from clientcast module).
		validationRaycastData = bytenet.optional(bytenet.dictionary(bytenet.any)),
	})

	local orionPlayEffectNotif = bytenet.struct({
		effectName = bytenet.string, -- Identifier for the visual/audio effect to play
		-- Dictionary containing parameters for the effect. Corresponds to EffectParams type.
		effectParams = bytenet.dictionary(bytenet.any), -- `bytenet.any` used for flexibility; ensure structure matches EffectParams.
	})

	return {
		-- General Game Packets
		CreateMatch = bytenet.definePacket({ value = newMatchStruct }),
		CancelMatch = bytenet.definePacket({ value = removeMatchStruct }),
		StreamArea = bytenet.definePacket({ value = requestStreamStruct }),
		SendNotification = bytenet.definePacket({ value = sendNotificationStruct }),
		BuyCard = bytenet.definePacket({ value = buyCardStruct }),
		RewardExperience = bytenet.definePacket({ value = giveExperienceStruct }),
		AscendRank = bytenet.definePacket({ value = rankUpStruct }),
		SellCard = bytenet.definePacket({ value = sellCardStruct }),
		PayBigCards = bytenet.definePacket({ value = payBigCardsStruct }),
		SprintRemote = bytenet.definePacket({ value = sprintStruct }),
		RayValidation = bytenet.definePacket({	value = raycastValidationStruct }), -- For general client-side raycast validation

		-- Orion Combat Packets
		Orion_ExecuteAttackRequest = bytenet.definePacket({
			value = orionExecuteAttackRequest,
			reliable = true, -- Attack requests should be reliable
		}),
		Orion_PlayerStateChangedNotif = bytenet.definePacket({
			value = orionPlayerStateChangedNotif,
			reliable = true, -- State changes are important and should be reliable
		}),
		Orion_ClientHitNotif = bytenet.definePacket({
			value = orionClientHitNotif,
			reliable = false, -- Hit notifications can be unreliable as server validates; consider reliability based on game feel.
		}),
		Orion_PlayEffectNotif = bytenet.definePacket({
			value = orionPlayEffectNotif,
			reliable = false, -- Effects are often cosmetic and can tolerate unreliability
		}),
	}
end)
