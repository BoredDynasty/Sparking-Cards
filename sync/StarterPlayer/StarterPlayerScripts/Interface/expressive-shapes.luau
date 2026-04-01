--!strict
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

-- expressive-shapes.luau

local module = {}

local shapes = {
	97245726087066,
	85614945574704,
	94017120307890,
	123135520846107,
	79431460260430,
	93166230776141,
	130781869380726,
	116970364655922,
	112316730429585,
	93127375416464,
	114671850438094,
}

do
	local shapes_transformed = {}
	for i, id in ipairs(shapes) do
		table.insert(shapes_transformed, "rbxassetid://" .. tostring(id))
	end

	ContentProvider:PreloadAsync({ shapes_transformed })
end

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

function module.random_shape()
	return Content.fromAssetId(shapes[math.random(1, #shapes)])
end

return module
