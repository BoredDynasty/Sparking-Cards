--!strict

export type Skill = {
	name: string,
	description: string,
	icon: string,
	type: "major" | "minor",
	dependencies: {string},
}

local skills = {
	-- major skills
	["Major Skill 1"] = {
		name = "Major Skill 1",
		description = "This is a major skill.",
		icon = "rbxassetid://10723425852",
		type = "major",
		dependencies = {},
	},
	["Major Skill 2"] = {
		name = "Major Skill 2",
		description = "This is another major skill.",
		icon = "rbxassetid://10723425852",
		type = "major",
		dependencies = {"Major Skill 1"},
	},

	-- minor skills
	["Minor Skill 1"] = {
		name = "Minor Skill 1",
		description = "This is a minor skill.",
		icon = "rbxassetid://10723425852",
		type = "minor",
		dependencies = {"Major Skill 1"},
	},
	["Minor Skill 2"] = {
		name = "Minor Skill 2",
		description = "This is another minor skill.",
		icon = "rbxassetid://10723425852",
		type = "minor",
		dependencies = {"Major Skill 1"},
	},
	["Minor Skill 3"] = {
		name = "Minor Skill 3",
		description = "This is a minor skill.",
		icon = "rbxassetid://10723425852",
		type = "minor",
		dependencies = {"Major Skill 2"},
	},
	["Minor Skill 4"] = {
		name = "Minor Skill 4",
		description = "This is another minor skill.",
		icon = "rbxassetid://10723425852",
		type = "minor",
		dependencies = {"Major Skill 2"},
	},
}

return skills
