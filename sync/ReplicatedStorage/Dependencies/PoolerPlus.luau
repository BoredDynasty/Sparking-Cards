--!strict
--!optimize 2
--[[
-- Pooler+ v1.4 by riftkuro (2025!!!!!!!)
=====================================================
A high-performance object pooling library that dramatically reduces memory allocation
overhead and improves game performance through intelligent object reuse and management.
FEATURES:
============
- High-performance object pooling with 95%+ hit rates (many times staying at 100% during benchmarks)
- Analytics and performance monitoring
- Automatic memory pressure management and optimization
- Smart garbage collection integration
- Real-time validation and health checking
- Batch operations for bulk object management
- Priority-based object allocation
- Adaptive preloading based on usage patterns
- Comprehensive debugging and export tools
- Fully type checked an errorless if handeled properly
QUICK START:
============
local PoolerPlus = require(path.to.PoolerPlus)
-- Create a pool
local bulletPool = PoolerPlus:CreatePool("Bullets", function()
	return workspace.BulletTemplate:Clone()
end)
-- Use the pool
local bullet = bulletPool:Get()     -- Get object from pool
-- ... use the bullet ...
bulletPool:Return(bullet)           -- Return to pool for reuse
CORE METHODS:
=============
POOLER MANAGER:
- CreatePool(name, createFn, cleanupFn?, destroyFn?, config?) -> ObjectPool
- GetPool(name) -> ObjectPool?
- Get(poolName) -> any?
- GetWithPriority(poolName, priority) -> any?
- Return(poolName, object)
- GetMemoryPressure() -> "none" | "moderate" | "critical"
- OptimizeAllPools()
- OptimizeAllPoolsWithGC()
OBJECT POOL:
=====================
- Get() -> any                      -- Get object from pool
- GetSafe() -> (any?, PoolError?)   -- Safe get with error handling
- GetWithPriority(priority) -> any? -- Priority-based allocation
- GetBatch(count) -> {any}          -- Get multiple objects
- Return(object)                    -- Return object to pool
- ReturnBatch(objects)              -- Return multiple objects
- ReturnAll()                       -- Return all in-use objects
- Preload(count)                    -- Pre-create objects
- AdaptivePreload()                 -- Smart preloading
- Clear()                           -- Destroy all objects
- Optimize()                        -- Memory optimization
- OptimizeWithGC()                  -- Optimization with GC hints
ANALYTICS & MONITORING:
=======================
- GetStats() -> PoolStats           -- Basic statistics
- GetEnhancedStats() -> EnhancedStats -- Detailed analytics
- GetStatus() -> {Available, InUse, Total}
- GetActiveObjects() -> {any}       -- Currently in-use objects
- Validate() -> boolean             -- Health check
- SerializeState() -> string        -- Export state as JSON
GLOBAL UTILITIES:
=================
- GetGlobalStats() -> {[string]: PoolStats}
- GetGlobalEnhancedStats() -> {[string]: EnhancedStats}
- GetSystemStatus() -> SystemStatus
- ValidateAllPools() -> {[string]: boolean}
- HealthCheck() -> HealthReport
- AutoRepairAllPools() -> {[string]: {string}}
- EmergencyCleanup()               -- Force aggressive cleanup
DEBUG & PERFORMANCE:
====================
- DebugPrintAllPools()             -- Comprehensive debug output
- GetPerformanceReport() -> string  -- Detailed performance analysis
- ExportPoolStates() -> string     -- Full system export
CONFIGURATION:
==============
PoolConfig = {
   maxSize?: number,              -- Maximum objects in pool (default: unlimited)
   preloadCount?: number,         -- Objects to create initially (default: 0)
   enableAnalytics?: boolean,     -- Track detailed statistics (default: false)
   enableAdaptivePreload?: boolean, -- Auto-adjust pool size (default: false)
   enableValidation?: boolean,    -- Health monitoring (default: false)
   instanceConfig?: {             -- For Roblox Instance objects:
       template?: Instance,       -- Template for property reset
       resetProperties?: {string}, -- Specific properties to reset
       cleanupConnections?: boolean, -- Auto-cleanup script connections
       safeParent?: Instance      -- Safe storage location
   }
}
PERFORMANCE BENEFITS:
=====================
- 10-50x reduction in object creation overhead
- 90%+ object reuse rates in typical scenarios
- Automatic memory pressure management
- Reduced garbage collection pressure
- Real-time performance monitoring
- Smart optimization based on usage patterns
TYPICAL PERFORMANCE METRICS:
=====================
- Hit Rate: 90-99% (objects reused vs newly created)
- Memory Efficiency: 5-20x less allocation than non-pooled
- Creation Rate: Objects created per second
- Return Rate: Objects returned per second
- Average Lifetime: How long objects stay in use
PRIORITY LEVELS:
================
- "low": Denied during critical memory pressure
- "normal": Standard allocation (default)
- "high": Preferred allocation
- "critical": Always allocated when possible
MEMORY PRESSURE HANDLING:
=========================
- "none": Normal operation
- "moderate": Reduced pool sizes, optimization hints
- "critical": Aggressive cleanup, priority-only allocation
BEST PRACTICES:
===============
1. Enable analytics for production monitoring
2. Set reasonable maxSize based on peak usage
3. Use preloadCount for frequently used objects
4. Implement cleanup functions for proper object reset
5. Monitor hit rates - aim for 90%+
6. Use priority allocation for critical systems
7. Enable validation in development
8. Regular health checks in production
roblox profile: https://www.roblox.com/users/122470010/profile
note: this script includes json debugging & HTTPService located in the "Debug" module
consider donating if you found this useful!!
]]
--// Services
local RunService = game:GetService("RunService")
--// Modules
local Analytics = require(script.Analytics)
local Constants = require(script.Constants)
local Debug = require(script.Debug)
local ObjectPool = require(script.ObjectPool)
local Types = require(script.Types)
local Utils = require(script.Utils)
local Validation = require(script.Validation)
--================================================================================--
--||                                POOLER MANAGER                              ||--
--================================================================================--
local Pooler = {} :: Types.Pooler
local pools: { [string]: Types.ObjectPool<any> } = {}
local lastOptimizeTime = 0
local lastAdaptivePreloadTime = 0
local lastValidationTime = 0
local function autoOptimize()
	local currentTime = tick()
	if currentTime - lastOptimizeTime >= Constants.OPTIMIZE_INTERVAL then
		Pooler:OptimizeAllPools()
		lastOptimizeTime = currentTime
	end
	if currentTime - lastAdaptivePreloadTime >= Constants.ADAPTIVE_PRELOAD_INTERVAL then
		for _, pool in pairs(pools) do
			local poolImpl = pool :: Types.ObjectPoolImpl<any>
			if poolImpl._config.enableAdaptivePreload then
				pool:AdaptivePreload()
			end
		end
		lastAdaptivePreloadTime = currentTime
	end
	if currentTime - lastValidationTime >= Constants.VALIDATION_INTERVAL then
		for _, pool in pairs(pools) do
			local poolImpl = pool :: Types.ObjectPoolImpl<any>
			if poolImpl._config.enableValidation then
				pool:Validate()
			end
		end
		lastValidationTime = currentTime
	end
