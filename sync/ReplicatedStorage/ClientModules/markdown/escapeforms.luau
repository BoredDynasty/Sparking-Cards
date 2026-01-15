--!strict

-- escapeforms.luau

return {
	["<"] = "&lt;",
	[">"] = "&gt;",
	['"'] = "&quot;",
	["'"] = "&apos;",
	["&"] = "&amp;",
} :: { [string]: string }
