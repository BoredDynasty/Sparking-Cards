--[=[
	@class Curvy
--]=]
local Curvy = {}
Curvy.__index = Curvy

-- Da Dubious Dynasty

-- This is unfinished

local TweenService = game:GetService("TweenService")

function Curvy.new()
	local self = setmetatable({}, Curvy)

	self.Objects = {}
	self.Curves = {} :: { Tween }

	return self
end

local function createCurve(object: any, info: TweenInfo, property: string, target: any): Tween
	return TweenService:Create(object, info, { [property] = target })
end

function Curvy:Curve(object: Instance, info, property, target): Tween
	local curve: Tween = nil
	if not info then
		info = TweenInfo.new(0.5)
	end
	curve = createCurve(object, info, property, target)
	curve:Play()
	curve.Completed:Once(function()
		curve:Destroy() -- no memory leaks!
	end)
	return curve
end

function Curvy.TweenInfo(seconds, style, direction, repeatCount, reverses, delayTime)
	return TweenInfo.new(
		seconds,
		Enum.EasingStyle[style],
		Enum.EasingDirection[direction],
		repeatCount,
		reverses,
		delayTime
	)
end

return Curvy
