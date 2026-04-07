--!native
--[[
    TripleBenchmark.lua
    Compares SpringShaker, RbxCameraShaker and Shake (Sleitnick)
    by measuring UpdateAll/Update cost per frame in isolation.
]]
local versusBenchmarking = {}
versusBenchmarking.__index = versusBenchmarking

local RunService = game:GetService("RunService")

local SpringShaker = require(script.Parent.Parent)
local CameraShaker = require(script.RbxCameraShaker)
local Shake = require(script.Shake)

local COUNTS = { 1, 10, 50, 100, 250, 1000 }
local DURATION = 10
local GC_WAIT = 5

local camShakerInstance = nil
local shakeInstances = {}

local function measureLoop(updateFn: (dt: number) -> (), duration: number): (number, number, number, number)
	local frameTimes = {}
	local connection = RunService.RenderStepped:Connect(function(dt: number)
		local start = os.clock()
		updateFn(dt)
		local elapsed = (os.clock() - start) * 1000
		table.insert(frameTimes, elapsed)
	end)

	task.wait(duration)
	connection:Disconnect()

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

	return avg, peak, stddev, #frameTimes
end

local function printResult(module: string, count: number, avg: number, peak: number, stddev: number, frames: number)
	print(
		string.format(
			"[%-20s] [%03d instances] avg: %.4fms | peak: %.4fms | stddev: %.4fms | frames: %d",
			module,
			count,
			avg,
			peak,
			stddev,
			frames
		)
	)
end

local function separator(label: string)
	print(string.rep("-", 80))
	print(string.format(">> %s", label))
	print(string.rep("-", 80))
end

local function benchSpringShaker(count: number)
	for i = 1, count do
		local n = SpringShaker:GetPreset("Earthquake")
		SpringShaker:ShakeSustained(n)
	end

	local avg, peak, stddev, frames = measureLoop(function(dt)
		SpringShaker:UpdateAll(dt)
	end, DURATION)

	SpringShaker:RecycleAll()
	task.wait(GC_WAIT)

	printResult("SpringShaker", count, avg, peak, stddev, frames)
	return avg, peak, stddev
end

local function benchRbxCameraShaker(count: number)
	camShakerInstance = CameraShaker.new(Enum.RenderPriority.Camera.Value, function() end)
	camShakerInstance:Start()

	for i = 1, count do
		local preset = CameraShaker.Presets.Earthquake
		camShakerInstance:ShakeSustain(preset)
	end

	local avg, peak, stddev, frames = measureLoop(function(dt)
		camShakerInstance:Update(dt)
	end, DURATION)

	camShakerInstance:Stop()
	camShakerInstance:StopSustained(0)
	camShakerInstance = nil
	task.wait(GC_WAIT)

	printResult("RbxCameraShaker", count, avg, peak, stddev, frames)
	return avg, peak, stddev
end

local function benchShake(count: number)
	shakeInstances = {}

	for i = 1, count do
		local s = Shake.new()
		s.Amplitude = 2.2
		s.Frequency = 0.125
		s.FadeInTime = 2
		s.FadeOutTime = 8
		s.Sustain = true
		s.RotationInfluence = Vector3.new(1.5, 3.5, 1.5)
		s:Start()
		table.insert(shakeInstances, s)
	end

	local avg, peak, stddev, frames = measureLoop(function(dt)
		for _, s in shakeInstances do
			s:Update()
		end
	end, DURATION)

	for _, s in shakeInstances do
		s:Stop()
	end
	table.clear(shakeInstances)
	task.wait(GC_WAIT)

	printResult("Shake", count, avg, peak, stddev, frames)
	return avg, peak, stddev
end

local function benchMemory(label: string, setupFn: () -> (), cleanupFn: () -> ())
	task.wait(GC_WAIT)
	local before = gcinfo()

	setupFn()
	local peak = gcinfo()

	cleanupFn()
	task.wait(GC_WAIT)
	local after = gcinfo()

	print(
		string.format(
			"[%-20s] before: %dKB | peak: %dKB | usage: %dKB | after: %dKB | delta: %dKB",
			label,
			before,
			peak,
			peak - before,
			after,
			after - before
		)
	)
end

local results = {
	SpringShaker = {},
	RbxCameraShaker = {},
	Shake = {},
}

local function printSummary()
	warn(string.rep("=", 80))
	warn("SUMMARY — avg ms per frame")
	warn(string.rep("=", 80))
	warn(string.format("%-12s | %-14s | %-14s | %-14s", "Instances", "SpringShaker", "RbxCameraShaker", "Shake"))
	warn(string.rep("-", 60))
	for _, count in COUNTS do
		local ss = results.SpringShaker[count]
		local rcs = results.RbxCameraShaker[count]
		local sh = results.Shake[count]
		warn(
			string.format(
				"%-12d | %-14s | %-14s | %-14s",
				count,
				ss and string.format("%.4fms", ss) or "N/A",
				rcs and string.format("%.4fms", rcs) or "N/A",
				sh and string.format("%.4fms", sh) or "N/A"
			)
		)
	end
	warn(string.rep("=", 80))
end

function versusBenchmarking.__dump()
	for _, count in COUNTS do
		separator(string.format("%d instances", count))

		local ssAvg = benchSpringShaker(count)
		task.wait(2)
		local rcsAvg = benchRbxCameraShaker(count)
		task.wait(2)
		local shAvg = benchShake(count)

		task.wait(2)
		results.SpringShaker[count] = ssAvg
		results.RbxCameraShaker[count] = rcsAvg
		results.Shake[count] = shAvg
	end

	printSummary()
	task.wait(GC_WAIT * 2)
	separator(`Memory Usage`)

	benchMemory("SpringShaker", function()
		for i = 1, 1000 do
			local n = SpringShaker:GetPreset("Earthquake")
			SpringShaker:ShakeSustained(n)
		end
	end, function()
		SpringShaker:RecycleAll()
	end)

	benchMemory("RbxCameraShaker", function()
		camShakerInstance = CameraShaker.new(Enum.RenderPriority.Camera.Value, function() end)
		camShakerInstance:Start()
		for i = 1, 1000 do
			camShakerInstance:ShakeSustain(CameraShaker.Presets.Earthquake)
		end
	end, function()
		camShakerInstance:Stop()
		camShakerInstance:StopSustained(0)
		camShakerInstance = nil
	end)

	benchMemory("Shake", function()
		shakeInstances = {}
		for i = 1, 1000 do
			local s = Shake.new()
			s.Amplitude = 2.2
			s.Frequency = 0.125
			s.Sustain = true
			s:Start()
			table.insert(shakeInstances, s)
		end
	end, function()
		for _, s in shakeInstances do
			s:Stop()
		end
		table.clear(shakeInstances)
	end)
end

return versusBenchmarking
