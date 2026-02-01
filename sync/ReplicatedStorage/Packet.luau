--!strict
--[[
	Packet.luau
	@module Packet
	@desc Bytenet packet definitions for network communication.
	This module defines the structure of data sent between server and client.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local bytenet = require(ReplicatedStorage.Packages.bytenet)

return bytenet.defineNamespace("MainNet", function()
	--[=[
		@struct new_match_struct
		@desc Structure for creating a new match.
	]=]
	local new_match_struct = bytenet.struct({
		[1] = bytenet.nothing, -- Placeholder, structure can be expanded
	})

	--[=[
		@struct remove_match_struct
		@desc Structure for removing a match.
	]=]
	local remove_match_struct = bytenet.struct({
		match_instance = bytenet.inst, -- Instance of the match to be removed
	})

	--[=[
		@struct request_stream_struct
		@desc Structure for requesting area stream.
	]=]
	local request_stream_struct = bytenet.struct({
		area_center = bytenet.vec3, -- Center of the area to stream
	})

	--[=[
		@struct send_notification_struct
		@desc Structure for sending notifications.
	]=]
	local send_notification_struct = bytenet.struct({
		message = bytenet.string, -- Notification message
		duration = bytenet.optional(bytenet.int8), -- Duration in seconds
	})

	--[=[
		@struct buy_card_struct
		@desc Structure for buying a card.
	]=]
	local buy_card_struct = bytenet.struct({
		card_name = bytenet.string, -- Name/ID of the card to purchase
	})

	--[=[
		@struct buy_skill_struct
		@desc Structure for buying a skill in the skill tree.
	]=]
	local buy_skill_struct = bytenet.struct({
		skill_name = bytenet.string,
	})

	--[=[
		@struct skill_purchased_struct
		@desc Structure sent to the client when a skill is purchased.
	]=]
	local skill_purchased_struct = bytenet.struct({
		skill_name = bytenet.string,
		remaining_affinity = bytenet.int16,
	})

	--[=[
		@struct give_experience_struct
		@desc Structure for rewarding experience.
	]=]
	local give_experience_struct = bytenet.struct({
		amount = bytenet.int16, -- Amount of experience to reward
	})

	--[=[
		@struct rank_up_struct
		@desc Structure for ascending rank.
	]=]
	local rank_up_struct = bytenet.struct({
		rank_name = bytenet.string, -- New rank name
		rank_level = bytenet.int32, -- New rank level
	})

	--[=[
		@struct sell_card_struct
		@desc Structure for selling a card.
	]=]
	local sell_card_struct = bytenet.struct({
		card_name = bytenet.string, -- Name/ID of the card to sell
	})

	--[=[
		@struct pay_prisms_struct
		@desc Structure for paying prisms.
	]=]
	local pay_prisms_struct = bytenet.struct({
		amount = bytenet.int16,
		recipient_username = bytenet.string,
	})

	--[=[
		@struct sprint_struct
		@desc Structure for sprinting actions.
	]=]
	local sprint_struct = bytenet.struct({
		walk_speed = bytenet.int8, -- Stamina cost of the sprint action
		is_sprinting = bytenet.bool, -- True if starting to sprint, false if stopping
	})

	--[=[
		@struct replicate_animation_struct
		@desc Structure for replicating animations.
	]=]
	local replicate_animation_struct = bytenet.struct({
		identification = bytenet.string, -- The animation ID should be formatted into a string.
	})

	--[=[
		@struct cancel_animation_struct
		@desc Structure for cancelling animations.
	]=]
	local cancel_animation_struct = bytenet.struct({
		identification = bytenet.string,
	})

	--[=[
		@struct stop_all_animations_struct
		@desc Structure for stopping all animations.
	]=]
	local stop_all_animations_struct = bytenet.struct({
		[1] = bytenet.nothing,
	})

	--[=[
		@struct indict_effect_struct
		@desc Structure for indicting effects.
	]=]
	local indict_effect_struct = bytenet.struct({
		text = bytenet.string,
	})

	--[=[
		@struct deduct_stamina_struct
		@desc Structure for deducting stamina.
	]=]
	local deduct_stamina_struct = bytenet.struct({
		amount = bytenet.int16, -- Amount of stamina to deduct
	})

	--[=[
		@struct add_stamina_struct
		@desc Structure for adding stamina.
	]=]
	local add_stamina_struct = bytenet.struct({
		amount = bytenet.int16, -- Amount of stamina to add
	})

	--[=[
		@struct cleanup_character_struct
		@desc Structure for cleaning up character.
	]=]
	local cleanup_character_struct = bytenet.struct({
		[1] = bytenet.nothing, -- Placeholder for future data
	})

	--[=[
		@struct set_network_owner_struct
		@desc Structure for setting network owner.
	]=]
	local set_network_owner_struct = bytenet.struct({
		player = bytenet.optional(bytenet.inst),
		object = bytenet.inst,
	})

	--[=[
		@struct add_quest_struct
		@desc Structure for adding a quest.
	]=]
	local add_quest_struct = bytenet.struct({
		player = bytenet.inst,
		quest_data = bytenet.string, -- Serialized quest data
	})

	--[=[
		@struct set_clock_time_struct
		@desc Structure for setting clock time.
	]=]
	local set_clock_time_struct = bytenet.struct({
		clock_time = bytenet.int8,
	})

	--[=[
		@struct melee_attack_struct
		@desc Structure for melee attacks.
	]=]
	local melee_attack_struct = bytenet.struct({
		weapon_name = bytenet.string,
	})

	local create_party_struct = bytenet.struct({
		settings = bytenet.map(bytenet.string, bytenet.unknown),
	})

	local delete_party_struct = bytenet.struct({
		party_id = bytenet.string,
	})

	local join_party_struct = bytenet.struct({
		party_id = bytenet.string,
	})

	local leave_party_struct = bytenet.struct({
		party_id = bytenet.string,
	})

	local request_queue_struct = bytenet.struct({
		[1] = bytenet.nothing,
	})

	local queue_info_struct = bytenet.struct({
		-- {userId: number, start: number}
		players = bytenet.array(bytenet.map(bytenet.string, bytenet.int32)),
		parties = bytenet.array(
			--[[{
				party_id: string,
				leader: number
				size: number,
				start: number
			}]]
			bytenet.map(bytenet.string, bytenet.unknown)
		),
	})

	local blow_fireworks_struct = bytenet.struct({
		amount = bytenet.int8,
		position = bytenet.vec3,
	})

	-- Packet definitions
	return {
		-- General Game Packets
		MeleeAttack = bytenet.definePacket({ value = melee_attack_struct }),
		CreateMatch = bytenet.definePacket({ value = new_match_struct }),
		CancelMatch = bytenet.definePacket({ value = remove_match_struct }),
		StreamArea = bytenet.definePacket({ value = request_stream_struct }),
		SendNotification = bytenet.definePacket({ value = send_notification_struct }),
		BuyCard = bytenet.definePacket({ value = buy_card_struct }),
		RewardExperience = bytenet.definePacket({ value = give_experience_struct }),
		AscendRank = bytenet.definePacket({ value = rank_up_struct }),
		SellCard = bytenet.definePacket({ value = sell_card_struct }),
		PayPrisms = bytenet.definePacket({ value = pay_prisms_struct }),
		ReplicateAnimation = bytenet.definePacket({ value = replicate_animation_struct }),
		CancelAnimation = bytenet.definePacket({ value = cancel_animation_struct }),
		StopAllAnimations = bytenet.definePacket({ value = stop_all_animations_struct }),
		-- Skill Tree
		BuySkill = bytenet.definePacket({ value = buy_skill_struct }),
		SkillPurchased = bytenet.definePacket({ value = skill_purchased_struct }),
		DeductStamina = bytenet.definePacket({ value = deduct_stamina_struct }),
		AddStamina = bytenet.definePacket({ value = add_stamina_struct }),
		CleanupCharacter = bytenet.definePacket({ value = cleanup_character_struct }),
		IndictEffect = bytenet.definePacket({ value = indict_effect_struct }),
		SetNetworkOwner = bytenet.definePacket({ value = set_network_owner_struct }),
		AddQuest = bytenet.definePacket({ value = add_quest_struct }),
		SetTime = bytenet.definePacket({ value = set_clock_time_struct }),
		CreateParty = bytenet.definePacket({ value = create_party_struct }),
		DeleteParty = bytenet.definePacket({ value = delete_party_struct }),
		JoinParty = bytenet.definePacket({ value = join_party_struct }),
		LeaveParty = bytenet.definePacket({ value = leave_party_struct }),
		BlowFirework = bytenet.definePacket({ value = blow_fireworks_struct }),
	}
end)
