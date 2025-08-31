--!nonstrict
--[[
	Packet.luau
	bytenet packet definitions for network communication.
	This module defines the structure of data sent between server and client.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local bytenet = require(ReplicatedStorage.Packages.bytenet)

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
		type = bytenet.optional(bytenet.string),
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
	local payPrismsStruct = bytenet.struct({
		amount = bytenet.int16,
		recipientUsername = bytenet.string,
	})
	local raycastValidationStruct =
		bytenet.struct({ -- For general raycast validation, e.g. client interactions
			hitModelName = bytenet.string, -- Name of the model that was hit
		})
	local sprintStruct = bytenet.struct({
		walkSpeed = bytenet.int8, -- Stamina cost of the sprint action
		isSprinting = bytenet.bool, -- True if starting to sprint, false if stopping
	})
	local profileChangedStruct = bytenet.struct({
		[1] = bytenet.nothing,
	})
	local replicateAnimation = bytenet.struct({
		identification = bytenet.string, -- The animation ID should be formatted into a string.
	})
	local cancelAnimation = bytenet.struct({
		identification = bytenet.string,
	})
	local stopAllAnimations = bytenet.struct({
		[1] = bytenet.nothing,
	})
	local indictEffectStruct = bytenet.struct({
		text = bytenet.string,
	})
	local deductStaminaStruct = bytenet.struct({
		amount = bytenet.int16, -- Amount of stamina to deduct
	})
	local addStaminaStruct = bytenet.struct({
		amount = bytenet.int16, -- Amount of stamina to add
	})
	local parrySuccess = bytenet.struct({
		[1] = bytenet.nothing, -- Placeholder for future data
	})
	local parryResult = bytenet.struct({
		[1] = bytenet.unknown,
		[2] = bytenet.unknown,
	})
	local attemptParryStruct = bytenet.struct({
		[1] = bytenet.nothing,
	})
	local shakeCamera = bytenet.struct({
		intensity = bytenet.float32, -- Intensity of the camera shake
		duration = bytenet.float32, -- Duration of the camera shake
	})
	local shakeFromAreaStruct = bytenet.struct({
		origin = bytenet.vec3, -- Origin point for the shake effect
		maxDistance = bytenet.float32, -- Maximum distance for the shake effect
		strength = bytenet.float32, -- Strength of the shake effect
	})
	local cleanupCharacter = bytenet.struct({
		[1] = bytenet.nothing, -- Placeholder for future data
	})
	local setNetworkOwnerStruct = bytenet.struct({
		player = bytenet.optional(bytenet.inst),
		object = bytenet.inst,
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
		PayPrisms = bytenet.definePacket({ value = payPrismsStruct }),
		SprintRemote = bytenet.definePacket({ value = sprintStruct }),
		RayValidation = bytenet.definePacket({ value = raycastValidationStruct }), -- For general client-side raycast validation
		profileChanged = bytenet.definePacket({ value = profileChangedStruct }),
		ReplicateAnimation = bytenet.definePacket({ value = replicateAnimation }),
		CancelAnimation = bytenet.definePacket({ value = cancelAnimation }),
		StopAllAnimations = bytenet.definePacket({ value = stopAllAnimations }),
		DeductStamina = bytenet.definePacket({ value = deductStaminaStruct }),
		AddStamina = bytenet.definePacket({ value = addStaminaStruct }),
		ParrySuccess = bytenet.definePacket({ value = parrySuccess }),
		AttemptParry = bytenet.definePacket({ value = attemptParryStruct }),
		ShakeCamera = bytenet.definePacket({ value = shakeCamera }),
		ShakeFromArea = bytenet.definePacket({ value = shakeFromAreaStruct }),
		CleanupCharacter = bytenet.definePacket({ value = cleanupCharacter }),
		IndictEffect = bytenet.definePacket({ value = indictEffectStruct }),
		SetNetworkOwner = bytenet.definePacket({ value = setNetworkOwnerStruct }),
	}
end)
