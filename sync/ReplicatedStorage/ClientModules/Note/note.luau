--!strict

-- note.luau

local note = {}
export type dataType = {
	[string]: {
		Header: string,
		Provider: string,
		Body: string,
		--
		contentType: "Big" | "Wide" | "Small",
	},
}

note.notes = {
	["Quality"] = {
		Header = "Improving Sparking Cards on your end!",
		Provider = "Dynasty",
		Body = [[Did'ya know that the interface quality can <i>decrease</i> depending on your graphics quality? This is due to the game using CanvasGroups which can impact the quality of your UI. CanvasGroups bring nice UI animation To fix this, just bring up your graphics quality—it's that simple.
        ]],
		--
		contentType = "Wide",
	},
} :: dataType

return note
