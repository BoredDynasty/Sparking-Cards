--!strict

-- story.luau

-- the main story manager
-- we will sort this with "Acts"
-- this'll basically just be a huge table with the ***story***
-- we'll make use of the cutscenes.
-- wip by the way.

type DialogEntry = {
	Character: string,
	Text: string,
	Actions: { [string]: () -> () }?, -- optional named actions executed when this dialog is shown
	TypewriterOpts: any?,
}

type Story = {
	act_name: string,
	act_number: number,

	time_period: { number }, -- 1 or 2 DateTime(s) representing how long the ingame Act is.

	characters_involved: { string }, -- character names

	-- the fun part
	phases: {
		{
			dialog_entries: { DialogEntry },
		}
	},
}

return {
	{
		act_name = "Obsidian",
	},
}
