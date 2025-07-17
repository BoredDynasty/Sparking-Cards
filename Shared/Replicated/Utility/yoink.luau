--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- yoink.luau

-- yoinks values from the client-server boundary.

local yoink = {
	client = {},
	boundary = {},
}

local events = ReplicatedStorage.Events

export type registered = "profile_data"

yoink.client.registeredValues =
	{ profile_data = events:FindFirstChild("GetProfile") :: RemoteFunction } :: { [registered]: RemoteFunction }

yoink.boundary.registeredValues = {
	profile_data = events:FindFirstChild("GetProfileBoundary") :: BindableFunction,
} :: { [registered]: BindableFunction }

--[[

	```luau

	yoink.client:grab(name: registered, ...: any?): any?
	
	```

	Yoinks a value from the server.
	
	Returns the value or nil if not found.
	]]
function yoink.client:grab(name: registered, ...: any?): any?
	local i = yoink.client.registeredValues[name]
	if i then
		return i:InvokeServer(...) :: any
	end
	return nil
end
--[[

	```luau

	yoink.boundary:grab(name: registered, ...: any?): any?
	
	```

	Yoinks a value from the same side of the client-server boundary.

	Returns the value or nil if not found.
	]]
function yoink.boundary:grab(name: registered, ...: any?): any?
	local i = yoink.boundary.registeredValues[name]
	if i then
		return i:Invoke(...) :: any
	end
	return nil
end

return yoink
