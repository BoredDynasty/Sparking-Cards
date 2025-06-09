--!nonstrict

-- observer.luau

local SignalPlus = require(script.Parent.SignalPlus)

--[[
	Observer class to handle state changes and notifications
]]
local Observer = {}
Observer.__index = Observer

export type Observer<T> = {
	Value: T,
	Changed: SignalPlus.Signal<(newValue: T, oldValue: T) -> ()>,
	Get: (self: Observer<T>) -> T,
	Set: (self: Observer<T>, value: T) -> (),
	Watch: (self: Observer<T>, callback: (newValue: T, oldValue: T) -> ()) -> SignalPlus.Connection,
	Destroy: (self: Observer<T>) -> (),
}

--[[
    local Observer = require(path.to.observer)

    
    ```luau
    -- Create a new observer with initial value
    local counter = Observer.new(0)
    ```
]]
function Observer.new<T>(initialValue: T): Observer<T>
	local self = setmetatable({
		_value = initialValue,
	}, Observer)

	return self
end

--[[
    ```luau
    -- Access the current value
    local currentValue = counter:Get()
    print("Current value:", currentValue)
    ```
]]
function Observer:Get(): any
	return self._value
end

--[[
    ```luau
    -- Set a new value
    counter:Set(5)
    print("New value set to: ", counter:Get())
    ```
]]
function Observer:Set(newValue: any)
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

function Observer:Destroy()
	self.Changed:Destroy()
	setmetatable(self, nil)
end

return Observer
