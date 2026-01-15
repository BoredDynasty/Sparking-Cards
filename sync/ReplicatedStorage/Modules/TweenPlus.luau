--!optimize 2
--!native

--[[

=============== ====      ====      ====  ========================   ====       ====                
=============== =====    ======    =====  ========================   ======     ====        :::     
     ====        ====    ======    ====   ====                       =======    ====        :::     
     ====         ====  ========  ====    ====                       ========   ====        :::     
     ====         ====  ===  ===  ====    =======================    ==== ===== ====   :::::::::::::
     ====          ========  ========     ====                       ====   ========        :::     
     ====          =======    =======     ====                       ====    =======        :::     
     ====           ======    ======      ========================   ====     ======        :::     
     ====            ====      ====       ========================   ====       ====                

v1.3.1

An open-source tweening module for Roblox, featuring advanced
datatypes, accurate color interpolation and more customization.


GitHub:
https://github.com/AlexanderLindholt/TweenPlus

DevForum:
https://devforum.roblox.com/t/3599638


--------------------------------------------------------------------------------
MIT License

Copyright (c) 2025 AlexanderLindholt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--------------------------------------------------------------------------------

]]
--

local RunService = game:GetService("RunService")

local SignalPlus = require(script.SignalPlus)

local dataTypes = require(script.DataTypes)
local normalDataTypes = dataTypes.Normal
local advancedDataTypes = dataTypes.Advanced

local easingFunctions = require(script.EasingFunctions)

-- Defaults.
local defaultInverseTime = 1 -- 1/time.

local defaultEasingStyle = "Linear"
local defaultEasingDirection = "In"

local defaultRepeatCount = 0

local defaultUpdateEvent = "PostSimulation"

