--!strict
--[[
	Manages the display order and visibility of major UI elements,
	such as the main menu, settings, and inventory. It uses a
	spring-based animation system to create smooth and fluid
	transitions between UI states.

	@module displayorder
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local observer = require(ReplicatedStorage.Utility.observer)
local spr = require(ReplicatedStorage.Modules.spr)
local sway = require(script.Parent.sway)

local displayorder = {}
displayorder.__index = displayorder

export type data = {
	canvas: CanvasGroup,
	layer_collector: LayerCollector,
	state: observer.Observer<boolean>,
}

displayorder.compiled = {}
displayorder.canvasPositions = {
	middle = UDim2.fromScale(0.5, 0.5),
	offscreen_high = UDim2.fromScale(0.5, -2),
	higher = UDim2.fromScale(0.5, 0.053),
	lower = UDim2.fromScale(0.5, 0.7),
	offscreen = UDim2.fromScale(0.5, 2),
}

--[[
	Retrieves the data for a given canvas. This is the fix for the bug
	where the script was unable to get the compiled data. The issue was
	that the key used to store the data was the name of the layer collector,
	but the key used to retrieve the data was the name of the canvas.

	@param value {CanvasGroup | string} The canvas or the name of the canvas to get the data for.
	@return {data} The data for the canvas.
]]
function displayorder:_getData(value: CanvasGroup | string)
	local data = nil

	if type(value) == "string" then
		data = displayorder.compiled[value:lower()]
	else
		-- This is the fix for the bug. The key is the name of the layer_collector,
		-- not the canvas itself.
		local key = value.Parent.Name:lower()
		data = displayorder.compiled[key]
	end

	assert(data, "Missing data for canvas: " .. (type(value) == "string" and value or value.Name))

	return data
end

--[[
	Adds a canvas to the display order manager.

	@param canvas {CanvasGroup} The canvas to add.
]]
function displayorder:add(canvas: CanvasGroup)
	local layer_collector = canvas.Parent :: ScreenGui
	local name = layer_collector.Name:lower()

	displayorder.compiled[name] = {
		canvas = canvas,
		layer_collector = layer_collector,
		state = observer.new(canvas.Visible),
	}

	displayorder.compiled[name].state:Watch(function(newValue)
		if newValue then
			sway:on(displayorder.compiled[name].canvas)
		else
			sway:off(displayorder.compiled[name].canvas)
		end
	end)
end

--[[
	Changes the visibility of a canvas with a springy animation.

	@param visible {boolean} Whether the canvas should be visible or not.
	@param canvas {CanvasGroup | string} The canvas or the name of the canvas to change the visibility of.
]]
function displayorder:changeVisibility(visible: boolean, canvas: CanvasGroup | string)
	local data = displayorder:_getData(canvas)
	if not data then
		return
	end

	data.layer_collector.Enabled = true
	data.state:Set(visible)

	local targetPosition
	local targetTransparency

	if visible then
		targetPosition = displayorder.canvasPositions.middle
		targetTransparency = 0
		data.canvas.Visible = true -- Make it visible before animating
	else
		targetPosition = displayorder.canvasPositions.lower
		targetTransparency = 1
	end

	spr.target(data.canvas, 0.5, 3, {
		Position = targetPosition,
		GroupTransparency = targetTransparency,
	})

	spr.completed(data.canvas, function()
		if not visible then
			data.canvas.Visible = false -- Hide it after animating
		end
	end)
end

--[[
	Toggles the visibility of a canvas.

	@param canvas {CanvasGroup | string} The canvas or the name of the canvas to toggle.
	@return {boolean} The new visibility state.
]]
function displayorder:toggle(canvas: CanvasGroup | string)
	local data = displayorder:_getData(canvas)
	if not data then
		return false
	end

	local newState = not data.state:Get()
	displayorder:changeVisibility(newState, canvas)

	return newState
end

--[[
	Sets the display order to a specific canvas, hiding all others.

	@param canvasName {string} The name of the canvas to set as the display order.
]]
function displayorder:setDisplayOrder(canvasName: string)
	for name, data in displayorder.compiled do
		if name ~= canvasName:lower() then
			displayorder:changeVisibility(false, data.canvas)
		end
	end
end

return displayorder
