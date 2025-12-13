--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)

export type Assets = { Instance }

local DEFAULT_BATCH_SIZE = 12
local DEFAULT_MAX_PARALLEL = 50

local function preload_assets(assets: Assets, batch_size: number?, max_parallel: number?)
	batch_size = batch_size or DEFAULT_BATCH_SIZE
	max_parallel = max_parallel or DEFAULT_MAX_PARALLEL

	local max_assets = #assets
	if max_assets == 0 then
		return
	end

	-- create batches
	local batches = {} :: { Assets }
	for i = 1, max_assets, batch_size do
		local end_index = math.min(i + batch_size - 1, max_assets)

		local batch = table.create(end_index - i + 1) :: Assets

		table.move(assets, i, end_index, 1, batch)

		table.insert(batches, batch)
	end

	local active_threads = 0
	local completed = SignalPlus() :: SignalPlus.Signal<unknown>

	for i, batch in ipairs(batches) do
		while active_threads >= max_parallel do
			task.wait() -- we wont use RunService:Wait() here
		end

		active_threads += 1
		task.spawn(function()
			-- TODO) use a future here
			local ok, err = pcall(ContentProvider.PreloadAsync, ContentProvider, batch)
			if not ok or err ~= nil then
				warn(err)
			end

			active_threads -= 1
			if active_threads == 0 then
				completed:Fire()
			end
		end)
	end

	-- wait until finished
	completed:Wait()
	completed:Destroy()
end

return preload_assets
