--!strict
--!optimize 2
-- Pooler+
-- riftkuro '25
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")

local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local Utils = {}
local PoolStorage = workspace:FindFirstChild("PoolStorage") or Instance.new("Folder")
PoolStorage.Name = "PoolStorage"
PoolStorage.Parent = workspace
local UIPoolStorage

if RunService:IsServer() then
	UIPoolStorage = StarterGui:FindFirstChild("UIPoolStorage") or Instance.new("ScreenGui")
	UIPoolStorage.Name = "UIPoolStorage"
	UIPoolStorage.Enabled = false
	UIPoolStorage.Parent = StarterGui
else
	UIPoolStorage = playerMarshaller.get().PlayerGui:FindFirstChild("UIPoolStorage")
		or Instance.new("ScreenGui")
	UIPoolStorage.Name = "UIPoolStorage"
	UIPoolStorage.Enabled = false
	UIPoolStorage.Parent = playerMarshaller.get().PlayerGui
end
local propertySnapshots: { [Instance]: { [string]: any } } = {}
local propertySets: { [string]: { [string]: boolean } } = {}
local weakInstanceTracker = setmetatable({}, { __mode = "k" })
function Utils.createPropertySet(properties: { string }): { [string]: boolean }
	local set = {}
	for _, prop in ipairs(properties) do
		set[prop] = true
	end
	return set
end
function Utils.snapshotInstanceOptimized(template: Instance): { [string]: any }
	if propertySnapshots[template] then
		return propertySnapshots[template]
	end
	local snapshot = {}
	local className = template.ClassName
	local cacheKey = className
	if not propertySets[cacheKey] then
		local propertySet = {} :: { [string]: boolean }
		for _, prop in ipairs(Constants.BASE_PROPERTIES) do
			propertySet[prop] = true
		end
		for class, props in pairs(Constants.DEFAULT_RESET_PROPERTIES) do
			if template:IsA(class) then
				for _, prop in ipairs(props) do
					propertySet[prop] = true
				end
			end
		end
		propertySets[cacheKey] = propertySet
	end
	for propertyName in pairs(propertySets[cacheKey]) do
		local success, value = pcall(function()
			return (template :: any)[propertyName]
		end)
		if success then
			snapshot[propertyName] = value
		end
	end
	propertySnapshots[template] = snapshot
	return snapshot
end
function Utils.trackInstance(instance: Instance)
	weakInstanceTracker[instance] = true
	local connection
	connection = instance.AncestryChanged:Connect(function()
		if not instance.Parent then
			propertySnapshots[instance] = nil
			weakInstanceTracker[instance] = nil
			connection:Disconnect()
		end
	end)
end
function Utils.resetInstance(instance: Instance, template: Instance)
	local snapshot = Utils.snapshotInstanceOptimized(template)
	for propertyName, value in pairs(snapshot) do
		if propertyName ~= "Parent" then
			local success = pcall(function()
				(instance :: any)[propertyName] = value
			end)
			if not success then
				warn(("[Pooler] Failed to reset property '%s' on %s"):format(propertyName, instance.Name))
			end
		end
	end
end
function Utils.cleanupConnections(instance: Instance)
	for _, child in ipairs(instance:GetDescendants()) do
		if child:IsA("Script") or child:IsA("LocalScript") then
			(child :: any).Enabled = false
			task.wait();
			(child :: any).Enabled = true
		end
	end
	if typeof(instance) == "table" and instance.cleanup then
		instance:cleanup()
	end
end
function Utils.safeParent(instance: Instance, newParent: Instance?)
	if not newParent then
		if instance:IsA("GuiObject") then
			newParent = UIPoolStorage
		else
			newParent = PoolStorage
		end
	end
	instance.Parent = newParent
end
function Utils.getMemoryPressure(): Types.MemoryPressure
	local totalMemory = Stats:GetTotalMemoryUsageMb()
	print(("DEBUG: Current memory usage: %.1f MB"):format(totalMemory))
	if totalMemory > Constants.MEMORY_PRESSURE_CRITICAL then
		return "critical"
	elseif totalMemory > Constants.MEMORY_PRESSURE_MODERATE then
		return "moderate"
	else
		return "none"
	end
end
function Utils.estimateMemoryUsage(object: any): number
	if typeof(object) == "Instance" then
		if object:IsA("Part") then
			return Constants.MEMORY_ESTIMATES.Part
		elseif object:IsA("GuiObject") then
			return Constants.MEMORY_ESTIMATES.GuiObject
		else
			return Constants.MEMORY_ESTIMATES.Instance
		end
	elseif typeof(object) == "table" then
		return Constants.MEMORY_ESTIMATES.Table
	else
		return Constants.MEMORY_ESTIMATES.Other
	end
end
function Utils.getPriorityValue(priority: Types.PoolPriority): number
	return Constants.PRIORITY_VALUES[priority] or 2
end
function Utils.smartGarbageCollection()
	local memoryBefore = Stats:GetTotalMemoryUsageMb()
	if memoryBefore > Constants.GC_MEMORY_THRESHOLD then
		local gcBefore = gcinfo()
		gcinfo()
		local gcAfter = gcinfo()
		local memoryAfter = Stats:GetTotalMemoryUsageMb()
		local memoryFreed = memoryBefore - memoryAfter
		if memoryFreed > 50 then
			print(("[Pooler] GC freed %.1f MB"):format(memoryFreed))
		end
	end
end
local PoolError = {}
PoolError.__index = PoolError
function Utils.createPoolError(message: string, errorType: string, poolName: string?): Types.PoolError
	return setmetatable({
		message = message,
		errorType = errorType,
		poolName = poolName,
		timestamp = tick(),
	}, PoolError) :: any
end
function Utils.getPoolStorage(): Folder
	return PoolStorage
end
function Utils.getUIPoolStorage(): ScreenGui
	return UIPoolStorage
end
return Utils
