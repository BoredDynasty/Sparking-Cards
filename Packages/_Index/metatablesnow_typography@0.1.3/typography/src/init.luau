--! strict

local Typography = {}

export type FontWeight =
	"Thin"
	| "ExtraLight"
	| "Light"
	| "Regular"
	| "Medium"
	| "SemiBold"
	| "Bold"
	| "ExtraBold"
	| "Heavy"

local function formatColor(color)
	if typeof(color) == "Color3" then
		return "#" .. color:ToHex()
	elseif typeof(color) == "string" then
		return color
	else
		error("Invalid color type, expected Color3 or string, got " .. typeof(color))
	end
end

local function addFontAttribute(text: string, attribute: string, value: string): string
	local escapedAttribute = string.gsub(attribute, "([^%w])", "%%%1")
	local fontOpen = string.match(text, "^<font%s+([^>]+)>")

	if fontOpen then
		if string.find(fontOpen, escapedAttribute .. '%s*=%s*"[^"]*"') then
			local newTag =
				string.gsub(fontOpen, escapedAttribute .. '%s*=%s*"[^"]*"', attribute .. '="' .. value .. '"')
			return string.gsub(text, "^<font%s+([^>]+)>", "<font " .. newTag .. ">", 1)
		else
			local newTag = fontOpen .. " " .. attribute .. '="' .. value .. '"'
			return string.gsub(text, "^<font%s+([^>]+)>", "<font " .. newTag .. ">", 1)
		end
	else
		return "<font " .. attribute .. '="' .. value .. '">' .. text .. "</font>"
	end
end

function Typography.Color(text: string, color: Color3 | string): string
	return addFontAttribute(text, "color", formatColor(color))
end

function Typography.Size(text: string, size: number): string
	return addFontAttribute(text, "size", tostring(size))
end

function Typography.FontFace(text: string, fontId: string): string
	return addFontAttribute(text, "face", fontId)
end

function Typography.Weight(text: string, weight: string): string
	return addFontAttribute(text, "weight", weight)
end

function Typography.Transparency(text: string, transparency: string): string
	return addFontAttribute(text, "transparency", tostring(transparency))
end

function Typography.Stroke(
	text: string,
	color: Color3 | string,
	thickness: number?,
	joinMode: string?,
	transparency: number?
): string
	local formattedColor = formatColor(color)
	return '<stroke color="'
		.. formattedColor
		.. '" joins="'
		.. string.lower(joinMode or "Miter")
		.. '" thickness="'
		.. tostring(thickness or 1)
		.. '" transparency="'
		.. tostring(transparency or 0)
		.. '">'
		.. text
		.. "</stroke>"
end

function Typography.Bold(text: string): string
	return "<b>" .. text .. "</b>"
end

function Typography.Italic(text: string): string
	return "<i>" .. text .. "</i>"
end

function Typography.Underline(text: string): string
	return "<u>" .. text .. "</u>"
end

function Typography.Strikethrough(text: string): string
	return "<s>" .. text .. "</s>"
end

function Typography.LineBreak(): string
	return "<br/>"
end

function Typography.Uppercase(text: string): string
	return "<uppercase>" .. text .. "</uppercase>"
end

function Typography.Smallcaps(text: string): string
	return "<smallcaps>" .. text .. "</smallcaps>"
end

function Typography.Highlight(text: string, color: Color3 | string, transparency: number): string
	local formattedColor = formatColor(color)
	local transparencyAttribute = ' transparency="' .. (transparency or 0) .. '"'

	local fontStart, fontEnd = string.find(text, "^<font.->")
	local fontCloseStart = string.find(text, "</font>")

	if fontStart and fontCloseStart then
		local fontOpen = string.sub(text, fontStart, fontEnd)
		local innerText = string.sub(text, fontEnd + 1, fontCloseStart - 1)
		local fontClose = "</font>"

		local marked = '<mark color="'
			.. formattedColor
			.. '"'
			.. transparencyAttribute
			.. ">"
			.. innerText
			.. "</mark>"
		return fontOpen .. marked .. fontClose
	else
		return '<mark color="' .. formattedColor .. '"' .. transparencyAttribute .. ">" .. text .. "</mark>"
	end
end

function Typography.Comment(text: string): string
	return "<!--" .. text .. "-->"
end

script.Parent.Text =
	Underline(Bold(Color(FontFace("Hello, World", Typography.Fonts.Inter), Color3.fromRGB(111, 255, 44))))

return Typography
