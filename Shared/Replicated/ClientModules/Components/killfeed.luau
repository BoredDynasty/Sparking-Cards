--!strict

-- killfeed.luau

-- a killfeed inspired by this twitter post
-- https://x.com/KenamiRBX/status/2061578219111755998

local module = {}

export type SpecialElimination = {
	{
		name: string, -- what was so *extraordinary* about this elimination? e.g. "Headshot", "Backstab", "Pyro Reaction"
		experience: number, -- the number of experience points awarded for this elimination
	}
}

function module.create_entry(target: string, total_exp: number, special_elimination: SpecialElimination?)
	--
end
