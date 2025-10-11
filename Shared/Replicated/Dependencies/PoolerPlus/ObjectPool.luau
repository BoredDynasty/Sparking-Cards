--!strict
--!optimize 2
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Pooler+
-- riftkuro '25
local Analytics = require(script.Parent.Analytics)
local Constants = require(script.Parent.Constaints)
local Debug = require(script.Parent.Debug)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local Types = require(script.Parent.Types)
local Utils = require(script.Parent.Utils)
local Validation = require(script.Parent.Validation)
local ObjectPool = {}
ObjectPool.__index = ObjectPool
function ObjectPool.new<T>(
	name: string,
	createFn: Types.CreateFunction<T>,
	cleanupFn: Types.CleanupFunction<T>?,
	destroyFn: Types.DestroyFunction<T>?,
	config: Types.PoolConfig?
): Types.ObjectPool<T>
	config = config or {}
	local safeConfig: Types.PoolConfig = config :: Types.PoolConfig
	local self: Types.ObjectPoolImpl<T> = setmetatable({}, ObjectPool) :: any
	self._name = name
	self._available = {}
	self._inUse = {} :: { [T]: boolean }
	self._create = createFn
	self._cleanup = cleanupFn
	self._destroy = destroyFn
	self._config = safeConfig
	self._maxSize = safeConfig.maxSize or math.huge
	self._stats = {
		name = name,
		hits = 0,
		misses = 0,
		peakUsage = 0,
		totalCreated = 0,
		averageLifetime = 0,
		memoryUsage = 0,
	}
	self._objectBirthTimes = {} :: { [T]: number }
	self._lifetimeSamples = {}
	Analytics.initializePool(self)
	self.OnGet = SignalPlus() :: any
	self.OnReturn = SignalPlus() :: any
	self.OnCreate = SignalPlus() :: any
	self.OnOptimize = SignalPlus() :: any
	if safeConfig.instanceConfig then
		local instanceConfig: Types.InstanceConfig = safeConfig.instanceConfig
		if not cleanupFn then
			self._cleanup = function(object: T)
				if typeof(object) == "Instance" and instanceConfig.template then
					Utils.resetInstance(object :: Instance, instanceConfig.template)
					Utils.trackInstance(object :: Instance)
				end
				if instanceConfig.cleanupConnections and typeof(object) == "Instance" then
					Utils.cleanupConnections(object :: Instance)
				end
				if instanceConfig.safeParent and typeof(object) == "Instance" then
					Utils.safeParent(object :: Instance, instanceConfig.safeParent)
				end
			end
		end
	end
	if not destroyFn then
		self._destroy = function(object: T)
			if typeof(object) == "Instance" then
				(object :: Instance):Destroy()
			end
		end
	end
	if safeConfig.preloadCount and safeConfig.preloadCount > 0 then
		self:Preload(safeConfig.preloadCount)
	end
	return self
end
function ObjectPool:Get<T>(): T
	local self = self :: Types.ObjectPoolImpl<T>
	local obj: T
	local isNewObject = false
	if #self._available > 0 then
		obj = table.remove(self._available) :: T
		self._stats.hits += 1
	else
		if self:_getTotalSize() >= self._maxSize then
			if #self._available > 0 then
				obj = table.remove(self._available, 1) :: T
				self._stats.hits += 1
			else
				obj = self._create()
				isNewObject = true
			end
		else
			obj = self._create()
			isNewObject = true
		end
	end
	if isNewObject then
		self._stats.misses += 1
		self._stats.totalCreated += 1
		self._stats.memoryUsage += Utils.estimateMemoryUsage(obj)
		Analytics.trackCreation(self)
		self.OnCreate:Fire(obj)
	end
	self._inUse[obj] = true
	Analytics.recordBirthTime(self, obj)
	local currentUsage = self:_getInUseCount()
	Analytics.updatePeakUsage(self, currentUsage)
	Analytics.updateRates(self)
	self.OnGet:Fire(obj)
	return obj
end
function ObjectPool:GetSafe<T>(): (T?, Types.PoolError?)
	local self = self :: Types.ObjectPoolImpl<T>
	local success, result = pcall(function()
		return self:Get()
	end)
	if success then
		return result, nil
	else
		return nil, Utils.createPoolError(tostring(result), "GET_FAILED", self._name)
	end
end
function ObjectPool:GetWithPriority<T>(priority: Types.PoolPriority): T?
	local self = self :: Types.ObjectPoolImpl<T>
	local memoryPressure = Utils.getMemoryPressure()
	local priorityValue = Utils.getPriorityValue(priority)
	if memoryPressure == "critical" and priorityValue < 3 then
		return nil -- denies low priority requests during critical memory pressure
	end
	return self:Get()
end
function ObjectPool:GetBatch<T>(count: number): { T }
	local self = self :: Types.ObjectPoolImpl<T>
	local objects = {}
	for i = 1, count do
		table.insert(objects, self:Get())
	end
	return objects
end
function ObjectPool:Return<T>(object: T)
	local self = self :: Types.ObjectPoolImpl<T>
	if not self._inUse[object] then
		warn(
			("[Pooler] Attempted to return object to pool '%s' which is not in use or was already returned."):format(
				self._name
			),
			object
		)
		return
	end
	Analytics.updateLifetimeStats(self, object)
	Analytics.trackReturn(self)
	if self._cleanup then
		self._cleanup(object)
	end
	self._inUse[object] = nil
	if #self._available < self._maxSize then
		table.insert(self._available, object)
	else
		if self._destroy then
			self._destroy(object)
		end
		self._stats.memoryUsage -= Utils.estimateMemoryUsage(object)
	end
	Analytics.updateRates(self)
	self.OnReturn:Fire(object)
