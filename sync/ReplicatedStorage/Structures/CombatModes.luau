--!strict

export type dataType = {
	[string]: {
		["Name"]: string,
		["Icon"]: string,
	},
}

return {
	["Solo"] = {
		["Name"] = "Solo",
		["Icon"] = "rbxassetid://10747373176",
	},
	["AI"] = {
		["Name"] = "Vs. AI",
		["Icon"] = "rbxassetid://10734949856",
	},
} :: dataType
