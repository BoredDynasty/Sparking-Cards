--!native
local __test = {}
__test.__index = __test
local __benchmarking = script.Parent
local RunService = game:GetService("RunService")
local SpringShaker = require(__benchmarking.Parent)
local COUNTS = { 1, 10, 50, 100, 250 }
local DURATION = 15

function __test.new()
	local self = setmetatable({}, __test)
	self.Results = {}
	return self
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

		print(
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

	self.Results[instanceCount] = { avg = avg, peak = peak, stddev = stddev, frames = #frameTimes }

	warn(
		string.format(
			"[%03d instances] avg: %.3fms | peak: %.3fms | stddev: %.3fms | frames: %d",
			instanceCount,
			avg,
			peak,
			stddev,
			#frameTimes
		)
	)
end

function __test:__RunAll()
	warn(string.format("Benchmarking %d counts over %ds each...", #COUNTS, DURATION))
	for _, count in COUNTS do
		warn(string.format("-> Running %d instances...", count))
		self:__Dump(count)
		task.wait(2)
	end
	warn("Benchmark complete.")
end

return __test
