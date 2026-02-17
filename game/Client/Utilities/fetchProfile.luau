--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local future = require(ReplicatedStorage.Packages.future)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- fetchProfile.luau
-- we needed this one.

local events = ReplicatedStorage.Events
local get_profile = events.GetProfile

return function()
	local fut = future.new(function()
		return get_profile:InvokeServer() :: typemarshaller.Profile
	end)

	repeat
		task.wait(1)
	--print("pending profile fetch")
	until not fut:IsPending()

	local result = fut:Unwrap()

	--[[
	if not result and RunService:IsStudio() then
		result = { Data = profilestructure }
	end
	--]]

	return result
end
