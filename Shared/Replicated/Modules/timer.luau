--!nonstrict

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
	Destroy: (self: Timer) -> (),
}

function Timer.new(): Timer
	return setmetatable({
		startTime = 0,
		running = false,
		elapsedTime = 0,
	}, Timer)
end

function Timer:Start()
	if not self.running then
		self.startTime = os.clock() - self.elapsedTime
		self.running = true
	end
end

function Timer:Stop()
	if self.running then
		self.elapsedTime = os.clock() - self.startTime
		self.running = false
	end
end

function Timer:Reset()
	self.startTime = 0
	self.elapsedTime = 0
	self.running = false
end

function Timer:GetTime(): number
	return if self.running then os.clock() - self.startTime else self.elapsedTime
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
