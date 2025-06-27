--!strict

-- DisplayOrder.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Emphasis = require(ReplicatedStorage.Utility.Emphasis)
local LightingManipulation = require(script.Parent.LightingManipulation)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local promise = require(ReplicatedStorage.Packages.promise)

local DisplayOrder = {}
DisplayOrder.__index = DisplayOrder

--[[
	Creates a new `DisplayOrder` object.
]]
function DisplayOrder.new()
	local self = setmetatable({
		compiled = {},
		canvasPositions = {
			middle = UDim2.fromScale(0.5, 0.5),
			offscreen_high = UDim2.fromScale(0.5, -2),
			higher = UDim2.fromScale(0.5, 0.053),
			lower = UDim2.fromScale(0.5, 0.7),
			offscreen = UDim2.fromScale(0.5, 2),
		},
	}, DisplayOrder)
	return self
end

function DisplayOrder:changeVisibility(v: boolean, canvas: CanvasGroup | Frame)
	if v == true then
		canvas.Visible = true
		TweenPlus(
			canvas,
			{ Position = self.canvasPositions.middle },
			{ Time = Emphasis.emphasized, EasingDirection = "InOut", EasingStyle = "Circular" }
		):Start()
		LightingManipulation:blur(true)
		print("visible")
	elseif v == false then
		TweenPlus(
			canvas,
			{ Position = self.canvasPositions.lower },
			{ Time = Emphasis.emphasized_accelerate, EasingDirection = "Out", EasingStyle = "Circular" }
		):Start()
		LightingManipulation:blur(true)
		task.wait(0.200)
		canvas.Visible = false
		print("invisible")
	end
end

function DisplayOrder:setDisplayOrder(i: string)
	for _, t: CanvasGroup | Frame in self.compiled do
		if t ~= self.compiled[i:lower()] then
			print("setDisplayOrder: ", t)
			self:changeVisibility(false, t)
		end
	end
end

-- TODO) Add a sort order function

return DisplayOrder
