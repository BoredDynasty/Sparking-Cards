-- Services.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

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
if not Signal then error("Could not find a signal module.") end
Signal = require(Signal)
if type(Signal) == "table" and Signal.new then Signal = Signal.new end

-- Customization defaults.
local defaults = require(data.Defaults)

-- Shared types.
local types = require(data.Types)

-- Signal type.
type Signal = types.Signal

-- Internal tween type.
type InternalTween = types.InternalTween & {
	Identifier: number,
	
	PlayerReadyConnection: RBXScriptConnection,
	
	Updated: Signal<number>,
	Started: Signal,
	Stopped: Signal,
	Completed: Signal,
}

local updates = {
	PreSimulation = true,
	PostSimulation = true
}

-- Network packets.
local packets = CollectionService:GetTagged("Packets")[1]

-- Roblox API map.
local apiMap = CollectionService:GetTagged("APIMap")[1]
if not apiMap then error("Could not find APIMap module.") end
apiMap = require(apiMap)

for _, data in apiMap do
	if typeof(data) == "function" then
		print(data)
	else
		for _, subData in data do
			if type(subData) == "function" then
				print(subData)
			end
		end
	end
end

-- Setup API map retrieval for clients.
if packets then
	packets = require(packets)
	
	packets.GetAPIMap.OnServerInvoke = function()
		return apiMap
	end
else
	local remote = Instance.new("RemoteFunction")
	remote.Name = "GetAPIMap"
	remote.OnServerInvoke = function()
		return apiMap
	end
	remote.Parent = script.Parent
	
	warn("Could not find 'Packets' module. Server tweening has been disabled.")
	return nil
end 

-- Quick access to packets.
local tweenReadyPacket = packets.TweenReady
local createTweenPacket = packets.CreateTween
local startTweenPacket = packets.StartTween
local stopTweenPacket = packets.StopTween
local resetTweenPacket = packets.ResetTween
local destroyTweenPacket = packets.DestroyTween

-- Store all possible tween identifiers.
local identifiers = {}
for identifier = 0, 255, 1 do
	identifiers[identifier] = true
end

-- Ready players table.
local players = {}
tweenReadyPacket.OnServerEvent:Connect(function(player) players[player] = true end)
Players.PlayerRemoving:Connect(function(player) players[player] = nil end)

-- Tweens collection.
local tweens: {InternalTween} = {}

-- Tween functions.
local function stop(tween: InternalTween)
	-- Update instance values.
	local alpha = tween.Ease(tween.Alpha)
	for _, update in tween.UpdateFunctions do
		update(alpha)
	end
	
	-- Tween removal.
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
	
	-- Fire stopped signal.
	tween.Stopped:Fire()
end
local function destroy(tween: InternalTween)
	-- Disconnect new player connection.
	tween.PlayerReadyConnection:Disconnect()
	
	-- Free up identifier.
	identifiers[tween.Identifier] = true
	
	-- Ensure no playback.
	if not tween.StopTime then
		-- Update instance values.
		local alpha = tween.Ease(tween.Alpha)
		for _, update in tween.UpdateFunctions do
			update(alpha)
		end
		
		-- Tween removal.
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

-- Setup tween processing.
RunService.PostSimulation:Connect(function()
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
		
		if tween.Reverse then
			alpha = 1 - alpha
		end
		
		-- Save alpha.
		tween.Alpha = alpha
		
		-- Fire updated signal with raw alpha.
		tween.Updated:Fire(alpha)
		
		-- Phase completion stuff.
		if phaseCompleted then
			if tween.Reverse then-- Already going in reverse. Means reversing is enabled, so no need to check for that.
				tween.Repetitions += 1
				if tween.RepeatCount == -1 or tween.Repetitions < tween.RepeatCount then
					if tween.DelayTime then tween.WaitTime = currentTime end
					tween.StartTime = currentTime
					tween.Reverse = nil
				else
					if not tween.StopTime then
						stop(tween)
						tween.Completed:Fire()
					end
				end
			else-- Not going in reverse.
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
							tween.Completed:Fire()
						end
					end
				end
			end
		end
	end
end)

-- Tween class.
local Tween = {}
Tween.__index = Tween

