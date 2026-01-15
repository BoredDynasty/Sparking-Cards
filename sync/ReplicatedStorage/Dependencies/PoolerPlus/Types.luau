--!strict
--!optimize 2
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
-- Pooler+
-- riftkuro '25
local Types = {}
-- function that creates and returns a new object for the pool
export type CreateFunction<T> = () -> T
-- function that resets an object's state, preparing it for reuse
export type CleanupFunction<T> = (object: T) -> ()
-- function that permanently destroys an object
export type DestroyFunction<T> = (object: T) -> ()
export type InstanceConfig = {
	template: Instance?, -- template object to reset properties from
	resetProperties: { string }?, -- specific properties to reset
	cleanupConnections: boolean?, -- whether to cleanup connections automatically
	safeParent: Instance?, -- where to parent objects when not in use
}
export type PoolConfig = {
	maxSize: number?, -- maximum number of objects in pool
	preloadCount: number?, -- number of objects to create initially
	instanceConfig: InstanceConfig?, -- configuration for Instance objects
	enableAnalytics: boolean?, -- whether to track usage statistics
	enableAdaptivePreload: boolean?, -- whether to use adaptive preloading
	enableValidation: boolean?, -- whether to enable pool validation
}
export type MemoryPressure = "none" | "moderate" | "critical"
export type PoolPriority = "low" | "normal" | "high" | "critical"
export type PoolStats = {
	name: string,
	hits: number, -- times Get() returned a pooled object
	misses: number, -- times Get() had to create a new object
	peakUsage: number, -- maximum objects in use at once
	totalCreated: number, -- total objects ever created
	averageLifetime: number, -- average time objects stay in use
	memoryUsage: number, -- estimated memory usage in bytes
}
export type EnhancedPoolStats = {
	name: string,
	hits: number,
	misses: number,
	peakUsage: number,
	totalCreated: number,
	averageLifetime: number,
	memoryUsage: number,
	hitRate: number, -- hits / (hits + misses)
	efficiency: number, -- objects reused / total objects created
	memoryEfficiency: number, -- memory saved by pooling
	optimizationCount: number, -- times pool was optimized
	lastOptimized: number, -- timestamp of last optimization
	creationRate: number, -- objects created per second
	returnRate: number, -- objects returned per second
}
export type PoolError = {
	message: string,
	errorType: string,
	poolName: string?,
	timestamp: number,
}
export type ObjectPoolImpl<T> = {
	_name: string,
	_available: { T },
	_inUse: { [T]: boolean },
	_create: CreateFunction<T>,
	_cleanup: CleanupFunction<T>?,
	_destroy: DestroyFunction<T>?,
	_config: PoolConfig,
	_maxSize: number,
	_stats: PoolStats,
	_objectBirthTimes: { [T]: number },
	_lifetimeSamples: { number },
	_optimizationCount: number,
	_lastOptimized: number,
	_creationRate: number,
	_returnRate: number,
	_creationTimes: { number },
	_returnTimes: { number },
	_lastAdaptivePreload: number,
	OnGet: SignalPlus.Signal<T>,
	OnReturn: SignalPlus.Signal<T>,
	OnCreate: SignalPlus.Signal<T>,
	OnOptimize: SignalPlus.Signal<>,
	Get: (self: ObjectPoolImpl<T>) -> T,
	GetSafe: (self: ObjectPoolImpl<T>) -> (T?, PoolError?),
	GetWithPriority: (self: ObjectPoolImpl<T>, priority: PoolPriority) -> T?,
	GetBatch: (self: ObjectPoolImpl<T>, count: number) -> { T },
	Return: (self: ObjectPoolImpl<T>, object: T) -> (),
	ReturnBatch: (self: ObjectPoolImpl<T>, objects: { T }) -> (),
	Preload: (self: ObjectPoolImpl<T>, count: number) -> (),
	AdaptivePreload: (self: ObjectPoolImpl<T>) -> (),
	ReturnAll: (self: ObjectPoolImpl<T>) -> (),
	Clear: (self: ObjectPoolImpl<T>) -> (),
	GetName: (self: ObjectPoolImpl<T>) -> string,
	GetStatus: (self: ObjectPoolImpl<T>) -> { Available: number, InUse: number, Total: number },
	GetStats: (self: ObjectPoolImpl<T>) -> PoolStats,
	GetEnhancedStats: (self: ObjectPoolImpl<T>) -> EnhancedPoolStats,
	GetActiveObjects: (self: ObjectPoolImpl<T>) -> { T },
	Optimize: (self: ObjectPoolImpl<T>) -> (),
	OptimizeWithGC: (self: ObjectPoolImpl<T>) -> (),
	SetMaxSize: (self: ObjectPoolImpl<T>, maxSize: number) -> (),
	Validate: (self: ObjectPoolImpl<T>) -> boolean,
	SerializeState: (self: ObjectPoolImpl<T>) -> string,
	_getTotalSize: (self: ObjectPoolImpl<T>) -> number,
	_getInUseCount: (self: ObjectPoolImpl<T>) -> number,
	_updateRates: (self: ObjectPoolImpl<T>) -> (),
}
export type ObjectPool<T> = {
	_config: PoolConfig,
	_maxSize: number,
	OnGet: SignalPlus.Signal<T>,
	OnReturn: SignalPlus.Signal<T>,
	OnCreate: SignalPlus.Signal<T>,
	OnOptimize: SignalPlus.Signal<>,
	Get: (self: ObjectPool<T>) -> T,
	GetSafe: (self: ObjectPool<T>) -> (T?, PoolError?),
	GetWithPriority: (self: ObjectPool<T>, priority: PoolPriority) -> T?,
	GetBatch: (self: ObjectPool<T>, count: number) -> { T },
	Return: (self: ObjectPool<T>, object: T) -> (),
	ReturnBatch: (self: ObjectPool<T>, objects: { T }) -> (),
	Preload: (self: ObjectPool<T>, count: number) -> (),
	AdaptivePreload: (self: ObjectPool<T>) -> (),
	ReturnAll: (self: ObjectPool<T>) -> (),
	Clear: (self: ObjectPool<T>) -> (),
	GetName: (self: ObjectPool<T>) -> string,
	GetStatus: (self: ObjectPool<T>) -> { Available: number, InUse: number, Total: number },
	GetStats: (self: ObjectPool<T>) -> PoolStats,
	GetEnhancedStats: (self: ObjectPool<T>) -> EnhancedPoolStats,
	GetActiveObjects: (self: ObjectPool<T>) -> { T },
	Optimize: (self: ObjectPool<T>) -> (),
	OptimizeWithGC: (self: ObjectPool<T>) -> (),
	SetMaxSize: (self: ObjectPool<T>, maxSize: number) -> (),
	Validate: (self: ObjectPool<T>) -> boolean,
	SerializeState: (self: ObjectPool<T>) -> string,
}
export type Pooler = {
	CreatePool: <T>(
		self: Pooler,
		name: string,
		createFn: CreateFunction<T>,
		cleanupFn: CleanupFunction<T>?,
		destroyFn: DestroyFunction<T>?,
		config: PoolConfig?
	) -> ObjectPool<T>,
	GetPool: <T>(self: Pooler, name: string) -> ObjectPool<T>?,
	Get: <T>(self: Pooler, poolName: string) -> T?,
	GetWithPriority: <T>(self: Pooler, poolName: string, priority: PoolPriority) -> T?,
	Return: <T>(self: Pooler, poolName: string, object: T) -> (),
	GetMemoryPressure: (self: Pooler) -> MemoryPressure,
	OptimizeAllPools: (self: Pooler) -> (),
	OptimizeAllPoolsWithGC: (self: Pooler) -> (),
	GetGlobalStats: (self: Pooler) -> { [string]: PoolStats },
	GetGlobalEnhancedStats: (self: Pooler) -> { [string]: EnhancedPoolStats },
	ValidateAllPools: (self: Pooler) -> { [string]: boolean },
	DebugPrintAllPools: (self: Pooler) -> (),
	GetPerformanceReport: (self: Pooler) -> string,
	ExportPoolStates: (self: Pooler) -> string,

	GetSystemStatus: (
		self: Pooler
	) -> {
		memoryPressure: MemoryPressure,
		totalPools: number,
		totalObjectsInUse: number,
		totalObjectsAvailable: number,
		totalMemoryUsage: number,
		globalHitRate: number,
		poolsWithIssues: { string },
	},
	BatchGet: (self: Pooler, requests: { { poolName: string, count: number } }) -> { [string]: { any } },
	EmergencyCleanup: (self: Pooler) -> (),
	HealthCheck: (
		self: Pooler
	) -> {
		overallHealth: boolean,
		issues: { string },
		warnings: { string },
		recommendations: { string },
	},
	AutoRepairAllPools: (self: Pooler) -> { [string]: { string } },
}
Types.CreateFunction = nil
Types.CleanupFunction = nil
Types.DestroyFunction = nil
Types.InstanceConfig = nil
Types.PoolConfig = nil
Types.MemoryPressure = nil
Types.PoolPriority = nil
Types.PoolStats = nil
Types.EnhancedPoolStats = nil
Types.PoolError = nil
Types.ObjectPoolImpl = nil
Types.ObjectPool = nil
Types.Pooler = nil
return Types
