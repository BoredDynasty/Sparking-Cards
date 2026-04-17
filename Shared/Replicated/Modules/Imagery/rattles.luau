--!strict

-- rattles.luau

--[[
    rattles - A Luau port of the Rust terminal spinner library
    rrovides minimal, dependency-free terminal spinners for Roblox
]]

export type Size = {
	width: number,
	height: number,
}

export type Rattle<T> = {
	size: Size,
	interval: number,
	frames: { { string } },
}

export type Rattler<T> = {
	interval_ms: number,
	offset: number,
	_type: T,

	new: (self: Rattler<T>) -> Rattler<T>,
	size: (self: Rattler<T>) -> Size,
	len: (self: Rattler<T>) -> number,
	is_empty: (self: Rattler<T>) -> boolean,
	frame: (self: Rattler<T>, index: number) -> string,
	frames: (self: Rattler<T>, index: number) -> { string },
	frame_at: (self: Rattler<T>, elapsed_ms: number) -> string,
	frames_at: (self: Rattler<T>, elapsed_ms: number) -> { string },
	current_frame: (self: Rattler<T>) -> string,
	current_frames: (self: Rattler<T>) -> { string },
	index: (self: Rattler<T>) -> number,
	interval: (self: Rattler<T>) -> number,
	set_interval: (self: Rattler<T>, interval_ms: number) -> Rattler<T>,
	offset: (self: Rattler<T>, offset: number) -> Rattler<T>,
	reverse: (self: Rattler<T>) -> Rattler<T>,
}

export type TickedRattler<T> = {
	interval_ms: number,
	offset: number,
	current: number,
	_type: T,

	new: (self: TickedRattler<T>) -> TickedRattler<T>,
	size: (self: TickedRattler<T>) -> Size,
	len: (self: TickedRattler<T>) -> number,
	is_empty: (self: TickedRattler<T>) -> boolean,
	current_frame: (self: TickedRattler<T>) -> string,
	current_frames: (self: TickedRattler<T>) -> { string },
	index: (self: TickedRattler<T>) -> number,
	tick: (self: TickedRattler<T>) -> { string },
	tick_by: (self: TickedRattler<T>, steps: number) -> { string },
	reset: (self: TickedRattler<T>) -> nil,
	interval: (self: TickedRattler<T>) -> number,
	set_interval: (self: TickedRattler<T>, interval_ms: number) -> TickedRattler<T>,
	offset: (self: TickedRattler<T>, offset: number) -> TickedRattler<T>,
	reverse: (self: TickedRattler<T>) -> Rattler<T>,
}

local Rattles = {}

local function apply_direction(index: number, len: number, reversed: boolean): number
	if reversed and len > 0 then
		return (len - 1) - index
	end
	return index
end

local function frame_at(elapsed_ms: number, interval_ms: number, len: number): number
	if len == 0 then
		return 0
	end
	return math.floor(elapsed_ms / interval_ms) % len
end

--[[ Rattler Implementation (Time-based) ]]
local Rattler_mt = {}
Rattler_mt.__index = Rattler_mt

function Rattler_mt.new<T>(rattle: Rattle<T>): Rattler<T>
	return setmetatable({
		interval_ms = rattle.interval,
		offset = 0,
		_type = rattle,
		_reversed = false,
	}, Rattler_mt) :: any
end

function Rattler_mt.size<T>(self: Rattler<T>): Size
	return self._type.size
end

function Rattler_mt.len<T>(self: Rattler<T>): number
	return #self._type.frames
end

function Rattler_mt.is_empty<T>(self: Rattler<T>): boolean
	return self:len() == 0
end

function Rattler_mt.frames<T>(self: Rattler<T>, index: number): { string }
	local len = self:len()
	if len == 0 then
		return {}
	end
	local shifted = (index + self.offset) % len
	local idx = apply_direction(shifted, len, self._reversed) + 1
	return self._type.frames[idx]
end

function Rattler_mt.frame<T>(self: Rattler<T>, index: number): string
	local frames = self:frames(index)
	return if #frames > 0 then frames[1] else ""
end

function Rattler_mt.frames_at<T>(self: Rattler<T>, elapsed_ms: number): { string }
	local len = self:len()
	local base = frame_at(elapsed_ms, self.interval_ms, len)
	local shifted = if len == 0 then 0 else (base + self.offset) % len
	local idx = apply_direction(shifted, len, self._reversed) + 1
	return if len > 0 then self._type.frames[idx] else {}
end

function Rattler_mt.frame_at<T>(self: Rattler<T>, elapsed_ms: number): string
	local frames = self:frames_at(elapsed_ms)
	return if #frames > 0 then frames[1] else ""
end

function Rattler_mt.current_frame<T>(self: Rattler<T>): string
	local elapsed = tick() * 1000
	return self:frame_at(elapsed)
end

function Rattler_mt.current_frames<T>(self: Rattler<T>): { string }
	local elapsed = tick() * 1000
	return self:frames_at(elapsed)
end

function Rattler_mt.index<T>(self: Rattler<T>): number
	local len = self:len()
	local elapsed = tick() * 1000
	local base = frame_at(elapsed, self.interval_ms, len)
	local shifted = if len == 0 then 0 else (base + self.offset) % len
	return apply_direction(shifted, len, self._reversed)
end

function Rattler_mt.interval<T>(self: Rattler<T>): number
	return self.interval_ms