end
RunService.Heartbeat:Connect(autoOptimize)
--================================================================================--
--||                              POOLER METHODS                                ||--
--================================================================================--
function Pooler:CreatePool<T>(
	name: string,
	createFn: Types.CreateFunction<T>,
	cleanupFn: Types.CleanupFunction<T>?,
	destroyFn: Types.DestroyFunction<T>?,
	config: Types.PoolConfig?
): Types.ObjectPool<T>
	if pools[name] then
		warn(("[Pooler] A pool with the name '%s' already exists. Returning existing pool."):format(name))
		return pools[name] :: Types.ObjectPool<T>
	end
	local pool = ObjectPool.new(name, createFn, cleanupFn, destroyFn, config)
	pools[name] = pool
	return pool
end
function Pooler:GetPool<T>(name: string): Types.ObjectPool<T>?
	return pools[name]
end
function Pooler:Get<T>(poolName: string): T?
	local pool = pools[poolName]
	if pool then
		return pool:Get()
	else
		warn(("[Pooler] Cannot Get(): Pool '%s' does not exist."):format(poolName))
		return nil
	end
end
function Pooler:GetWithPriority<T>(poolName: string, priority: Types.PoolPriority): T?
	local pool = pools[poolName]
	if pool then
		return pool:GetWithPriority(priority)
	else
		warn(("[Pooler] Cannot GetWithPriority(): Pool '%s' does not exist."):format(poolName))
		return nil
	end
end
function Pooler:Return<T>(poolName: string, object: T)
	local pool = pools[poolName]
	if pool then
		pool:Return(object)
	else
		warn(("[Pooler] Cannot Return(): Pool '%s' does not exist."):format(poolName))
		if typeof(object) == "Instance" and object:IsA("Instance") then
			object:Destroy()
		end
	end
end
function Pooler:GetMemoryPressure(): Types.MemoryPressure
	return Utils.getMemoryPressure()
end
function Pooler:OptimizeAllPools()
	for _, pool in pairs(pools) do
		pool:Optimize()
	end
end
function Pooler:OptimizeAllPoolsWithGC()
	for _, pool in pairs(pools) do
		pool:OptimizeWithGC()
	end
end
function Pooler:GetGlobalStats(): { [string]: Types.PoolStats }
	local stats = {}
	for name, pool in pairs(pools) do
		stats[name] = pool:GetStats()
	end
	return stats
