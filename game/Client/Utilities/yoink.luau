--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- yoink.luau

-- yoinks values from the server.

local yoink = {}

local events = ReplicatedStorage.RemoteEvents

export type registered = "profile_data"

local registeredValues = {
	profile_data = events:FindFirstChild("GetProfile") :: RemoteFunction,
} :: { [string]: RemoteFunction }

--[[

	```luau

	yoink:grab(name: registered, ...: any?): any?
	
	```

	Yoinks a value from the server.
	Returns the value or nil if not found.
	]]
function yoink:grab(name: registered, ...: any?): any?
	local i = registeredValues[name]
	if i then
		return i:InvokeServer(...) :: any
	end
	return nil
end

return yoink
