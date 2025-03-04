--!nocheck
local Maid = {}

-- // A custom Maid module from @Herobrinekd1

-- // Exported
export type Dictionary = { [any]: any }
-- // End

-- // High priority funcs
local function ClearTask(Task: any)
	local Type = typeof(Task)

	if Type == "RBXScriptConnection" then
		Task:Disconnect()
	elseif Type == "function" then
		Task()
		Task = nil
	elseif Type == "Instance" then
		Task:Destroy()
	end
end
-- // End

-- // Metamethods
function Maid:__index(Value)
	return Maid[Value] or self._Tasks[Value]
end

function Maid:__newindex(Key, Value)
	if self._Tasks[Key] then
		ClearTask(self._Tasks[Key])
	end

	self._Tasks[Key] = Value
end
-- // End

-- // Low priority funcs
local function Count(T: Dictionary)
	local Num = 1

	for _, _ in T do
		Num = Num + 1
	end
	return Num
end
-- // End

-- // Methods
function Maid.new()
	return setmetatable({ _Tasks = {} }, Maid)
end

function Maid:GiveTask(Task: any)
	local Index = Count(self._Tasks)

	self._Tasks[Index] = Task
	return Index
end

function Maid:ClearTask(Key: string)
	local Task = self._Tasks[Key]

	if Task then
		ClearTask(Task)
	end
end

function Maid:ClearTasks()
	for _, Task in self._Tasks do
		ClearTask(Task)
	end
end

function Maid:Destroy()
	self:ClearTasks()
	self._Tasks = nil
end
-- // End

return Maid
