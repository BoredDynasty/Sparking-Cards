--!strict

-- typemarshaller.luau

export type ReceiptInfo = {
	PlayerId: number,
	PlaceIdWherePurchased: number,
	PurchaseId: string,
	ProductId: number,
	-- deprecated
	CurrencyType: Enum.CurrencyType,
	CurrencySpent: number,
}

export type Product = {
	[string]: {
		Name: string,
		Details: string,
		Id: number,
		Cost: number,
		Callback: (...unknown) -> ...unknown,
	},
}

export type ProductInfo = {
	Name: string,
	Description: string,
	PriceInRobux: number,
	ProductId: number,
	ProductType: string,
	--[[
      ISO 6801
   ]]
	Created: string,
	--[[
      ISO 6801
   ]]
	Updated: string,
	ContentRatingTypeId: number,
	MinimumMembershipLevel: number,
	IsPublicDomain: boolean,
	TargetId: number,
}

return nil
