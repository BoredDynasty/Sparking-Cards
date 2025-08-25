--!strict

-- DisplayOrder.lua

local TweenService = game:GetService("TweenService")

local DisplayOrder = {}
DisplayOrder.__index = DisplayOrder

DisplayOrder.compiled = {}
DisplayOrder.canvasPositions = {
	middle = UDim2.fromScale(0.5, 0.5),
	offscreen_high = UDim2.fromScale(0.5, -2),
	higher = UDim2.fromScale(0.5, 0.053),
	lower = UDim2.fromScale(0.5, 0.7),
	offscreen = UDim2.fromScale(0.5, 2),
}
DisplayOrder.canvasSizes = {
	offscreen = 0,
	visible = 1,
}

function DisplayOrder:_createScale(ancestor: Instance)
	local scale = Instance.new("UIScale")
	scale.Name = "visibility_scale"
	scale.Parent = ancestor
	scale.Scale = 1
	return scale
end

function DisplayOrder:add(canvas: Instance)
	DisplayOrder.compiled[(canvas.Parent :: ScreenGui).Name:lower()] = canvas
end

function DisplayOrder:changeVisibility(v: boolean, canvas: CanvasGroup | Frame)
	(canvas.Parent :: ScreenGui).Enabled = true
	task.spawn(function()
		local tweenInfo
		local targetPosition
		local targetScale

		if v == true then
			canvas.Visible = true
			tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.InOut)
			targetPosition = DisplayOrder.canvasPositions.middle
			targetScale = 1
		else
			tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			targetPosition = DisplayOrder.canvasPositions.lower
			targetScale = 0
		end

		local positionTween = TweenService:Create(canvas, tweenInfo, { Position = targetPosition })
		positionTween:Play()

		local scale = DisplayOrder:_createScale(canvas)
		scale.Scale = v and 0 or 1
		local scaleTween = TweenService:Create(scale, tweenInfo, { Scale = targetScale })
		scaleTween:Play()

		task.delay(tweenInfo.Time + 0.01, function()
			scale:Destroy()
			if not v then
				canvas.Visible = false
			end
		end)

		if v then
			print("visible")
		else
			print("invisible")
		end
	end)
	--DisplayOrder:setDisplayOrder(canvas.Parent.Name:lower())
end

function DisplayOrder:setDisplayOrder(i: string)
	for _, t: CanvasGroup | Frame in DisplayOrder.compiled do
		if t ~= DisplayOrder.compiled[i:lower()] then
			print("setDisplayOrder: ", t)
			DisplayOrder:changeVisibility(false, t)
		end
	end
end

-- TODO) Add a sort order function

return DisplayOrder
