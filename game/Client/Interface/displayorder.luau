--!nonstrict

-- displayorder.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local observer = require(ReplicatedStorage.Utility.observer)
local promise = require(ReplicatedStorage.Packages.promise)
local spr = require(ReplicatedStorage.Modules.spr)
local sway = require(script.Parent.sway)

local displayorder = {}

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
displayorder.canvasSizes = {
	offscreen = 0,
	visible = 1,
}

function displayorder:_createScale(ancestor: Instance)
	local scale = Instance.new("UIScale")
	scale.Name = "visibility_scale"
	scale.Parent = ancestor
	scale.Scale = 1

	return scale
end

function displayorder:_getData(value: CanvasGroup | string)
	local data = nil

	if type(value) == "string" then
		data = displayorder.compiled[value:lower()]
	else
		local layer_collector = value.Parent :: ScreenGui

		data = displayorder.compiled[layer_collector.Name:lower()]
	end

	--assert(data, "Missing data from compiled table. Did you forget to add canvas?")

	return data :: data
end

function displayorder:add(canvas: CanvasGroup)
	local layer_collector = canvas.Parent :: ScreenGui
	local name = layer_collector.Name:lower()

	displayorder.compiled[name] = {
		canvas = canvas,
		layer_collector = layer_collector,
		state = observer.new(canvas.Visible :: boolean),
	}

	displayorder.compiled[name].state:Watch(function(newValue)
		promise.new(function()
			if newValue then
				sway:on(displayorder.compiled[name].canvas)
			else
				sway:off(displayorder.compiled[name].canvas)
			end
		end)
	end)
end

function displayorder:changeVisibility(v: boolean, canvas: CanvasGroup | string)
	local layer_collector = nil

	local data = promise
		.new(function()
			return displayorder:_getData(canvas)
		end)
		:expect() :: data

	layer_collector = data.layer_collector
	layer_collector.Enabled = true

	task.spawn(function()
		local tweenInfo = nil
		local targetPosition = nil
		local targetScale = nil

		data.state:Set(true)

		if v then
			data.canvas.Visible = true

			tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.InOut)
			targetPosition = displayorder.canvasPositions.middle
			targetScale = 1

			data.state:Set(true)
		else
			tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			targetPosition = displayorder.canvasPositions.lower
			targetScale = 0

			data.state:Set(false)
		end

		local scale = displayorder:_createScale(data.canvas)
		scale.Scale = v and 0 or 1

		data.canvas.Visible = true
		spr.target(data.canvas, 0.55, tweenInfo.Time, {
			Position = targetPosition,
		})

		spr.target(scale, tweenInfo.Time, 0.55, {
			Scale = targetScale,
		})

		promise
			.delay(tweenInfo.Time)
			:andThen(function()
				scale:Destroy()
				if not v then
					data.canvas.Visible = false
				end
			end)
			:catch(warn)
	end)
end

function displayorder:toggle(canvas: CanvasGroup | string)
	local data = promise
		.new(function()
			return displayorder:_getData(canvas)
		end)
		:expect() :: data

	--promise.new(function()
	displayorder:changeVisibility(not data.state:Get(), canvas)
	--end)

	return not data.state:Get()
end

function displayorder:setDisplayOrder(i: string)
	for _, t in displayorder.compiled do
		if t ~= displayorder.compiled[i:lower()] then
			print("setDisplayOrder: ", t)
			displayorder:changeVisibility(false, t.canvas)
		end
	end
end

-- TODO) Add a sort order function

return displayorder
