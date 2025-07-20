--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local promise = require(ReplicatedStorage.Packages.promise)

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

function yoink.client:grab(name: registered, ...: any?): any?
	local i = yoink.client.registeredValues[name]
	if not i then
		return nil
	end

	local function invokePromise()
		return promise.new(function(resolve, reject)
			local success, value: any? = pcall(function(...)
				return i:InvokeServer(...)
			end)

			if success and value then
				resolve(value :: any)
			else
				reject(value or "Failed to get value")
			end
		end)
	end

	-- Wait for the promise to resolve and return the actual value
	local success, result = pcall(function(...)
		return promise.retry(invokePromise, 3, ...):expect()
	end)

	if success then
		return result
	else
		warn("Failed to grab value:", result)
		return nil
	end
end

function yoink.boundary:grab(name: registered, ...: any?): any?
	local i = yoink.boundary.registeredValues[name]
	if not i then
		return nil
	end

	local success, result = pcall(function(...)
		return i:Invoke(...)
	end)

	if success then
		return result
	else
		warn("Failed to grab boundary value:", result)
		return nil
	end
end

return yoink
