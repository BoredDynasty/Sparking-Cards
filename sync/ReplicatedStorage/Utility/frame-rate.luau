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

return module
