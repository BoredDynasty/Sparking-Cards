--!strict

-- DisplayOrder.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Emphasis = require(ReplicatedStorage.Utility.Emphasis)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local fade = require(script.Parent.fade)

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

function DisplayOrder:changeVisibility(v: boolean, canvas: CanvasGroup | Frame)
	if v == true then
		canvas.Visible = true
		TweenPlus(
			canvas,
			{ Position = DisplayOrder.canvasPositions.middle },
			{ Time = 0.35, EasingDirection = "InOut", EasingStyle = "Back" }
		):Start()
		local scale = DisplayOrder:_createScale(canvas)
		scale.Scale = 0
		TweenPlus(scale, {
			Scale = 1,
		}, {
			Time = 0.35,
			EasingDirection = "InOut",
			EasingStyle = "Back",
		}):Start()
		task.delay(0.36, function()
			scale:Destroy()
		end)
		print("visible")
	elseif v == false then
		TweenPlus(
			canvas,
			{ Position = DisplayOrder.canvasPositions.lower },
			{ Time = 0.25, EasingDirection = "Out", EasingStyle = "Back" }
		):Start()
		local scale = DisplayOrder:_createScale(canvas)
		scale.Scale = 1
		TweenPlus(scale, {
			Scale = 0,
		}, {
			Time = 0.25,
			EasingDirection = "InOut",
			EasingStyle = "Back",
		}):Start()
		task.delay(0.36, function()
			scale:Destroy()
		end)
		task.wait(0.2)
		canvas.Visible = false
		print("invisible")
	end
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
