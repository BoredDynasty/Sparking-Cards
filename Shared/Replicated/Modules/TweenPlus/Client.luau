-- Services.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- Directories.
local root = script.Parent
local data = root.Data
local utilities = root.Utilities

-- Easing functions.
local easingFunctions = require(utilities.EasingFunctions)

-- Updation functions.
local getUpdateFunctions = require(utilities.UpdateFunctions)

-- Signal library.
local Signal = CollectionService:GetTagged("Signal")[1]
if not Signal then error("Could not find a signal library.") end
Signal = require(Signal)
if type(Signal) == "table" and Signal.new then Signal = Signal.new end

-- Game context detection.
local gameContext = script:IsDescendantOf(game)

-- Network packets and Roblox API map.
local packets = nil
local apiMap = nil
if gameContext then
	packets = CollectionService:GetTagged("Packets")[1]
	if packets then
		packets = require(packets)
		apiMap = packets.GetAPIMap:Fire() -- This line weird asf.
	else
		apiMap = script.Parent:WaitForChild("GetAPIMap", 60):InvokeServer()
	end
else -- Plugin context.
	local apiMap = CollectionService:GetTagged("APIMap")[1]
	if not apiMap then error("Could not find APIMap module.") end
	apiMap = require(apiMap)
end

-- Customization defaults.
local defaults = require(data.Defaults)

-- Shared types.
local types = require(data.Types)

-- Signal type.
type Signal = types.Signal

-- Internal tween type.
type InternalTween = types.InternalTween & {
	Updated: Signal<number>?,
	Started: Signal?,
	Stopped: Signal?,
	Completed: Signal?,
}

-- Store update events, each with its own tweens collection.
local updates: {{InternalTween}} = {
	PreSimulation = {},
	PostSimulation = {},
}

-- Tween functions.
local function stop(tween: InternalTween)
	-- Tween removal.
	local tweens = tween.Table
	local lastIndex = #tweens
	local index = tween.Index
	if index == lastIndex then
		tweens[lastIndex] = nil
	else
		local last = tweens[lastIndex]
		last.Index = index
		tweens[index] = last
		tweens[lastIndex] = nil
	end
	
	-- Set time markers.
	tween.StopTime = tick()
end
local function destroy(tween: InternalTween)
	-- Ensure no playback.
	if not tween.StopTime then
		-- Tween removal.
		local tweens = tween.Table
		local lastIndex = #tweens
		local index = tween.Index
		if index == lastIndex then
			tweens[lastIndex] = nil
		else
			local last = tweens[lastIndex]
			last.Index = index
			tweens[index] = last
			tweens[lastIndex] = nil
		end
		
		-- Fire stopped signal.
		tween.Stopped:Fire()
	end
	
	-- Destroy signals.
	tween.Updated:Destroy()
	tween.Started:Destroy()
	tween.Stopped:Destroy()
	tween.Completed:Destroy()
	-- Clear tween data.
	table.clear(tween)
	-- Unlink methods.
	setmetatable(tween, nil)
end

local function start(tween: InternalTween, startOverride)
	-- Handle conflicts.
	local instance = tween.Instance
	local values = tween.Values
	
	for _, tweens in updates do
		for _, otherTween in tweens do
			if otherTween.Instance ~= instance then continue end
			
			for value in otherTween.Values do
				if values[value] then
					stop(otherTween)
					if otherTween.Stopped then otherTween.Stopped:Fire() end
					tweens[otherTween] = nil
					break
				end
			end
		end
	end
	
	-- Set time markers.
	local stopDuration = tick() - tween.StopTime
	if not startOverride then tween.StartTime += stopDuration end
	if tween.Interval then tween.LastUpdate = -math.huge end
	if tween.WaitTime then tween.WaitTime += stopDuration end
	tween.StopTime = nil
	
	-- Add tween.
	local tweens = tween.Table
	table.insert(tweens, tween)
	tween.Index = #tweens
end

