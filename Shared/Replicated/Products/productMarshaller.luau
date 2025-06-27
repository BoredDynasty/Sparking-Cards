--!strict

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
	product_callbacks = {} :: { (receipt: (any | string)?, player: Player) -> boolean },
}
