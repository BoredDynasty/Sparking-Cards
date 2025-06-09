--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Emphasis = require(ReplicatedStorage.Utility.Emphasis)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local LightingManipulation = {}

function LightingManipulation:blur(v: boolean)
	--[[
	local blurEffect = Lighting:WaitForChild("Blur") :: BlurEffect
	if v == true then
		blurEffect.Enabled = true
		local goal = { Size = 24 }
		TweenPlus(blurEffect, goal, { Time = Emphasis.standard, EasingStyle = "Circular" })
	elseif v == false then
		local goal = { Size = 0 }
		TweenPlus(blurEffect, goal, { Time = Emphasis.standard, EasingStyle = "Circular" })
		task.delay(Emphasis.standard, function()
			blurEffect.Enabled = false
		end)
	end
	--]]
end

return LightingManipulation