-- Setup tween processing for all events.
for event, tweens in updates do
	RunService[event]:Connect(function()
		if #tweens == 0 then return end
		
		local currentTime = tick()
		for _, tween in tweens do
			-- Ensure desired interval (specified in FPS).
			if tween.Interval then
				if currentTime - tween.LastUpdate < tween.Interval then continue end
				tween.LastUpdate = currentTime
			end
			
			-- Account for wait.
			if tween.WaitTime then
				if currentTime - tween.WaitTime < tween.DelayTime then continue end
				tween.WaitTime = nil
				tween.StartTime = currentTime
			end
			
			-- Calculate alpha.
			local alpha = (currentTime - tween.StartTime)*tween.InverseTweenTime
			
			local phaseCompleted = alpha >= 1
			
			if phaseCompleted then alpha = 1 end
			
			local easedAlpha = nil
			if tween.Reverse then
				alpha = 1 - alpha
				easedAlpha = tween.Ease(alpha)
			else
				easedAlpha = tween.Ease(alpha)
			end
			
			-- Get eased alpha and call value update functions.
			for _, update in tween.UpdateFunctions do
				update(easedAlpha)
			end
			
			-- Fire updated signal with raw alpha.
			local updateSignal = tween.Updated
			
			if updateSignal then updateSignal:Fire(alpha) end
			
			-- Phase completion stuff.
			if phaseCompleted then
				if tween.Reverse then -- Already going in reverse. Means reversing is enabled, so no need to check for that.
					tween.Repetitions += 1
					if tween.RepeatCount == -1 or tween.Repetitions < tween.RepeatCount then
						if tween.DelayTime then tween.WaitTime = currentTime end
						tween.StartTime = currentTime
						tween.Reverse = nil
					else
						if not tween.StopTime then
							stop(tween)
							if updateSignal then -- If there's one signal, we know there are all of them.
								tween.Stopped:Fire()
								tween.Completed:Fire()
							end
						end
					end
				else -- Not going in reverse.
					tween.Repetitions += 1
					if tween.Reverses then
						-- Reversing enabled.
						if tween.DelayTime then tween.WaitTime = currentTime end
						tween.Reverse = true
						tween.StartTime = currentTime
					else
						-- Reversing disabled.
						if tween.RepeatCount == -1 or tween.Repetitions < tween.RepeatCount then
							if tween.DelayTime then tween.WaitTime = currentTime end
							tween.StartTime = currentTime
						else
							if not tween.StopTime then
								stop(tween)
								if updateSignal then -- If there's one signal, we know there are all of them.
									tween.Stopped:Fire()
									tween.Completed:Fire()
								end
							end
						end
					end
				end
			end
		end
	end)
end

-- Tween class.
local Tween = {}
Tween.__index = Tween

Tween.Start = function(tween: InternalTween)
	if not tween.StopTime then return end
	start(tween)
	tween.Started:Fire()
end
Tween.Stop = function(tween: InternalTween)
	if tween.StopTime then return end
	stop(tween)
	tween.Stopped:Fire()
end
Tween.Reset = function(tween: InternalTween)
	if not tween.StopTime then
		stop(tween)
		tween.Stopped:Fire()
	end
	tween.WaitTime = nil
	tween.StopTime = 0
	tween.StartTime = 0
	tween.Repetitions = 0
	for _, reset in tween.ResetFunctions do reset() end
end
Tween.Destroy = destroy

