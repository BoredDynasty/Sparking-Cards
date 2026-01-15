--!nonstrict

-- Permission.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local command_whitelist = require(ReplicatedStorage.Structures["command-whitelist"])

if RunService:IsServer() then
	return function(registry)
		registry:RegisterHook("BeforeRun", function(context)
			if not table.find(command_whitelist, context.Executor.UserId) then
				return "it seems like someone figured out how to open the commands!"
			else
				return nil
			end
		end)
	end
else
	return function()
		return nil
	end
end