end
function ObjectPool:ReturnBatch<T>(objects: { T })
	local self = self :: Types.ObjectPoolImpl<T>
	for _, obj in ipairs(objects) do
		self:Return(obj)
	end
end
function ObjectPool:Preload(count: number)
	local self = self :: Types.ObjectPoolImpl<any>
	for _ = 1, count do
		if self:_getTotalSize() >= self._maxSize then
			break
		end
		local obj = self._create()
		if self._cleanup then
			self._cleanup(obj)
		end
		table.insert(self._available, obj)
		self._stats.totalCreated += 1
		self._stats.memoryUsage += Utils.estimateMemoryUsage(obj)
	end
end
function ObjectPool:AdaptivePreload()
	local self = self :: Types.ObjectPoolImpl<any>
	if not self._config.enableAdaptivePreload then
		return
	end
	local currentTime = tick()
	if currentTime - self._lastAdaptivePreload < 10 then
		return
	end
	self._lastAdaptivePreload = currentTime
	local avgUsage = self._stats.peakUsage * Constants.PEAK_USAGE_RATIO
	local currentAvailable = #self._available
	local targetPreload = math.max(0, math.floor(avgUsage) - currentAvailable)
	if targetPreload > 0 then
		self:Preload(targetPreload)
	end
end
function ObjectPool:ReturnAll()
	local self = self :: Types.ObjectPoolImpl<any>
	local inUseCopy = {}
	for obj in pairs(self._inUse) do
		table.insert(inUseCopy, obj)
	end
	for _, obj in ipairs(inUseCopy) do
		self:Return(obj)
	end
end
function ObjectPool:Clear()
	local self = self :: Types.ObjectPoolImpl<any>
	for obj in pairs(self._inUse) do
		if self._destroy then
			self._destroy(obj)
		end
	end
	for _, obj in ipairs(self._available) do
		if self._destroy then
			self._destroy(obj)
		end
	end
	self._inUse = {}
	self._available = {}
	self._stats.memoryUsage = 0
end
function ObjectPool:GetName(): string
	local self = self :: Types.ObjectPoolImpl<any>
	return self._name
end
function ObjectPool:GetStatus()
	local self = self :: Types.ObjectPoolImpl<any>
	local inUseCount = self:_getInUseCount()
	local availableCount = #self._available
	return { Available = availableCount, InUse = inUseCount, Total = availableCount + inUseCount }
end
function ObjectPool:GetStats(): Types.PoolStats
	local self = self :: Types.ObjectPoolImpl<any>
	return table.clone(self._stats)
end
function ObjectPool:GetEnhancedStats(): Types.EnhancedPoolStats
	local self = self :: Types.ObjectPoolImpl<any>
	return Analytics.calculateEnhancedStats(self)
end
function ObjectPool:GetActiveObjects(): { any }
	local self = self :: Types.ObjectPoolImpl<any>
	local activeObjects = {}
	for obj in pairs(self._inUse) do
		table.insert(activeObjects, obj)
	end
	return activeObjects
end
function ObjectPool:Optimize()
	local self = self :: Types.ObjectPoolImpl<any>
	local memoryPressure = Utils.getMemoryPressure()
	local targetSize = #self._available
	if memoryPressure == "critical" then
		targetSize = math.floor(#self._available * Constants.CRITICAL_MEMORY_RATIO)
	elseif memoryPressure == "moderate" then
		targetSize = math.floor(#self._available * Constants.MODERATE_MEMORY_RATIO)
	else
		local reasonableSize = math.max(Constants.MIN_REASONABLE_POOL_SIZE, self._stats.peakUsage)
		targetSize = math.min(#self._available, reasonableSize)
	end
	while #self._available > targetSize do
		local obj = table.remove(self._available)
		if self._destroy then
			self._destroy(obj)
		end
		self._stats.memoryUsage -= Utils.estimateMemoryUsage(obj)
	end
	self._optimizationCount += 1
	self._lastOptimized = tick()
	self.OnOptimize:Fire()
end
function ObjectPool:OptimizeWithGC()
	local self = self :: Types.ObjectPoolImpl<any>
	local memoryBefore = self._stats.memoryUsage
	self:Optimize()
	local memoryAfter = self._stats.memoryUsage
	if memoryBefore - memoryAfter > Constants.GC_OPTIMIZATION_THRESHOLD then
		Utils.smartGarbageCollection()
	end
end
function ObjectPool:SetMaxSize(maxSize: number)
	local self = self :: Types.ObjectPoolImpl<any>
	self._maxSize = maxSize
	while #self._available > maxSize do
		local obj = table.remove(self._available)
		if self._destroy then
			self._destroy(obj)
		end
		self._stats.memoryUsage -= Utils.estimateMemoryUsage(obj)
	end
end
function ObjectPool:Validate(): boolean
	local self = self :: Types.ObjectPoolImpl<any>
	return Validation.validatePool(self)
end
function ObjectPool:SerializeState(): string
	local self = self :: Types.ObjectPoolImpl<any>
	return Debug.serializePoolState(self)
end
function ObjectPool:_getTotalSize(): number
	local self = self :: Types.ObjectPoolImpl<any>
	return #self._available + self:_getInUseCount()
end
function ObjectPool:_getInUseCount(): number
	local self = self :: Types.ObjectPoolImpl<any>
	local count = 0
	for _ in pairs(self._inUse) do
		count += 1
	end
	return count
end
function ObjectPool:_updateRates()
	local self = self :: Types.ObjectPoolImpl<any>
	Analytics.updateRates(self)
end
return ObjectPool
