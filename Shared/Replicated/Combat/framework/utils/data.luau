--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local promise = require(ReplicatedStorage.Packages.promise)

-- data.luau
-- for managing player states
-- and attributes
-- and allat

local data_module = {
	arbitrary = {},
}

function data_module:Insert(value: any, key: any?)
	return promise.new(function()
		if data_module.arbitrary[key] then
			warn("Overwriting existing key in data_module: " .. tostring(key))
		end

		if key then
			data_module.arbitrary[key] = value
		else
			data_module.arbitrary[#data_module.arbitrary + 1] = value
		end
	end)
end

function data_module:Remove(key: any)
	return promise.new(function()
		data_module.arbitrary[key] = nil
	end)
end

function data_module:Fetch(key: any)
	return promise.new(function(resolve: (any) -> (), reject: (string) -> ())
		if data_module.arbitrary[key] then
			resolve(data_module.arbitrary[key])
		else
			reject("No value found for key: " .. tostring(key))
		end
	end)
end

function data_module:Raw()
	return data_module.arbitrary
end

return data_module
