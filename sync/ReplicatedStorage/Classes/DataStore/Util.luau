--!nonstrict

local Util = {}

-- Utilities

-- Function to check if the player is eligible for a daily reward
function Util.getDailyRewards(lastLogin)
	local currentDate = os.date("*t") -- Get current date table
	local lastDate = os.date("*t", lastLogin) -- Convert last login timestamp to date table

	-- Check if the last login was on a different day
	return currentDate.year ~= lastDate.year or currentDate.yday ~= lastDate.yday
end

return Util
