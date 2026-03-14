--!strict
local RunService = game:GetService("RunService")

-- expressive-shapes.luau

local module = {}

local tracked = {}

function module.register(shape: GuiObject, inside: GuiObject)
	table.insert(tracked, { shape = shape, inside = inside })
end

RunService.Heartbeat:Connect(function(delta)
	if next(tracked) == nil then
		return
	end

	for i, shape in ipairs(tracked) do
		shape.shape.Rotation = shape.shape.Rotation + 20 * delta

		-- keep inert
		shape.inside.Rotation = shape.inside.Rotation - 20 * delta
	end
end)

function module.unregister(shape: GuiObject)
	for i, data in ipairs(tracked) do
		if data.shape:GetFullName() == shape:GetFullName() then
			table.remove(tracked, i)
			return
		end
	end
end

return module
