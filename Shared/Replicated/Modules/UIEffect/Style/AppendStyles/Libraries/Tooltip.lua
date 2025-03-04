--!nonstrict

-- Not finished yet

-- // Requires
local Curvy = require(script.Parent.Parent.Parent.Curvy)

local TooltipUI: ScreenGui

-- // Gui Definitions
local Canvas: CanvasGroup = TooltipUI.CanvasGroup :: CanvasGroup
local Frame: Frame = Canvas.Frame

local function setText(topic, details)
	Frame.Details.Text = topic .. "<br></br><br></br>" .. details
end

local function focus(value)
	if value == true then
		Canvas.GroupTransparency = 0
		Canvas.Visible = false
	else
		Canvas.GroupTransparency = 1
		Canvas.Visible = true
	end
end

return function(topic, details, value: boolean)
	Curvy:Curve(Canvas, nil, "GroupTransparency", 0)
	setText(topic, details)
	focus(value)
end
