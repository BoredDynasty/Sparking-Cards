--!strict
local RunService = game:GetService("RunService")

-- frame-rate.luau

local module = {}

function module:GetFrameRate(samples: number?)
	samples = samples or 20

	local total = 0

	for i = 1, samples do
		total += RunService.PreRender:Wait()
	end

	local mean = total / samples
	local frame_rate = 1 / math.max(mean, 1 / 1000)

	return frame_rate
end

--[[
   @param iterations `number?`

   For accuracy, input a number above `10000`.
]]
function module:GetDevicePower(iterations: number?)
	iterations = iterations or 40000

	local x = 0
	local time_start = os.clock()

	for i = 1, iterations do
		x += i
	end

	local delta_time = os.clock() - time_start
	local power = 1 / delta_time

	return power
end

function module:GetPercentileFramesPerSecond(
	percentile: number,
	sorted_frame_buffer: { number },
	total_frames: number?
)
	total_frames = total_frames or 40000

	local target_count = math.ceil(total_frames * percentile)

	local total_frame_time = 0

	for i = 1, target_count do
		total_frame_time += sorted_frame_buffer[i]
	end

	return 1 / (total_frame_time / target_count)
end

--[[
	@within module
	@param threshold number -- The maximum allowed deviation in seconds between frame times.
	@param sample_count number? -- Number of frames to sample for stability check. Defaults to 10.
	@returns boolean -- Returns true if frames are stable within the threshold.
	@desc
	Waits until the frame times are stable within the given threshold.
]]
function module:WaitUntilFramesAreStable(threshold: number, sample_count: number?): boolean
	sample_count = sample_count or 10
	assert(threshold > 0, "Threshold must be positive")
	assert(sample_count > 1, "Sample count must be greater than 1")

	local frame_times = table.create(sample_count, 0)
	while true do
		local total = 0
		for i = 1, sample_count do
			frame_times[i] = RunService.PreRender:Wait()
			total += frame_times[i]
		end

		local mean = total / sample_count
		local variance = 0
		for i = 1, sample_count do
			local diff = frame_times[i] - mean
			variance += diff * diff
		end
		local stddev = math.sqrt(variance / sample_count)

		if stddev <= threshold then
			return true
		end
	end
end

return module
