--!strict
local SignalPlus = require(script.Parent.SignalPlus)

--[[
    Given a tuple of Luau `signals`, to wait only for the first of them to fire without leaking memory
    
    ```luau
    waitForFirst(humanoid.Died, character.AncestryChanged)
    ```
]]

return function(...): ...any
	local shunt = SignalPlus() :: SignalPlus.Signal<...any>
	local slots: { typeof(...) } = { ... }

	local function fire(...)
		for i = 1, #slots do
			slots[i]:Disconnect()
		end
		return shunt:Fire(...)
	end

	for i = 1, #slots do
		slots[i] = slots[i]:Connect(fire)
	end

	return shunt:Wait()
end
