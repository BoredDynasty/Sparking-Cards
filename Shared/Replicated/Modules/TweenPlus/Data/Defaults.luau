--!optimize 2

-- Services.
local CollectionService = game:GetService("CollectionService")

-- Easing functions.
local easingFunctions = require(script.Parent.Parent.Utilities.EasingFunctions)

-- Initialize defaults table with default defaults.
local defaults = {
	Time = 1,
	
	EasingStyle = "Linear",
	EasingDirection = "In",
	
	DelayTime = 0,
	Reverses = false,
	RepeatCount = 0,
	
	FPS = nil,
	
	Update = "PreSimulation"
}

-- Merge user defaults.
local customizationOptions = {
	Time = true,
	
	EasingStyle = true,
	EasingDirection = true,
	
	DelayTime = true,
	Reverses = true,
	RepeatCount = true,
	
	FPS = true,
	
	Update = true
}
local userDefaults = CollectionService:GetTagged("TweenDefaults")[1]
if userDefaults then
	userDefaults = require(userDefaults)
	if type(userDefaults) == "table" then
		for key in userDefaults do
			if customizationOptions[key] then defaults[key] = userDefaults[key] end
		end
	end
end

-- Remove false booleans.
for key, value in defaults do
	if value == false then defaults[key] = nil end
end

-- Invert time beforehand.
defaults.Time = 1/defaults.Time

-- Reference easing function.
local easingStyle = defaults.EasingStyle
if easingStyle == "Linear" then
	defaults.EasingFunction = easingFunctions.Linear
else
	defaults.EasingFunction = easingFunctions[easingStyle][defaults.EasingDirection]
end

-- Return final defaults.
return defaults