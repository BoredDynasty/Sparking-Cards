--!strict
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)

local BATCH_SIZE = 12
local MAX_PARALLEL_LOADS = 50

return function(assetsDict: { any })
	local startTime = os.clock()

	-- Combine assets into one table
	local pre_allocated = #assetsDict or 2000
	local assets = table.create(pre_allocated) -- pre-allocate approximate size
	task.spawn(function()
		for _, asset in ipairs(assetsDict) do
			table.insert(assets, asset)
		end
	end)
	local completed = SignalPlus()

	local maxAssets = #assets
	local loadedCount = 0

	-- split assets into batches
	local batches: { ((({ any }?) & { any } & { any })?) & ({ any }?) & { any } & { any } } = {}
	for i = 1, #assets, BATCH_SIZE do
		local batch = {}
		for j = i, math.min(i + BATCH_SIZE - 1, #assets) do
			table.insert(batch, assets[j])
		end
		table.insert(batches, batch)
	end

	local activeThreads = 0
	local success, err
	local results = table.create(20) -- theres only so much room for error
	-- process batches in parallel hehe
	for _, batch in ipairs(batches) do
		while activeThreads >= MAX_PARALLEL_LOADS do
			task.wait()
		end

		activeThreads += 1
		task.spawn(function()
			success, err = pcall(function()
				return ContentProvider:PreloadAsync(batch)
			end)
			if not success or err ~= nil then
				warn(err)
				local concatenated_batch: string
				for k, v in pairs(batch) do
					concatenated_batch = concatenated_batch .. k .. ":" .. v .. "\n" -- concatenate key/value pairs, with a newline in-between
				end
				warn("Couldn't download batch: ", concatenated_batch)
			end
			loadedCount += #batch
			table.insert(results, string.format("Loaded: %d/%d", loadedCount, maxAssets))

			activeThreads -= 1
			if activeThreads == 0 and loadedCount >= maxAssets then
				completed:Fire()
			end
		end)
	end
	-- wait for batching to complete
	completed:Wait()
	local endTime = math.round((os.clock() - startTime) * 10000) / 10000
	print("Loaded in: " .. tostring(endTime))
	table.clear(assets)
	table.clear(batches)

	return completed, results
end