-- Server tweening.
if packets then
	local serverTweens = {}
	
	local function serverDestroy(tween: InternalTween)
		-- Ensure no playback.
		if not tween.StopTime then
			-- Tween removal.
			local tweens = tween.Table
			local lastIndex = #tweens
			local index = tween.Index
			if index == lastIndex then
				tweens[lastIndex] = nil
			else
				local last = tweens[lastIndex]
				last.Index = index
				tweens[index] = last
				tweens[lastIndex] = nil
			end
		end
		
		-- Clear tween data.
		table.clear(tween)
		-- Unlink methods.
		setmetatable(tween, nil)
	end
	
	packets.CreateTween.OnClientEvent:Connect(function(identifier, instance, values, customization)
		-- Argument errors.
		if not instance then error("Could not find instance on client.") end
		
		-- Handle values.
		local updateFunctions, resetFunctions = getUpdateFunctions(apiMap, instance, values)
		
		-- Create tween.
		local easingStyle = customization[2]
		local tween = {
			-- Main arguments.
			Instance = instance,
			Values = values,
			
			-- Value functions.
			UpdateFunctions = updateFunctions,
			ResetFunctions = resetFunctions,
			
			-- Customization.
			InverseTweenTime = customization[1],
			Ease = if easingStyle == "Linear" then easingFunctions.Linear else easingFunctions[easingStyle][customization[3]],
			DelayTime = customization[4],
			Reverses = customization[5],
			RepeatCount = customization[6],
			Interval = customization[7],
			Table = updates[customization[8]],
			
			-- Time markers.
			StartTime = 0,
			StopTime = 0,
			
			-- Trackers.
			Repetitions = 0
		}
		
		-- Handle instance destroy.
		instance.Destroying:Connect(function()
			serverDestroy(tween)
		end)
		
		-- Store the tween with its given identifier.
		serverTweens[identifier] = tween
	end)
	
	packets.StartTween.OnClientEvent:Connect(function(identifier, runTime, repetitions)
		local tween = serverTweens[identifier]
		if not tween then return end
		
		if repetitions then
			tween.Repetitions = repetitions
			if tween.Reverses then tween.Reverse = repetitions%2 == 1 end
		end
		if tween.StopTime then
			if runTime then
				tween.StartTime = tick() - runTime
				start(tween, true)
			else
				start(tween)
			end
		end
	end)
	packets.StopTween.OnClientEvent:Connect(function(identifier)
		local tween = serverTweens[identifier]
		if not tween then return end
		
		if not tween.StopTime then stop(tween) end
	end)
	packets.ResetTween.OnClientEvent:Connect(function(identifier)
		local tween = serverTweens[identifier]
		if not tween then return end
		
		if not tween.StopTime then stop(tween) end
		for _, reset in tween.ResetFunctions do reset() end
	end)
	packets.DestroyTween.OnClientEvent:Connect(function(identifier)
		local tween = serverTweens[identifier]
		if not tween then return end
		
		serverDestroy(tween)
	end)
	
	-- Notify the server that we're ready for tweening.
	packets.TweenReady:Fire()
end

-- Local tween creation.
return function(instance, values, customization)
	-- Argument errors.
	if typeof(instance) ~= "Instance" then error("No instance provided.", 2) end
	if type(values) ~= "table" or not next(values) then error("No values provided.", 2) end
	
	-- Handle values.
	local updateFunctions, resetFunctions = getUpdateFunctions(apiMap, instance, values)
	
	-- Handle customization.
	if type(customization) ~= "table" then customization = {} end
	
	local tweenTime = customization.Time
	if type(tweenTime) ~= "number" then
		tweenTime = defaults.InverseTime
	elseif tweenTime <= 0 then
		tweenTime = 0
	else
		tweenTime = 1/tweenTime
	end
	
	local ease = nil
	do
		local easingStyle = customization.EasingStyle
		local easing = easingFunctions[easingStyle]
		if not easing then
			easing = easingFunctions[defaults.EasingStyle]
			easingStyle = defaults.EasingStyle
		end
		if easingStyle == "Linear" then
			ease = easing
		else
			ease = easing[customization.EasingDirection]
			if not ease then
				ease = easing[defaults.EasingDirection]
			end
		end
	end
	
	
	local delayTime = customization.DelayTime
	if type(delayTime) ~= "number" or delayTime <= 0 then
		delayTime = nil
	end
	
	local reverses = customization.Reverses
	if reverses ~= true then
		reverses = nil
	end
	
	local repeatCount = customization.RepeatCount
	if type(repeatCount) ~= "number" then
		repeatCount = defaults.RepeatCount
	elseif repeatCount < 0 then
		repeatCount = -1
	end
	
	
	local fps = customization.FPS
	local interval = nil
	if type(fps) == "number" then
		interval = 1/fps
	end
	
	local update = customization.Update
	if not updates[update] then
		update = defaults.Update
	end
	
	-- Create tween.
	local tween = setmetatable({
		-- Signals.
		Updated = Signal(),
		Started = Signal(),
		Stopped = Signal(),
		Completed = Signal(),
		
		-- Main arguments.
		Instance = instance,
		Values = values,
		
		-- Value functions.
		UpdateFunctions = updateFunctions,
		ResetFunctions = resetFunctions,
		
		-- Customization.
		InverseTweenTime = tweenTime,
		Ease = ease,
		DelayTime = delayTime,
		Reverses = reverses,
		RepeatCount = repeatCount,
		Interval = interval,
		Table = updates[update],
		
		-- Time markers.
		StartTime = 0,
		StopTime = 0,
		
		-- Trackers.
		Repetitions = 0
	}, Tween)
	
	-- Handle instance destroy.
	instance.Destroying:Connect(function()
		destroy(tween)
	end)
	
	-- Return tween.
	return tween
end