end

function Rattler_mt.set_interval<T>(self: Rattler<T>, interval_ms: number): Rattler<T>
	self.interval_ms = math.max(1, interval_ms)
	return self
end

function Rattler_mt.offset<T>(self: Rattler<T>, offset: number): Rattler<T>
	local len = self:len()
	self.offset = if len == 0 then 0 else offset % len
	return self
end

function Rattler_mt.reverse<T>(self: Rattler<T>): Rattler<T>
	self._reversed = not self._reversed
	return self
end

--[[ TickedRattler Implementation (Tick-based) ]]
local TickedRattler_mt = {}
TickedRattler_mt.__index = TickedRattler_mt

function TickedRattler_mt.new<T>(rattle: Rattle<T>): TickedRattler<T>
	return setmetatable({
		interval_ms = rattle.interval,
		offset = 0,
		current = 0,
		_type = rattle,
		_reversed = false,
	}, TickedRattler_mt) :: any
end

function TickedRattler_mt.size<T>(self: TickedRattler<T>): Size
	return self._type.size
end

function TickedRattler_mt.len<T>(self: TickedRattler<T>): number
	return #self._type.frames
end

function TickedRattler_mt.is_empty<T>(self: TickedRattler<T>): boolean
	return self:len() == 0
end

function TickedRattler_mt.current_frames<T>(self: TickedRattler<T>): { string }
	local len = self:len()
	if len == 0 then
		return {}
	end
	local shifted = (self.current + self.offset) % len
	local idx = apply_direction(shifted, len, self._reversed) + 1
	return self._type.frames[idx]
end

function TickedRattler_mt.current_frame<T>(self: TickedRattler<T>): string
	local frames = self:current_frames()
	return if #frames > 0 then frames[1] else ""
end

function TickedRattler_mt.index<T>(self: TickedRattler<T>): number
	local len = self:len()
	if len == 0 then
		return 0
	end
	return apply_direction((self.current + self.offset) % len, len, self._reversed)
end

function TickedRattler_mt.tick<T>(self: TickedRattler<T>): { string }
	local len = self:len()
	if len == 0 then
		return {}
	end
	self.current = (self.current + 1) % len
	return self:current_frames()
end

function TickedRattler_mt.tick_by<T>(self: TickedRattler<T>, steps: number): { string }
	local len = self:len()
	if len == 0 then
		return {}
	end
	self.current = (self.current + (steps % len)) % len
	return self:current_frames()
end

function TickedRattler_mt.reset<T>(self: TickedRattler<T>)
	self.current = 0
end

function TickedRattler_mt.interval<T>(self: TickedRattler<T>): number
	return self.interval_ms
end

function TickedRattler_mt.set_interval<T>(self: TickedRattler<T>, interval_ms: number): TickedRattler<T>
	self.interval_ms = math.max(1, interval_ms)
	return self
end

function TickedRattler_mt.offset<T>(self: TickedRattler<T>, offset: number): TickedRattler<T>
	local len = self:len()
	self.offset = if len == 0 then 0 else offset % len
	return self
end

function TickedRattler_mt.reverse<T>(self: TickedRattler<T>): Rattler<T>
	self._reversed = not self._reversed
	return self
end

--[[ Preset Spinners ]]
function Rattles.dots(): Rattler<any>
	local rattle: Rattle<any> = {
		size = { width = 1, height = 1 },
		interval = 80,
		frames = {
			{ "⠋" },
			{ "⠙" },
			{ "⠹" },
			{ "⠸" },
			{ "⠼" },
			{ "⠴" },
			{ "⠦" },
			{ "⠧" },
			{ "⠇" },
			{ "⠏" },
		},
	}
	return Rattler_mt.new(rattle)
end

function Rattles.line(): Rattler<any>
	local rattle: Rattle<any> = {
		size = { width = 1, height = 1 },
		interval = 130,
		frames = { { "-" }, { "\\" }, { "|" }, { "/" } },
	}
	return Rattler_mt.new(rattle)
end

function Rattles.arrow(): Rattler<any>
	local rattle: Rattle<any> = {
		size = { width = 1, height = 1 },
		interval = 100,
		frames = { { "←" }, { "↖" }, { "↑" }, { "↗" }, { "→" }, { "↘" }, { "↓" }, { "↙" } },
	}
	return Rattler_mt.new(rattle)
end

function Rattles.clock(): Rattler<any>
	local rattle: Rattle<any> = {
		size = { width = 1, height = 1 },
		interval = 100,
		frames = {
			{ "🕐" },
			{ "🕑" },
			{ "🕒" },
			{ "🕓" },
			{ "🕔" },
			{ "🕕" },
			{ "🕖" },
			{ "🕗" },
			{ "🕘" },
			{ "🕙" },
			{ "🕚" },
			{ "🕛" },
		},
	}
	return Rattler_mt.new(rattle)
end

function Rattles.ticked_dots(): TickedRattler<any>
	local rattle: Rattle<any> = {
		size = { width = 1, height = 1 },
		interval = 80,
		frames = {
			{ "⠋" },
			{ "⠙" },
			{ "⠹" },
			{ "⠸" },
			{ "⠼" },
			{ "⠴" },
			{ "⠦" },
			{ "⠧" },
			{ "⠇" },
			{ "⠏" },
		},
	}
	return TickedRattler_mt.new(rattle)
end

return Rattles
