-- // Requires

local Color = require(script.Parent.Parent.Parent.Parent.Color)

local function style(object: Frame | CanvasGroup | ScrollingFrame, name: string, theme: string)
	if theme == "Dark" and name == "Material 3" then
		object.BackgroundColor3 = Color.getColor("Black")
		object.BackgroundTransparency = 0
		object.BorderSizePixel = 0
		object.ClipsDescendants = true
		object.AutoLocalize = true
		object.ZIndex = 1
		object.Active = false
		object.Selectable = false
		object.Visible = true
		object.Draggable = false
		object.ScrollingEnabled = true
		object.ScrollBarThickness = 8
		object.ScrollBarImageColor3 = Color.getColor("Grey")
		object.ScrollBarImageTransparency = 0.9
	elseif theme == "Light" and name == "Material 3" then
		object.BackgroundColor3 = Color.getColor("White")
		object.BackgroundTransparency = 0
		object.BorderSizePixel = 0
		object.ClipsDescendants = true
		object.AutoLocalize = true
		object.ZIndex = 1
		object.Active = false
		object.Selectable = false
		object.Visible = true
		object.Draggable = false
		object.ScrollingEnabled = true
		object.ScrollBarThickness = 8
		object.ScrollBarImageColor3 = Color.getColor("Grey")
		object.ScrollBarImageTransparency = 0.9
	end
end

return style
