--!nocheck

local AppendStyle = {}

-- // Requires

local Style = require(script.Parent.Parent)
local _, theme = Style.getGameStyle()

local Button = require(script.Button)
local Canvas = require(script.Canvas)

function AppendStyle:automaticStyling(objects: {}, name: string)
	for _, object: GuiObject in pairs(objects) do
		-- // Button
		if object:IsA("TextButton") or object:IsA("ImageButton") then
			Button(object, name)
		elseif object:IsA("Frame") or object:IsA("ScrollingFrame") or object:IsA("CanvasGroup") then
			Canvas(object, name, theme)
		end
	end
end

return AppendStyle