end
function Pooler:GetGlobalEnhancedStats(): { [string]: Types.EnhancedPoolStats }
	local stats = {}
	for name, pool in pairs(pools) do
		stats[name] = pool:GetEnhancedStats()
	end
	return stats
end
function Pooler:ValidateAllPools(): { [string]: boolean }
	local results = {}
	for name, pool in pairs(pools) do
		results[name] = pool:Validate()
	end
	return results
end
--================================================================================--
--||                              DEBUGGING UTILITIES                           ||--
--================================================================================--
function Pooler:DebugPrintAllPools()
	Debug.printAllPools(pools)
end
function Pooler:GetPerformanceReport(): string
	return Debug.getPerformanceReport(pools)
end
function Pooler:ExportPoolStates(): string
	return Debug.exportPoolStates(pools)
end
--================================================================================--
--||                              ADDITIONAL UTILITIES                          ||--
--================================================================================--
function Pooler:GetSystemStatus(): {
	memoryPressure: Types.MemoryPressure,
	totalPools: number,
	totalObjectsInUse: number,
	totalObjectsAvailable: number,
	totalMemoryUsage: number,
	globalHitRate: number,
	poolsWithIssues: { string },
}
	local totalInUse = 0
	local totalAvailable = 0
	local totalMemory = 0
	local poolsWithIssues = {}
	for name, pool in pairs(pools) do
		local status = pool:GetStatus()
		totalInUse += status.InUse
		totalAvailable += status.Available
		totalMemory += pool:GetStats().memoryUsage
		if not pool:Validate() then
			table.insert(poolsWithIssues, name)
		end
	end
	local poolCount = 0
	for _ in pairs(pools) do
		poolCount += 1
	end
	return {
		memoryPressure = Utils.getMemoryPressure(),
		totalPools = poolCount,
		totalObjectsInUse = totalInUse,
		totalObjectsAvailable = totalAvailable,
		totalMemoryUsage = totalMemory,
		globalHitRate = Analytics.calculateGlobalHitRate(pools),
		poolsWithIssues = poolsWithIssues,
	}
end
function Pooler:BatchGet(requests: { { poolName: string, count: number } }): { [string]: { any } }
	local results = {}
	for _, request in ipairs(requests) do
		local pool = pools[request.poolName]
		if pool then
			results[request.poolName] = pool:GetBatch(request.count)
		else
			warn(("[Pooler] BatchGet: Pool '%s' does not exist"):format(request.poolName))
			results[request.poolName] = {}
		end
	end
	return results
end
function Pooler:EmergencyCleanup()
	warn("[Pooler] Emergency cleanup initiated!")
	for _, pool in pairs(pools) do
		local originalMaxSize = pool._maxSize
		pool:SetMaxSize(math.max(1, math.floor(pool:GetStatus().InUse * 1.2)))
		pool:OptimizeWithGC()
		pool:SetMaxSize(originalMaxSize)
	end
	Utils.smartGarbageCollection()
	gcinfo()
end
function Pooler:HealthCheck(): {
	overallHealth: boolean,
	issues: { string },
	warnings: { string },
	recommendations: { string },
}
	local allIssues = {}
	local allWarnings = {}
	local allRecommendations = {}
	for name, pool in pairs(pools) do
		local poolImpl = pool :: Types.ObjectPoolImpl<any>
		local health = Validation.healthCheck(poolImpl)
		for _, issue in ipairs(health.issues) do
			table.insert(allIssues, string.format("[%s] %s", name, issue))
		end
		for _, warning in ipairs(health.warnings) do
			table.insert(allWarnings, string.format("[%s] %s", name, warning))
		end
		local recommendations = Debug.generateRecommendations(poolImpl)
		for _, rec in ipairs(recommendations) do
			table.insert(allRecommendations, string.format("[%s] %s", name, rec))
		end
	end
	local memoryPressure = Utils.getMemoryPressure()
	if memoryPressure == "critical" then
		table.insert(allIssues, "System memory pressure is critical")
	elseif memoryPressure == "moderate" then
		table.insert(allWarnings, "System memory pressure is moderate")
	end
	local globalHitRate = Analytics.calculateGlobalHitRate(pools)
	if globalHitRate < 0.3 then
		table.insert(allWarnings, string.format("Low global hit rate: %.1f%%", globalHitRate * 100))
	end
	return {
		overallHealth = #allIssues == 0,
		issues = allIssues,
		warnings = allWarnings,
		recommendations = allRecommendations,
	}
end
function Pooler:AutoRepairAllPools(): { [string]: { string } }
	local repairs = {}
	for name, pool in pairs(pools) do
		local poolImpl = pool :: Types.ObjectPoolImpl<any>
		repairs[name] = Validation.autoRepair(poolImpl)
	end
	return repairs
end
return Pooler
