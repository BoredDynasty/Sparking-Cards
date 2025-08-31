--!strict

-- displayorder.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local observer = require(ReplicatedStorage.Utility.observer)
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
	assert(data, "Missing data from compiled table. Did you forget to add canvas?")

	if type(value) == "string" then
		data = displayorder.compiled[value]
	end

	return data :: data
end

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

function displayorder:changeVisibility(v: boolean, canvas: CanvasGroup | string)
	local layer_collector = nil

	local data = displayorder:_getData(canvas)

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

		local positionTween = TweenService:Create(data.canvas, tweenInfo, { Position = targetPosition })
		positionTween:Play()

		local scale = displayorder:_createScale(data.canvas)
		scale.Scale = v and 0 or 1
		local scaleTween = TweenService:Create(scale, tweenInfo, { Scale = targetScale })
		scaleTween:Play()

		task.delay(tweenInfo.Time + 0.01, function()
			scale:Destroy()
			if not v then
				data.canvas.Visible = false
			end
		end)
	end)
end

function displayorder:toggle(canvas: CanvasGroup | string)
	local data = displayorder:_getData(canvas)

	displayorder:changeVisibility(not data.state:Get(), canvas)

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
