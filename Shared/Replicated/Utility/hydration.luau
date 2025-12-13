--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local future = require(ReplicatedStorage.Packages.future)
local observer = require(script.Parent.observer)

-- hydration.luau

local hydration = {}

type connections = { SignalPlus.Connection | { ["__destruct"]: () -> () } }

local function isObserver(value)
	if type(value) ~= "table" then
		return false
	end

	if type(value.Get) ~= "function" then
		return false
	end

	local ok, hasConnect = future
		.Try(function()
			return type(value.Changed) == "table" and type(value.Changed.Connect) == "function"
		end)
		:Unwrap()

	return ok and hasConnect
end

local function safeSetProperty<a, b>(instance: { [a]: b }, key: a, value: b)
	return future.new(function(...)
		instance[key] = value
	end)
end

--[[
   ```luau

   -- usage

   local hydrate = require(path.to.hydration) -- callable module
   local observer = require(path.to.observer)

   local message = observer.new("Loading...")

   hydrate(PlayerGui.LoadingText) {
       Text = message
   }

   print(PlayerGui.LoadingText.Text) --> Loading...

   message:Set("All done!")

   print(PlayerGui.LoadingText.Text) --> All done!

   ```

   @param instance - The instance that should be saturated

   @return function - The property table should be inputted into the function parameters.


   ### Design notes & compatibility

   - #### Detection of observer: 
   checks for Get method and a Changed signal with a Connect function.
   
   - #### Property assignment:
   Tries direct property assignment `instance[key] = value` inside promise to avoid errors when property does not exist or is read-only.
   If direct set fails and the instance supports `SetAttribute`, falls back to `SetAttribute`.

   - #### Nested tables:
   If a prop value is a table and `instance[key]` is a table/child instance, `hydrate` is called recursively to apply nested props.
   The nested destructor is stored and run during cleanup.

   - #### Cleanup:
   Keeps track of connections (Connection objects with `Disconnect`/`Destroy` or wrapper tables with `__destruct`).
   The destructor returned by `hydrate(instance)(props)` will attempt to safely call `:Disconnect`, `:Destroy`, or `__destruct` on each tracked connection.
]]
function hydration.hydrate<b, c, a>(instance: { [b]: c } & { [string]: a })
	assert(instance ~= nil, "hydrate: instance cannot be nil")

	local connections = {} :: connections

	local function bind(key: string, value: observer.Observer<any?> | any)
		-- Observer value: set initial value and connect Changed
		if isObserver(value) then
			local ok, current = future
				.Try(function()
					return value:Get()
				end)
				:Unwrap()

			if ok then
				safeSetProperty(instance, key, current)
			end

			local okConn, conn = future
				.Try(function()
					return value.Changed:Connect(
							function(newValue: a & c, oldValue: unknown)
								safeSetProperty(instance, key, newValue)
							end
						) :: SignalPlus.Connection
				end)
				:Unwrap()

			if okConn and conn then
				table.insert(connections, conn)
			end

			return
		end

		-- If value is a table and the instance has a child/property of that name which is also an Instance/table,
		-- attempt recursive hydration so nested tables can be applied to child objects.
		if type(value) == "table" then
			local okChild, child = future
				.Try(function()
					return instance[key]
				end)
				:Unwrap()

			if okChild and type(child) == "table" then
				-- Use hydration recursively on the child.
				local destructor = hydration.hydrate(child)(value)
				if type(destructor) == "function" then
					table.insert(connections, { __destruct = destructor })
				end
				return
			end
		end

		-- Plain value: set once
		safeSetProperty(instance, key, value)
	end

	-- returned function accepts a props table
	return function(props: { [string]: any | observer.Observer<any?> })
		if type(props) ~= "table" then
			error("hydrate: expected a props table")
		end

		for key, value in pairs(props) do
			bind(key, value)
		end

		-- return a destructor so callers can clean up observer connections
		return function()
			for i, conn in ipairs(connections :: connections) do
				-- Support Connection objects with Disconnect or Destroy
				future.new(function()
					if typeof(conn.Disconnect) == "function" then
						conn:Disconnect()
					elseif type(conn.Destroy) == "function" then
						conn:Destroy()
					elseif type(conn) == "table" and type(conn.__destruct) == "function" then
						conn.__destruct()
					end
				end)
			end

			table.clear(connections)
		end
	end
end

setmetatable(hydration, {
	--[[
   ```luau

   -- usage

   local hydrate = require(path.to.hydration) -- callable module
   local observer = require(path.to.observer)

   local message = observer.new("Loading...")

   hydrate(PlayerGui.LoadingText) {
       Text = message
   }

   print(PlayerGui.LoadingText.Text) --> Loading...

   message:Set("All done!")

   print(PlayerGui.LoadingText.Text) --> All done!

   ```

   @param instance - The instance that should be saturated

   @return function - The property table should be inputted into the function parameters.


   ### Design notes & compatibility

   - #### Detection of observer: 
   checks for Get method and a Changed signal with a Connect function.
   
   - #### Property assignment:
   Tries direct property assignment `instance[key] = value` inside promise to avoid errors when property does not exist or is read-only.
   If direct set fails and the instance supports `SetAttribute`, falls back to `SetAttribute`.

   - #### Nested tables:
   If a prop value is a table and `instance[key]` is a table/child instance, `hydrate` is called recursively to apply nested props.
   The nested destructor is stored and run during cleanup.

   - #### Cleanup:
   Keeps track of connections (Connection objects with `Disconnect`/`Destroy` or wrapper tables with `__destruct`).
   The destructor returned by `hydrate(instance)(props)` will attempt to safely call `:Disconnect`, `:Destroy`, or `__destruct` on each tracked connection.
]]
	__call = function(_, ...: any)
		return hydration.hydrate(...)
	end,
})

return hydration
