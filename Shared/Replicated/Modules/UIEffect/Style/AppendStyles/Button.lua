-- // Requires

local Maid = require(script.Parent.Parent.Parent.Parent.Maid)
local Curvy = require(script.Parent.Parent.Parent.Parent.Curvy) -- TweenService but better
local Color = require(script.Parent.Parent.Parent.Parent.Color)

local connection1
local connection2
local connection3

local function style(object: GuiButton, name: string)
	if name == "Material 3" then
		connection1 = object.MouseButton1Down:Connect(function()
			Maid:GiveTask(connection1)
			local objectColor = object.BackgroundColor3
			Curvy:Curve(object, nil, "BackgroundColor3", Color:darker(objectColor))
			return connection1
		end)
		connection2 = object.MouseEnter:Connect(function()
			Maid:GiveTask(connection2)
			local objectColor = object.BackgroundColor3
			Curvy:Curve(object, nil, "BackgroundColor3", Color:lighter(objectColor))
			return connection2
		end)
		connection3 = object.MouseLeave:Connect(function()
			Maid:GiveTask(connection3)
			local objectColor = object.BackgroundColor3
			Curvy:Curve(object, nil, "BackgroundColor3", objectColor)
			return connection3
		end)
	end
	return connection1, connection2, connection3
end

return style
