--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local future = require(ReplicatedStorage.Packages.future)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- product-manager.luau

local module = {}

local products = {}

function module:GetAsync(id: number): typemarshaller.ProductInfo?
	local fut =
		future.Try(MarketplaceService.GetProductInfoAsync, MarketplaceService, id, Enum.InfoType.Asset)

	local ok, result = fut:Await()

	if ok then
		return result
	else
		print("Couldn't get product info: ", result)

		return nil
	end
end

--[[
	Use the `pages.luau` utility to format.
]]
function module:FetchAll()
	return MarketplaceService:GetDeveloperProductsAsync()
end

function module:FetchAllFromModule()
	return products
end

function module:InsertProduct(product: typemarshaller.Product)
	table.insert(products, product)
end

function module:FindProductById(id: number): typemarshaller.Product?
	for i, data in pairs(products) do
		if data.Id == id then
			return data
		end
	end

	return nil
end

function module:ProcessReceipt(receipt_info: typemarshaller.ReceiptInfo)
	local user_id = receipt_info.PlayerId
	local product_id = receipt_info.ProductId

	local player = Players:GetPlayerByUserId(user_id)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- what did they actually buy?
	local product_data = module:FindProductById(product_id)
	if not product_data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handler = product_data.Callback
	local ok, result = future.Try(handler, receipt_info, player):Await()
	if ok then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("Failed to process receipt:", receipt_info, result)

		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end
return module
