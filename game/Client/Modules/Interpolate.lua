--!strict

-- Interpolate.lua

-- // Util

local TweenService = game:GetService("TweenService")

local TweenCache = {}

return function(instance: Instance, info: TweenInfo, goal: { [string]: any })
	-- Clean up existing tween
	if TweenCache[instance] then
		TweenCache[instance]:Cancel()
		TweenCache[instance]:Destroy()
		TweenCache[instance] = nil
	end

	local tween = TweenService:Create(instance, info, goal)
	TweenCache[instance] = tween

	tween.Completed:Once(function()
		TweenCache[instance] = nil
		tween:Destroy()
	end)

	tween:Play()
	return tween
end
