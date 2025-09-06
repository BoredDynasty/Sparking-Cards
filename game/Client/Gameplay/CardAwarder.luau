--!strict

-- CardAwarder.luau

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardManager = require(ReplicatedStorage.ClientModules.CardManager)
local Fireworks = require(ReplicatedStorage.Modules.Fireworks)
local Packet = require(ReplicatedStorage.Packet)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- // Gameplay -- //

local player: Player = playerMarshaller.get()

local debounceDelay = 1

return function()
	debug.profilebegin("card_drop")
	for _, card: BasePart in CollectionService:GetTagged("collectible") :: { BasePart } do
		-- print(card.Name)
		local touchDebounce = false

		card.Touched:Connect(function(otherPart: BasePart)
			if touchDebounce then
				return
			end

			touchDebounce = true

			task.delay(debounceDelay, function()
				touchDebounce = false
			end)

			local parent = otherPart.Parent :: Model

			local otherPlayer = playerMarshaller.getFromCharacter(parent)

			if not otherPlayer then
				return
			end

			if otherPlayer == player then
				print("Touched Prism: " .. card.Name)

				local amount = card:GetAttribute("Award") :: number
				local dropAmount = amount

				CardManager:Drop(player, dropAmount)

				local character = player.Character

				Fireworks:PlayFireworks(character.HumanoidRootPart)

				Packet.PayPrisms.send({ amount = amount, recipientUsername = player.Name })

				print("sent req. to pay prisms!")

				task.delay(debounceDelay, function()
					card:Destroy()
				end)
			end
		end)
	end
	debug.profileend()
end
