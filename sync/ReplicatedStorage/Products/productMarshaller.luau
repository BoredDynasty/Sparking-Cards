--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- productMarshaller.luau

local product_mt = setmetatable({}, {})

function product_mt.new(product: typemarshaller.Product)
	assert(product, "Did you forget to input a product?")

	table.insert(product_mt, product)
end

function product_mt.remove(product: typemarshaller.Product)
	assert(product, "Did you forget to input a product?")

	local needle = table.find(product_mt, product)

	if needle then
		table.remove(product_mt, needle)
	end
end

function product_mt.get(id: number): typemarshaller.ProductInfo?
	local ok, result = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, Enum.InfoType.Asset)

	if ok then
		return result
	else
		print("Couldn't get product info: ", result)
		return nil
	end
end

--[[
	Use the `pages.luau` module to format.
]]
function product_mt.get_all()
	return MarketplaceService:GetDeveloperProductsAsync()
end

local __call = function(receiptInfo: typemarshaller.ReceiptInfo)
	local user_id = receiptInfo.PlayerId
	local product_id = receiptInfo.ProductId

	local player = playerMarshaller.getByUserId(user_id)
	if player then
		local product_data = nil :: typemarshaller.Product?

		-- get our data
		for i, data: typemarshaller.Product in pairs(product_mt :: { typemarshaller.Product }) do
			if data.Id == product_id then
				product_data = data
			end
		end

		if not product_data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local handler = product_data.Callback

		local ok, result = pcall(handler, receiptInfo, player)

		if ok then
			-- The user has received their items
			-- Returns "PurchaseGranted" to confirm the transaction
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("Failed to process receipt:", receiptInfo, result)
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

product_mt._call = __call

return product_mt
