--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)

-- timer.luau
-- A reusable module for tracking and formatting time in Roblox

local Timer = {}
Timer.__index = Timer

export type Timer = {
	startTime: number,
	running: boolean,
	elapsedTime: number,

	new: () -> Timer,
	Start: (self: Timer) -> (),
	Stop: (self: Timer) -> (),
	Reset: (self: Timer) -> (),
	GetTime: (self: Timer) -> number,
	FormatTime: (self: Timer) -> string,
	FormatCustom: (self: Timer, format: string) -> string,
	interval: <T...>(self: Timer, duration: number, f: (T...) -> (), ...any) -> SignalPlus.Signal<>,

	cancel_interval: SignalPlus.Signal<>,

	Destroy: (self: Timer) -> (),
}

function Timer.new(): Timer
	return setmetatable({
		startTime = 0,
		running = false,
		elapsedTime = 0,
		incrementThread = nil :: thread?,
		cancel_interval = nil,
	}, Timer)
end

function Timer:Start()
	if not self.running then
		self.startTime = os.clock() - self.elapsedTime
		self.running = true
	end
	return self
end

function Timer:interval<T...>(self: Timer, duration: number, f: (T...) -> (), ...: T...)
	local function inner(duration: number, f: (T...) -> (), ...: T...)
		local nextTick = os.clock() + duration
		while true do
			task.wait(nextTick - os.clock())
			task.spawn(f, ...)
			nextTick += duration
		end
	end

	local thread = task.spawn(inner, duration, f, ...)

	local cancelSignal = SignalPlus()
	cancelSignal:Connect(function()
		task.cancel(thread)
	end)

	self.cancel_interval = cancelSignal

	return cancelSignal
end

function Timer:Stop()
	if self.running then
		self.elapsedTime = os.clock() - self.startTime
		self.running = false
		if self.incrementThread :: thread? then
			task.cancel(self.incrementThread)
		end
	end
	return self
end

function Timer:Reset()
	self.startTime = 0
	self.elapsedTime = 0
	self.running = false
	if self.incrementThread :: thread? then
		task.cancel(self.incrementThread)
	end
	return self
end

function Timer:GetTime(): number
	local currentTime = os.clock()
	if self.running then
		self.elapsedTime = currentTime - self.startTime
	end
	return self.elapsedTime
end

function Timer:FormatTime(): string
	local totalSeconds = math.floor(self:GetTime())
	return string.format(
		"%02d:%02d:%02d",
		math.floor(totalSeconds / 3600),
		math.floor((totalSeconds % 3600) / 60),
		totalSeconds % 60
	)
end

function Timer:FormatCustom(format: string): string
	local totalSeconds = math.floor(self:GetTime())
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = totalSeconds % 60

	return format
		:gsub("HH", string.format("%02d", hours))
		:gsub("MM", string.format("%02d", minutes))
		:gsub("SS", string.format("%02d", seconds))
end

function Timer:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return Timer
