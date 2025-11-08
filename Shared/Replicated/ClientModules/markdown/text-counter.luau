--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local observer = require(ReplicatedStorage.Utility.observer)
local promise = require(ReplicatedStorage.Packages.promise)

local counter = {}
counter.__index = counter

export type props = {
	to: number,
	from: number,
	direction: "up" | "down",
	delay: number,
	duration: number,
	label: TextLabel?,
	separator: string?,
	onStart: (() -> ())?,
	onEnd: (() -> ())?,
}

type self = {
	To: number,
	From: number,
	Direction: "up" | "down",
	Delay: number,
	Duration: number,
	Label: TextLabel?,
	Separator: string,
	OnStart: (() -> ())?,
	OnEnd: (() -> ())?,

	_running: observer.Observer<boolean>,
	_startTime: number?,

	completed: SignalPlus.Signal<>,
}

-- Utility: get decimal places
local function getDecimalPlaces(num: number)
	local str = tostring(num)

	local dot = string.find(str, "%.")

	if dot then
		local decimals = string.sub(str, dot + 1)

		if tonumber(decimals) ~= 0 then
			return #decimals
		end
	end

	return 0
end

--// Spring-based lerp (simple, not physically accurate)
-- we can use shared/modules/mathematics/physical-spring
-- but we're not going to to do that.
local function springLerp(
	current: number,
	target: number,
	deltaTime: number,
	stiffness: number,
	damping: number
)
	local diff = target - current

	return current + diff * math.clamp(stiffness * deltaTime, 0, 1) - diff * (damping * deltaTime)
end

--[[
   ```luau

   local counter = require(path.to.text-counter)

   local myCounter = counter.new({
      to = 100,
      from = 0,
      direction = "up",
      delay = 1,
      duration = 5,
      label = myTextLabel, -- expects a TextLabel
      separator = ",",
      onStart = function()
         print("Counter started!")
      end,
      onEnd = function()
         print("Counter ended!")
      end,
   })

   myCounter:Start()

   ```
]]
function counter.new(props: props): setmetatable<self, typeof(counter)>
	local self = setmetatable({}, counter)

	self.To = props.to or 0
	self.From = props.from or 0
	self.Direction = props.direction or "up"
	self.Delay = props.delay or 0
	self.Duration = props.duration or 2
	self.Label = props.label -- expects a TextLabel
	self.Separator = props.separator or ""
	self.OnStart = props.onStart
	self.OnEnd = props.onEnd

	self._startTime = nil
	self._running = observer.new(false)

	self.completed = SignalPlus()

	return self
end

function counter:Start()
	if self._running:Get() then
		return
	end

	self._running:Set(true)

	if typeof(self.OnStart) == "function" then
		task.spawn(self.OnStart)
	end

	task.wait(self.Delay)

	local fromValue = self.Direction == "down" and self.To or self.From
	local toValue = self.Direction == "down" and self.From or self.To

	local startTime = os.clock()

	-- local endTime = startTime + self.Duration :: number

	local value = fromValue

	local maxDecimals = math.max(getDecimalPlaces(self.From), getDecimalPlaces(self.To))

	local stiffness = 6 / self.Duration :: number
	local damping = 2 / self.Duration :: number

	local connection = nil :: RBXScriptConnection?

	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		local now = os.clock()

		local alpha = math.clamp((now - startTime) / self.Duration :: number, 0, 1)
		value = springLerp(value, toValue, deltaTime, stiffness, damping)

		if self.Label then
			local formatted = string.format(("%." .. maxDecimals .. "f") :: any, value)

			if self.Separator ~= "" then
				formatted = formatted:gsub(",", self.Separator :: string)
			end

			(self.Label :: TextLabel).Text = formatted
		end

		if self._running:Get() == false and connection then
			connection:Disconnect()
			self.completed:Fire()
		end

		if alpha >= 1 then
			if self.Label then
				(self.Label :: TextLabel).Text = tostring(toValue)
			end

			if connection then
				connection:Disconnect()
				self.completed:Fire()
			end

			self._running:Set(false)
			if typeof(self.OnEnd) == "function" then
				task.spawn(self.OnEnd)
			end
		end
	end)
end

function counter:Destroy()
	self._running:Set(false)

	promise.defer(function(resolve)
		self._running:Destroy()
		self.completed:Destroy()
		resolve()
	end)

	table.clear(self)
	setmetatable(self, nil)
end

return counter
