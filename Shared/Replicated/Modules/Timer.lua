-- TimerModule.lua
-- A reusable module for tracking and formatting time in Roblox

local TimerModule = {}
TimerModule.__index = TimerModule

export type timer = {
	["startTime"]: number,
	["running"]: boolean,
	["elaspedTime"]: number,
}

-- Creates a new timer instance
function TimerModule.new(): timer
	local self = setmetatable({}, TimerModule)

	self.startTime = 0
	self.running = false
	self.elapsedTime = 0 -- Keeps track of paused time

	return self
end

-- Starts or resumes the timer
function TimerModule:Start()
	if not self.running then
		self.startTime = os.clock() - self.elapsedTime
		self.running = true
	end
end

-- Stops the timer and saves the elapsed time
function TimerModule:Stop()
	if self.running then
		self.elapsedTime = os.clock() - self.startTime
		self.running = false
	end
end

-- Resets the timer to 0
function TimerModule:Reset()
	self.startTime = 0
	self.elapsedTime = 0
	self.running = false
end

-- Gets the current time in seconds
function TimerModule:GetTime()
	if self.running then
		return os.clock() - self.startTime
	else
		return self.elapsedTime
	end
end

-- Formats the time into HH:MM:SS
function TimerModule:FormatTime()
	local totalSeconds = math.floor(self:GetTime())
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = totalSeconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Formats time into custom units (e.g., MM:SS)
function TimerModule:FormatCustom(format)
	local totalSeconds = math.floor(self:GetTime())
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = totalSeconds % 60

	-- Replace placeholders with actual values
	return format
		:gsub("HH", string.format("%02d", hours))
		:gsub("MM", string.format("%02d", minutes))
		:gsub("SS", string.format("%02d", seconds))
end

function TimerModule:Desroy()
	self.running = nil
	self.elaspedTime = nil
	self.startTime = nil
end

return TimerModule