Tween.Start = function(tween: InternalTween)
	-- Verify playback.
	if not tween.StopTime then return end
	
	-- Handle conflicts.
	local instance = tween.Instance
	local values = tween.Values
	
	for _, otherTween in tweens do
		if otherTween.Instance ~= instance then continue end
		
		for value in otherTween.Values do
			if values[value] then
				stop(otherTween)
				tweens[otherTween] = nil
				break
			end
		end
	end
	
	-- Set time markers.
	local stopDuration = tick() - tween.StopTime
	tween.StartTime += stopDuration
	if tween.Interval then tween.LastUpdate = -math.huge end
	if tween.WaitTime then tween.WaitTime += stopDuration end
	tween.StopTime = nil
	
	-- Notify clients.
	for player in players do
		startTweenPacket:FireClient(player, tween.Identifier)
	end
	
	-- Add tween.
	table.insert(tweens, tween)
	tween.Index = #tweens
	
	-- Fire started signal.
	tween.Started:Fire()
end
Tween.Stop = function(tween: InternalTween)
	if tween.StopTime then return end
	
	for player in players do
		stopTweenPacket:FireClient(player, tween.Identifier)
	end
	
	stop(tween)
end
Tween.Reset = function(tween: InternalTween)
	for player in players do
		resetTweenPacket:FireClient(player, tween.Identifier)
	end
	
	if not tween.StopTime then stop(tween) end
	tween.WaitTime = nil
	tween.StopTime = 0
	tween.StartTime = 0
	tween.Repetitions = 0
	for _, reset in tween.ResetFunctions do reset() end
end
Tween.Destroy = function(tween: InternalTween)
	for player in players do
		destroyTweenPacket:FireClient(player, tween.Identifier)
	end
	
	destroy(tween)
end

-- Tween creation.
return function(instance, values, customization)
	-- Argument errors.
	if typeof(instance) ~= "Instance" then error("No instance provided.", 2) end
	if type(values) ~= "table" or not next(values) then error("No values provided.", 2) end
	
	-- Get and verify identifier.
	local identifier = next(identifiers)
	if not identifier then error("Maximum server tweens (256) exceeded. Destroy tweens to free up space.", 2) end
	
	-- Handle values.
	local updateFunctions, resetFunctions = getUpdateFunctions(apiMap, instance, values)
	
	-- Handle customization.
	if type(customization) ~= "table" then customization = {} end
	
	local customizationForClient = {}
	
	local tweenTime = customization.Time
	if type(tweenTime) ~= "number" then
		tweenTime = defaults.InverseTime
	elseif tweenTime <= 0 then
		tweenTime = 0
	else
		tweenTime = 1/tweenTime
	end
	customizationForClient[1] = tweenTime
	
	local ease = nil
	do
		local easingStyle = customization.EasingStyle
		local easing = easingFunctions[easingStyle]
		if not easing then
			easing = easingFunctions[defaults.EasingStyle]
			easingStyle = defaults.EasingStyle
		end
		customizationForClient[2] = easingStyle
		if easingStyle == "Linear" then
			ease = easing
		else
			local easingDirection = customization.EasingDirection
			ease = easing[easingDirection]
			if not ease then
				easingDirection = defaults.EasingDirection
				ease = easing[easingDirection]
			end
			customizationForClient[3] = easingDirection
		end
	end
	
	
	local delayTime = customization.DelayTime
	if type(delayTime) ~= "number" or delayTime <= 0 then
		delayTime = nil
	end
	customizationForClient[4] = delayTime
	
	local reverses = customization.Reverses
	if reverses ~= true then
		reverses = nil
	end
	customizationForClient[5] = reverses
	
	local repeatCount = customization.RepeatCount
	if type(repeatCount) ~= "number" then
		repeatCount = defaults.RepeatCount
	elseif repeatCount < 0 then
		repeatCount = -1
	end
	customizationForClient[6] = repeatCount
	
	
	local fps = customization.FPS
	local interval = nil
	if type(fps) == "number" then
		interval = 1/fps
	end
	customizationForClient[7] = interval
	
	local update = customization.Update
	if updates[update] then
		customizationForClient[8] = update
	else
		customizationForClient[8] = defaults.Update
	end
	
	-- Notify all clients.
	for player in players do
		createTweenPacket:FireClient(player, identifier, instance, values, customizationForClient)
	end
	
	-- Create tween.
	local tween = nil
	tween = setmetatable({
		-- New player handling.
		PlayerReadyConnection = tweenReadyPacket.OnServerEvent:Connect(function(player)
			createTweenPacket:FireClient(player, identifier, instance, values, customizationForClient)
			if not tween.StopTime then
				startTweenPacket:FireClient(player, identifier, tick() - tween.StartTime, tween.Repetitions)
			end
		end),
		
		-- Identifier.
		Identifier = identifier,
		
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
