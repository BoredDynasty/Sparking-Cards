--!strict

-- badges.luau

export type badge = {
	name: string,
	description: string,
	points: number,
	date_acquired: number, -- unix timestamp millis
}

return {
	{
		name = "First Victory",
		description = "Win your first match",
		points = 10,
	},
	{
		name = "Card Collector",
		description = "Collect all card types",
		points = 20,
	},
}
