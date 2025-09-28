--!nonstrict

-- observer.luau

local SignalPlus = require("../Dependencies/SignalPlus")

--[[
	Observer class to handle state changes and notifications
]]
local Observer = {}
Observer.__index = Observer

export type Observer<T> = {
	_value: T,
	Changed: SignalPlus.Signal<(newValue: T, oldValue: T) -> ()>,
	Get: (self: Observer<T>) -> T,
	Set: (self: Observer<T>, value: T) -> (),
	Watch: (self: Observer<T>, callback: (newValue: T, oldValue: T) -> ()) -> SignalPlus.Connection,
	Insert: (self: Observer<T>, key: any?, value: any) -> (),
	Remove: (self: Observer<T>, key: number | any) -> (),
	Find: (self: Observer<T>, predicate: (value: any, key: any) -> boolean) -> (any?, any?),
	Calculate: (self: Observer<T>, fn: (current: T) -> T) -> (),
	Destroy: (self: Observer<T>) -> (),
}

--[[
    ```luau

	 local Observer = require(path.to.observer)
    -- Create a new observer with initial value
    local counter = Observer.new(0)
    ```
]]
function Observer.new<T>(initialValue: T): Observer<T>
	local self = setmetatable({
		_value = initialValue,
		Changed = SignalPlus(),
	}, Observer)

	return self
end

--[[
	```luau
	local none = observer.None

	-- An observer with no value.
]]

Observer.None = Observer.new(nil)

--[[
    ```luau

    -- Access the current value
    local currentValue = counter:Get()
    print("Current value:", currentValue)
    ```
]]
function Observer:Get<T>(): T
	return self._value
end

--[[
	```luau
	local observer = observer.None

	local expected = observer:Expect()
	-- expects a value from the observer.
	-- if no value, it throws an error.
]]
function Observer:Expect<T>(str: string): T
	return if self._value ~= nil then self.value else error(str or "Expected a value from observer.")
end

--[[
    ```luau
	 
    -- Set a new value
    counter:Set(5)
    print("New value set to: ", counter:Get())
    ```
]]
function Observer:Set<T>(newValue: T)
	if self._value == newValue then
		return
	end

	local oldValue = self._value
	self._value = newValue
	self.Changed:Fire(newValue, oldValue)
end

--[[
    ```luau

    -- Watch for changes
    local connection = counter:Watch(function(newValue, oldValue)
        print("Counter changed from", oldValue, "to", newValue)
    end)
    ```
]]
function Observer:Watch(callback: (newValue: any, oldValue: any) -> ())
	return self.Changed:Connect(callback)
end

--[[
	Insert a value into the internal value

	When using, the internal value should be a table.
]]
function Observer:Insert(key: any?, value: any)
	assert(type(self._value) == "table", "Cannot use :Insert, Observer value isn't a table.")
	if key then
		local oldValue = self._value

		self._value[key] = value

		self.Changed:Fire(self._value, oldValue)
	elseif not key then
		table.insert(self._value, value)
	end
end

--[[
	Remove a value from the internal table value

	When using, the internal value should be a table.
]]
function Observer:Remove(key: number | any)
	assert(type(self._value) == "table", "Cannot use :Remove, Observer value isn't a table.")
	local oldValue = self._value

	if type(key) == "number" then
		table.remove(self._value, key)
	else
		self._value[key] = nil
	end

	self.Changed:Fire(self._value, oldValue)
end

--[[
	Find a value in the internal table value using a predicate function

	Returns the first matching element, or nil if not found.

	```luau

	local object = Instance.new("Part")

	local obj = _observer:Find(function(dictionary)
		return dictionary.object == object
	end)
	```
]]
function Observer:Find(predicate: (value: any, key: any) -> boolean): (any?, any?)
	assert(type(self._value) == "table", "Cannot use :Find, Observer value isn't a table.")
	for key, value in pairs(self._value) do
		if predicate(value, key) then
			return value, key
		end
	end
	return nil
end

--[[
	Calculate a new value based on the current value and a function

	```luau
	local observer = Observer.new(10)
	observer:Calculate(function(current)
		return current * 2
	end)
	-- observer:Get() is now 20
	```
]]
function Observer:Calculate<T>(fn: (current: T) -> T)
	local newValue = fn(self:Get())
	self:Set(newValue)
end

function Observer:Destroy()
	self.Changed:Destroy()
	setmetatable(self, nil)
end

return Observer
