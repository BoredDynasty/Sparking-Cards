--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ratelimit = require(ReplicatedStorage.Utility.ratelimit)

-- limits.luau
-- a module for "retry" limits

return table.freeze({
	update_limit = ratelimit(10, 5),
	-- can happen every 1 second once.
	subsequent_limit = ratelimit(1, 1),
	debounce_limit = ratelimit(1, 3),
	--[[
		Waits 3 second before setting the debounce to false
	]]
	debounce = function(condition: boolean)
		task.delay(3, function()
			condition = false
		end)
	end,
})
