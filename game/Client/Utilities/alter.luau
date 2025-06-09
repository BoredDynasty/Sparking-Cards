--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dictionary = require(ReplicatedStorage.Utility.dictionary)

type instance = Instance

return function(
	instances: { Instance },
	modifications: { [string]: any } | (Instance) -> (),
	exceptions: { Instance }?
)
	-- Validate input parameters
	assert(typeof(instances) == "table", "Expected table of instances as first argument")
	assert(
		typeof(modifications) == "table" or typeof(modifications) == "function",
		"Expected table of properties or function as second argument"
	)

	-- Convert exceptions table to set for O(1) lookup
	local exceptionSet = {}
	if exceptions then
		for _, instance in pairs(exceptions) do
			exceptionSet[instance] = true
		end
	end

	local potentialErrors: { string? } = { nil }
	-- Process each instance
	for _, instance in instances do
		-- Skip if instance is in exceptions
		if exceptionSet[instance] then
			continue
		end

		-- Handle function modification
		if typeof(modifications) == "function" then
			task.spawn(modifications, instance) -- Wrap in task.spawn to prevent yielding
			continue
		end

		-- Handle property modifications
		for property, value in modifications do
			-- Use pcall to safely attempt property changes
			assert(instance:FindFirstChild(property), property .. " is an instance!")
			local success, result = pcall(function()
				instance[property] = value
			end)
			if not success then
				table.insert(potentialErrors, result)
			end
		end
	end

	if not dictionary.empty(potentialErrors) then
		for _, err in potentialErrors do
			print(err)
		end
	end
end
