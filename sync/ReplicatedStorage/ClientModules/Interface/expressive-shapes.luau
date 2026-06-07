--!strict

local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local lerp = require(ReplicatedStorage.ClientModules.Utilities.lerp)

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

local tracked: { { shape: GuiObject, inside: GuiObject } } = {}

function module.register(shape: GuiObject, inside: GuiObject)
	table.insert(tracked, { shape = shape, inside = inside })
end

RunService.PreRender:Connect(function(delta)
	if next(tracked) == nil then
		return
	end

	for i, shape in ipairs(tracked) do
		-- use lerp to smoothly rotate the shape and its inside in opposite directions

		shape.shape.Rotation = lerp(shape.shape.Rotation, shape.shape.Rotation + 20 * delta, 0.1 * delta)
		-- the inside should rotate in the opposite direction to create a dynamic effect, but it should also
		-- lerp towards its original rotation to prevent it from drifting too far and looking weird
		-- this creates a nice balance where the inside rotates opposite to the shape, but doesn't go

		if shape.inside then
			shape.inside.Rotation =
				lerp(shape.inside.Rotation, shape.inside.Rotation - 20 * delta, 0.1 * delta)
		end
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

