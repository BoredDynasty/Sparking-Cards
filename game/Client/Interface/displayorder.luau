--!strict

-- DisplayOrder.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Emphasis = require(ReplicatedStorage.Utility.Emphasis)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
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

function DisplayOrder:changeVisibility(v: boolean, canvas: CanvasGroup | Frame)
	if v == true then
		canvas.Visible = true
		TweenPlus(
			canvas,
			{ Position = DisplayOrder.canvasPositions.middle },
			{ Time = Emphasis.emphasized, EasingDirection = "InOut", EasingStyle = "Circular" }
		):Start()
		--[[
		coroutine.wrap(function()
			fade.fadeIn(canvas)
				:andThen(function()
					print("visible")
				end)
				:catch(function(err)
					warn("Fade failed:", err)
				end)
		end)
		]]
		print("visible")

		--LightingManipulation:blur(true)
		print("visible")
	elseif v == false then
		TweenPlus(
			canvas,
			{ Position = DisplayOrder.canvasPositions.lower },
			{ Time = Emphasis.emphasized_accelerate, EasingDirection = "Out", EasingStyle = "Circular" }
		):Start()
		--[[
			fade.fadeOut(canvas)
			:andThen(function()
				task.wait(0.2)
				canvas.Visible = false
				print("invisible")
			end)
			:catch(function(err)
				warn("fade failed: ", err)
			end)
		]]
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
