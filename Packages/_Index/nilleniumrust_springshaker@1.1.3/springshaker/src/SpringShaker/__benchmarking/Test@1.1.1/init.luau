local __test = {}
__test.__index = __test

local __benchmarking = script.Parent
local RunService = game:GetService("RunService")
local SpringShaker = require(__benchmarking.Parent)

local INVALID_TRACEBACK_ARG_NOTE = "Argument required %s, but got %s. Traceback: %s"
local NON_EXISTENT_TRACEBACK_ARG_NOTE = "Argument required %s does not exist. Traceback: %s"

local COUNTS = { 1, 10, 50, 100, 250 }
local DURATION = 15

function __test.new()
	local self = setmetatable({
		Results = {},
	}, __test)
	return self
end

function __test:__dumpStart(count: number)
	if not count then
		warn(string.format(NON_EXISTENT_TRACEBACK_ARG_NOTE, "number", debug.traceback("", 2)))
		return
	end
	if typeof(count) ~= "number" then
		warn(string.format(INVALID_TRACEBACK_ARG_NOTE, "number", typeof(count), debug.traceback("", 2)))
		return
	end
	self:__Dump(count)
end

function __test:__MemoryDump(instanceCount: number)
	local before = gcinfo()

	for i = 1, instanceCount do
		local n = SpringShaker:GetPreset("Earthquake")
		SpringShaker:ShakeSustained(n)
	end

	local peak = gcinfo()
	SpringShaker:RecycleAll()
	task.delay(5, function()
		local after = gcinfo()

		warn(
			string.format(
				"[%03d instances] before: %dKB | peak: %dKB | after: %dKB | delta: %dKB",
				instanceCount,
				before,
				peak,
				after,
				after - before
			)
		)
	end)
end

function __test:__Dump(instanceCount: number)
	for i = 1, instanceCount do
		local n = SpringShaker:GetPreset("Earthquake")
		SpringShaker:ShakeSustained(n)
	end

	local frameTimes = {}

	local connection = RunService.RenderStepped:Connect(function(dt)
		local start = os.clock()
		SpringShaker:UpdateAll(dt)
		local elapsed = (os.clock() - start) * 1000
		table.insert(frameTimes, elapsed)
	end)

	task.wait(DURATION)
	connection:Disconnect()
	SpringShaker:RecycleAll()

	local total = 0
	local peak = 0
	for _, t in frameTimes do
		total += t
		if t > peak then
			peak = t
		end
	end

	local avg = total / #frameTimes
	local variance = 0
	for _, t in frameTimes do
		variance += (t - avg) ^ 2
	end
	local stddev = math.sqrt(variance / #frameTimes)

	self.Results[instanceCount] = {
		avg = avg,
		peak = peak,
		stddev = stddev,
		frames = #frameTimes,
	}

	warn(
		string.format(
			"[%03d instances] avg: %.4fms | peak: %.4fms | stddev: %.4fms | frames: %d",
			instanceCount,
			avg,
			peak,
			stddev,
			#frameTimes
		)
	)
end

function __test:__RunAll()
	warn(string.rep("-", 60))
	warn(string.format("SpringShaker Benchmark — %ds per count", DURATION))
	warn(string.format("Counts: %s", table.concat(COUNTS, ", ")))
	warn(string.rep("-", 60))

	for _, count in COUNTS do
		print(string.format("-> Running %d instances...", count))
		self:__dumpStart(count)
		task.wait(2)
	end

	self:__PrintSummary()
end

function __test:__PrintSummary()
	warn(string.rep("-", 60))
	warn("Summary:")
	for _, count in COUNTS do
		local r = self.Results[count]
		if not r then
			continue
		end
		warn(string.format("  [%03d] avg: %.4fms | peak: %.4fms | stddev: %.4fms", count, r.avg, r.peak, r.stddev))
	end

	local first = self.Results[COUNTS[1]]
	local last = self.Results[COUNTS[#COUNTS]]
	if first and last then
		local countRatio = COUNTS[#COUNTS] / COUNTS[1]
		local perfRatio = last.avg / first.avg

		local linearity = (1 - (perfRatio / countRatio)) * 100
		warn(
			string.format(
				"  Scaling efficiency: %.1f%% (higher = better, 0%% = linear, 100%% = no overhead)",
				linearity
			)
		)
	end

	warn(string.rep("-", 60))
end

return __test
