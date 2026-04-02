--!strict

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
	_connections: { SignalPlus.Connection }?,
	Get: (self: Observer<T>) -> T,
	Set: (self: Observer<T>, value: T) -> (),
	Watch: (self: Observer<T>, callback: (newValue: T, oldValue: T) -> ()) -> SignalPlus.Connection,
	Map: (self: Observer<T>, fn: (current: T) -> T) -> (),
	Destroy: (self: Observer<T>) -> (),
	__concat: (self: Observer<T>, ...Observer<T>) -> string,
	__add: (self: Observer<T>, ...Observer<T>) -> number,
	__sub: (self: Observer<T>, ...Observer<T>) -> number,
	__mul: (self: Observer<T>, ...Observer<T>) -> number,
	__div: (self: Observer<T>, ...Observer<T>) -> number,
	__idiv: (self: Observer<T>, ...Observer<T>) -> number,
	__mod: (self: Observer<T>, ...Observer<T>) -> number,
	__pow: (self: Observer<T>, ...Observer<T>) -> number,
	__tostring: (self: Observer<T>) -> string,
}

export type observer_mt<T> = setmetatable<Observer<T>, typeof(Observer)>

--[[
    ```luau

	 local Observer = require(path.to.observer)
    -- Create a new observer with initial value
    local counter = Observer.new(0)
    ```
]]
function Observer.new<T>(initialValue: T): observer_mt<T>
	return setmetatable({
		_value = initialValue,
		Changed = SignalPlus() :: SignalPlus.Signal<(newValue: T, oldValue: T) -> ()>,
		_connections = {} :: { SignalPlus.Connection },
	}, Observer)
end

--[[
	```luau

	local scope = observer.scope(1, 67, "baller", "roblox", Axes.new(Enum.NormalId.Top))

	-- creates multiple observers from a tuple/variadic

]]
function Observer.scope<T...>(...: T...)
	local tuple = { ... } :: { any }
	local r = {} :: { observer_mt<any> }

	for i, v in ipairs(tuple) do
		table.insert(r, Observer.new(v))
	end

	return table.unpack(r)
end

--[[
	```luau
	local none = observer.None

	-- An observer with no value.

	none:Expect("nil value")
]]

Observer.None =
	table.freeze(setmetatable({ _value = nil, Changed = SignalPlus() }, Observer)) :: observer_mt<any?>

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
	return assert(self:Get(), str or "Expected a value from observer.")
	--return if self:Get() ~= nil then self:Get() else error(str or "Expected a value from observer.")
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

	local old_value = self._value
	self._value = newValue

	self.Changed:Fire(newValue, old_value)
end

--[[
    ```luau

    -- Watch for changes
    local connection = counter:Watch(function(newValue, oldValue)
        print("Counter changed from", oldValue, "to", newValue)
    end)
    ```
]]
function Observer:Watch<T>(callback: (newValue: T, oldValue: T) -> ()): SignalPlus.Connection
	if not self._connections then
		self._connections = {}
	end

	local conn = self.Changed:Connect(callback)

	table.insert(self._connections, conn)

	return conn
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
function Observer:Map<T>(fn: (current: T) -> T)
	local newValue = fn(self:Get())

	self:Set(newValue)
end

function Observer:__concat<T>(...: Observer<T>): T
	local scope = { ... }

	local str = ""

	for i, v in scope do
		str ..= v:Get()
	end

	return str
end

function Observer:__add(...: Observer<number>)
	local scope = { ... }

	local sum = 0

	for i, v in scope do
		sum += v:Get()
	end

	return sum
end

function Observer:__sub(...: Observer<number>)
	local scope = { ... }

	local difference = 0

	for i, v in scope do
		difference -= v:Get()
	end

	return difference
end

function Observer:__mul(...: Observer<number>)
	local scope = { ... }

	local product = 0

	for i, v in scope do
		product *= v:Get()
	end

	return product
end

function Observer:__div(...: Observer<number>)
	local scope = { ... }

	local quotient = 0

	for i, v in scope do
		quotient /= v:Get()
	end

	return quotient
end

function Observer:__idiv(...: Observer<number>)
	local scope = { ... }

	local quotient = 0

	for i, v in scope do
		quotient //= v:Get()
	end

	return math.floor(quotient)
end

function Observer:__mod(...: Observer<number>)
	local scope = { ... }

	local remainder = 0

	for i, v in scope do
		remainder %= v:Get()
	end

	return remainder
end

function Observer:__pow(...: Observer<number>)
	local scope = { ... }

	local power = 0

	for i, v in scope do
		power = math.pow(power, v:Get())
	end

	return power
end

function Observer:__tostring()
	return tostring(self._value)
end

function Observer:__call(...: any): ...unknown?
	if type(self._value) == "function" then
		return self._value(...)
	else
		return nil
	end
end

function Observer:Destroy()
	self.Changed:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

return Observer
