--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)

-- productMarshaller.luau

export type productTable = {
	[string]: {
		name: string,
		description: string,
		identification: number,
		cost: number,
	},
}

return {
	products = {
		["Extra Cards"] = {
			name = "Extra Cards",
			description = [[
            Buy yourself 50 Extra Cards!
         ]],
			identification = 1904591683,
			cost = 15.00,
		},
		["Donation"] = {
			name = "Donation",
			description = [[
            Thanks for donating!
         ]],
			identification = 1906572512,
			cost = 20.00,
		},
	} :: productTable,
	product_callbacks = {} :: { (receipt: (any | string)?, player: playerMarshaller.player) -> boolean },
	processReceipt = function(receiptInfo: { PlayerId: number, ProductId: number }, product_callbacks)
		local userId = receiptInfo.PlayerId :: number
		local productId = receiptInfo.ProductId :: number

		local player = playerMarshaller.getByUserId(userId) :: playerMarshaller.player

		if player then
			local handler = product_callbacks[productId]

			if not handler then
				warn("No handler for productId: " .. productId)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			promise
				.try(handler, receiptInfo, player)
				:andThen(function()
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end)
				:catch(function(...)
					warn(`product purchase went wrong somewhere : {receiptInfo}, {...}`)
				end)
		end
		--[[
	if player then
		-- Get the handler function associated with the developer product ID and attempt to run it
		local handler = productFunctions[productId]
		local success, result = pcall(handler, receiptInfo, player)
		if success then
			-- The user has received their benefits
			-- Return "PurchaseGranted" to confirm the transaction
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("Failed to process receipt: ", receiptInfo, result)
		end
	end
	]]

		-- The user's benefits couldn't be awarded
		-- Return "NotProcessedYet" to try again next time the user joins
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end,
}