-- External types.
export type Tween = {
	Start: typeof( -- Starts or resumes playback of the tween.function(tween: Tween) end),
	Stop: typeof( -- Stops playback of the tween.	-- Can be resumed with <code>Start()</code>.
function(tween: Tween) end),
	Reset: typeof( -- Stops playback of the tween, and resets to starting values.function(tween: Tween) end),
	Destroy: typeof( -- Makes the tween unusable, and ensures it's stopped.function(tween: Tween) end),

	Updated: signalPlus.Signal<number>,
	Started: signalPlus.Signal,
	Stopped: signalPlus.Signal,
	Completed: signalPlus.Signal,
}
export type Customization = {
	Time: number,

	EasingStyle: "Linear"
		| "Quad"
		| "Cubic"
		| "Quart"
		| "Quint"
		| "Sine"
		| "Exponential"
		| "Circular"
		| "Elastic"
		| "Back"
		| "Bounce",
	EasingDirection: "In" | "Out" | "InOut" | "OutIn",

	RepeatCount: number,
	Reverses: boolean,
	DelayTime: number,

	FPS: number,

	UpdateEvent: "PostSimulation" | "PreSimulation" | "PreRender",
}
type CreateTween = typeof( -- Creates a new tween.function(
	instance: Instance,
	values: { [string]: any },
	customization: Customization
): Tween
end)

-- Internal types.
type InternalTween = {
	InverseTweenTime: number,

	GetValue: (alpha: number) -> number,

	RepeatCount: number,
	Reverses: boolean,
	DelayTime: number,

	Interval: number,
	LastUpdate: number,

	UpdateEvent: "PostSimulation" | "PreSimulation" | "PreRender",

	Updated: signalPlus.Signal<number>,
	Started: signalPlus.Signal,
	Stopped: signalPlus.Signal,
	Completed: signalPlus.Signal,
}

-- Update events each with a tweens collection.
local updateEvents = {
	PostSimulation = {},
	PreSimulation = {},
	PreRender = {},
}

-- Tween stop function.
local function stop(tween)
	-- Verify playback.
	if tween.Paused then
		return
	end

	-- Tween removal.
	tween.Table[tween] = nil
	-- Set time markers.
	tween.Paused = time()

	-- Fire stopped signal.
	tween.Stopped:Fire()
end

-- Setup tween processing for all events.
local function processTweens(tweens)
	if not next(tweens) then
		return
	end

	local currentTime = time()
	for tween: InternalTween in tweens do
		-- Account for pause when waiting.
		if tween.Waited then
			if currentTime - tween.Waited < tween.DelayTime then
				continue
			end
			tween.Waited = nil
			tween.StartTime = currentTime
		end

		-- Ensure desired interval (specified in FPS).
		if tween.Interval then
			if currentTime - tween.LastUpdate < tween.Interval then
				continue
			end
			tween.LastUpdate = currentTime
		end

		-- Calculate raw alpha.
		local alpha = (currentTime - tween.StartTime) * tween.InverseTweenTime

		local phaseCompleted = alpha >= 1

		if phaseCompleted then
			alpha = 1
		end

		if tween.Reverse then
			alpha = 1 - alpha
			if alpha < 0 then
				alpha = 0
			end
		else
			if alpha > 1 then
				alpha = 1
			end
		end

		-- Get eased alpha and call value update functions.
		local easedAlpha = tween.GetValue(alpha)
		for _, update in tween.UpdateFunctions do
			update(easedAlpha)
		end

		-- Fire updated signal with raw alpha.
		tween.Updated:Fire(alpha)

		-- Phase completion stuff.
		if phaseCompleted then
			if tween.Reverse then
				-- Already going in reverse. Means reversing is enabled, so no need to check for that.
				if tween.RepeatCount == -1 or tween.Repetitions < tween.RepeatCount then
					tween.Repetitions += 1
					if tween.DelayTime then
						tween.Waited = currentTime
					end
					tween.StartTime = currentTime
					tween.Reverse = nil
				else
					stop(tween)
				end
			else
				-- Not going in reverse.
				if tween.Reverses then
					-- Reversing enabled.
					if tween.DelayTime then
						tween.Waited = currentTime
					end
					tween.Reverse = true
					tween.StartTime = currentTime
				else
					-- Reversing disabled.
					if tween.RepeatCount == -1 or tween.Repetitions < tween.RepeatCount then
						tween.Repetitions += 1
						if tween.DelayTime then
							tween.Waited = currentTime
						end
						tween.StartTime = currentTime
					else
						stop(tween)
					end
				end
			end
		end
	end
end
for event, tweens in updateEvents do
	RunService[event]:Connect(function()
		processTweens(tweens)
	end)
end

-- Tween class.
local tweenClass = table.freeze({
	__index = table.freeze({
		Start = function(tween: InternalTween)
			-- Verify playback.
			if not tween.Paused then
				return
			end

			-- Handle any conflicts.
			local instance = tween.Instance
			local values = tween.Values

			for _, tweens in updateEvents do
				for otherTween, otherInstance in tweens do
					if otherInstance == instance then
						for value in otherTween.Values do
							if values[value] then
								stop(otherTween)
								tweens[otherTween] = nil
								break
							end
						end
					end
				end
			end

			-- Set time markers.
			local timeSince = time() - tween.Paused
			tween.StartTime += timeSince
			if tween.Waited then
				tween.Waited += timeSince
			end
			tween.Paused = nil

			-- Add tween.
			tween.Table[tween] = instance

			-- Fire started signal.
			tween.Started:Fire()
		end,

		Stop = stop,

		Reset = function(tween: InternalTween)
			-- Ensure no playback.
			stop(tween)

			-- Call all value reset functions.
			for _, reset in tween.ResetFunctions do
				reset()
			end
		end,

		Destroy = function(tween: InternalTween)
			-- Ensure no playback.
			tween.Table[tween] = nil
			tween.Stopped:Fire()

			-- Destroy signals.
			tween.Updated:Destroy()
			tween.Started:Destroy()
			tween.Stopped:Destroy()
			tween.Completed:Destroy()

			-- Clear tween data.
			table.clear(tween)
		end,
	}),
})

-- Tween creation function.
local function propertyExists(instance, name)
	local _, result = pcall(function()
		local property = instance[name] -- If no property or instance is found, this will error.
		if typeof(property) == "Instance" then
			return
		end -- Ensure it's a property, not a child.
		return true
	end)
	return result
end

return function(instance, values, customization)
	-- Argument errors.
	if typeof(instance) ~= "Instance" then
		error("No instance provided.", 2)
	end
	if type(values) ~= "table" or not next(values) then
		error("No values provided.", 2)
	end

	-- Handle values.
	local updateFunctions = {}
	local resetFunctions = {}
	for name, value in values do
		if type(name) ~= "string" then
			error("Invalid value name of type '" .. typeof(name) .. "' instead of string.", 2)
		end

		if name:sub(1, 1) == "@" then
			-- Attribute.
			local attributeName = name:sub(2)
			local original = instance:GetAttribute(attributeName)
			if original == nil then
				error(
					"'"
						.. attributeName
						.. "' is not a valid attribute of '"
						.. instance:GetFullName()
						.. "'.",
					2
				)
			end

			local dataType = normalDataTypes[typeof(value)]
			if not dataType then
				error("'" .. typeof(value) .. "'' data type is not supported.", 2)
			end

			table.insert(updateFunctions, function(lerp)
				instance:SetAttribute(attributeName, dataType(original, value, lerp))
			end)
			table.insert(resetFunctions, function()
				instance:SetAttribute(attributeName, original)
			end)
		else
			-- Not attribute.
			local dataType = advancedDataTypes[name]
			if dataType then
				-- Advanced type.
				if not instance:IsA(dataType.Target) then
					error("'" .. instance:GetFullName() .. "'' doesn't have data type '" .. name .. "'.", 2)
				end

				local original = dataType.Get(instance)
				local set = dataType.Set
				table.insert(updateFunctions, function(lerp)
					set(instance, original, value, lerp)
				end)
				table.insert(resetFunctions, function()
					set(instance, original, value, 0)
				end)
			else
				-- Property.
				if propertyExists(instance, name) ~= true then
					error(
						"'" .. name .. "' is not a valid property of '" .. instance:GetFullName() .. "'.",
						2
					)
				end
				dataType = normalDataTypes[typeof(value)]
				if not dataType then
					error("'" .. typeof(value) .. "' data type is not supported.", 2)
				end

				local original = instance[name]
				table.insert(updateFunctions, function(lerp)
					instance[name] = dataType(original, value, lerp)
				end)
				table.insert(resetFunctions, function()
					instance[name] = original
				end)
			end
		end
	end

	-- Handle customization.
	if type(customization) ~= "table" then
		-- Create tween.
		local tween: InternalTween = setmetatable({
			-- Signals.
			Updated = SignalPlus(),
			Started = SignalPlus(),
			Stopped = SignalPlus(),
			Completed = SignalPlus(),

			-- Main arguments.
			Instance = instance,
			Values = values,

			-- Value functions.
			UpdateFunctions = updateFunctions,
			ResetFunctions = resetFunctions,

			-- Customization. None provided, so use defaults.
			InverseTweenTime = defaultInverseTime,
			GetValue = easingFunctions[defaultEasingStyle],
			RepeatCount = defaultRepeatCount,
			Table = updateEvents[defaultUpdateEvent],

			-- Time markers
			StartTime = 0,
			Paused = 0,

			-- Trackers.
			Repetitions = 0,
			Reverse = false,
		}, tweenClass)

		-- Handle instance destroy.
		instance.Destroying:Connect(function()
			tween:Destroy()
		end)

		-- Return tween.
		return tween
	else
		-- Get customization.
		local tweenTime = customization.Time

		local easingStyle = customization.EasingStyle

		local delayTime = customization.DelayTime
		local reverses = customization.Reverses
		local repeatCount = customization.RepeatCount

		local fps = customization.FPS

		local updateEvent = customization.UpdateEvent

		-- Verify customization.
		if type(tweenTime) ~= "number" then
			tweenTime = defaultInverseTime
		elseif tweenTime < 0.01 then
			tweenTime = 100 -- 1/0.01
		else
			tweenTime = 1 / tweenTime
		end

		local getValue = nil
		do
			local easing = easingFunctions[easingStyle]
			if not easing then
				easing = easingFunctions[defaultEasingStyle]
				easingStyle = defaultEasingStyle
			end
			if easingStyle == "Linear" then
				getValue = easing
			else
				getValue = easing[customization.EasingDirection]
				if not getValue then
					getValue = easing[defaultEasingDirection]
				end
			end
		end

		if type(delayTime) ~= "number" or delayTime <= 0 then
			delayTime = nil
		end
		if reverses ~= true then
			reverses = nil
		end
		if type(repeatCount) ~= "number" then
			repeatCount = defaultRepeatCount
		elseif repeatCount < 0 then
			repeatCount = -1
		end

		local interval = nil
		if type(fps) == "number" then
			interval = 1 / fps
		end

		if not updateEvents[updateEvent] then
			updateEvent = defaultUpdateEvent
		end

		-- Create tween.
		local tween: InternalTween = setmetatable({
			-- Signals.
			Updated = SignalPlus(),
			Started = SignalPlus(),
			Stopped = SignalPlus(),
			Completed = SignalPlus(),

			-- Main arguments.
			Instance = instance,
			Values = values,

			-- Value functions.
			UpdateFunctions = updateFunctions,
			ResetFunctions = resetFunctions,

			-- Customization.
			InverseTweenTime = tweenTime,
			GetValue = getValue,
			DelayTime = delayTime,
			Reverses = reverses,
			RepeatCount = repeatCount,
			Interval = interval,
			LastUpdate = if interval then -math.huge else nil,
			Table = updateEvents[updateEvent],

			-- Time markers.
			StartTime = 0,
			Paused = 0,

			-- Trackers.
			Repetitions = 0,
		}, tweenClass)

		-- Handle instance destroy.
		instance.Destroying:Connect(function()
			tween:Destroy()
		end)

		-- Return tween.
		return tween
	end
end :: CreateTween
