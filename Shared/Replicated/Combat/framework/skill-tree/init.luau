--!strict

-- skill-tree.luau

local skill_chart = {
	-- TODO) expand here
}

export type skill_chart = {
	{
		name: string,
		description: string,
		cost: number,
		level_required: number, -- dont worry, we can convert level number to rank name
		requirements: { string? }, -- ahem, ALL skill requirements.
		next: { string? },
		locked_for_cards: { string? }, -- what cards can use this skill
		icon: Content | string, -- content or "rbxassetid://ASSET_ID"
	}
}
