local Text = {}

-- // Requires
-- local SoundManager = require(script.Parent.SoundManager)

local function cleanupText(textlabel)
	local index = 0
	local text = " "

	if index >= #text then
		return text
	end

	print(text:sub(index, index))
	index = index + 1
	textlabel.Text = text
	task.wait(0.05)
end

local function stripRichText(text)
	-- Function to strip out rich text tags and return the pure text
	return string.gsub(text, "<.->", "")
end

local function markdownToRichText(input)
	-- Convert Bold: **text** → <b>text</b>
	input = string.gsub(input, "%*%*(.-)%*%*", "<b>%1</b>")
	-- Convert Italic: *text* → <i>text</i>
	input = string.gsub(input, "%*(.-)%*", "<i>%1</i>")
	-- Convert Underline: __text__ → <u>text</u>
	input = string.gsub(input, "__([^_]-)__", "<u>%1</u>")
	-- Convert Color: {#hexcolor|text} → <font color="hexcolor">text</font>
	input = string.gsub(input, "{#([%x]+)%|(.-)}", '<font color="#%1">%2</font>')

	return input
end

function Text.stripRichText(text)
	return stripRichText(text)
end

function Text.clean(textlabel)
	return cleanupText(textlabel)
end

function Text.TypewriterEffect(DisplayedText: string, TextLabel, speed)
	for i = 1, #DisplayedText do
		local str = string.sub(DisplayedText, i, #DisplayedText)
		TextLabel.Text = str
		task.wait(speed)
	end
end

function Text:MD_ToRichText(input): string
	return markdownToRichText(input)
end

function Text:Replace(input: string, replacement, pattern: string)
	return string.gsub(input, pattern, replacement)
end

return Text
