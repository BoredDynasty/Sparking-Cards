--!strict
--!optimize 2
-- Pooler+
-- riftkuro '25
local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)
local Utils = require(script.Parent.Utils)
local Analytics = {}
function Analytics.calculateEnhancedStats(pool: Types.ObjectPoolImpl<any>): Types.EnhancedPoolStats
	local stats = pool._stats
	local total = stats.hits + stats.misses
	return {
		name = stats.name,
		hits = stats.hits,
		misses = stats.misses,
		peakUsage = stats.peakUsage,
		totalCreated = stats.totalCreated,
		averageLifetime = stats.averageLifetime,
		memoryUsage = stats.memoryUsage,
		hitRate = total > 0 and stats.hits / total or 0,
		efficiency = stats.totalCreated > 0 and stats.hits / stats.totalCreated or 0,
		memoryEfficiency = stats.totalCreated > 0 and (stats.hits * Utils.estimateMemoryUsage({})) or 0,
		optimizationCount = pool._optimizationCount,
		lastOptimized = pool._lastOptimized,
		creationRate = pool._creationRate,
		returnRate = pool._returnRate,
	}
end
function Analytics.updateRates(pool: Types.ObjectPoolImpl<any>)
	local currentTime = tick()
	if #pool._creationTimes > 1 then
		local timeSpan = pool._creationTimes[#pool._creationTimes] - pool._creationTimes[1]
		if timeSpan > 0 then
			pool._creationRate = (#pool._creationTimes - 1) / timeSpan
		end
	end
	if #pool._returnTimes > 1 then
		local timeSpan = pool._returnTimes[#pool._returnTimes] - pool._returnTimes[1]
		if timeSpan > 0 then
			pool._returnRate = (#pool._returnTimes - 1) / timeSpan
		end
	end
end
function Analytics.trackCreation(pool: Types.ObjectPoolImpl<any>)
	table.insert(pool._creationTimes, tick())
	if #pool._creationTimes > Constants.MAX_RATE_SAMPLES then
		table.remove(pool._creationTimes, 1)
	end
end
function Analytics.trackReturn(pool: Types.ObjectPoolImpl<any>)
	table.insert(pool._returnTimes, tick())
	if #pool._returnTimes > Constants.MAX_RATE_SAMPLES then
		table.remove(pool._returnTimes, 1)
	end
end
function Analytics.updateLifetimeStats(pool: Types.ObjectPoolImpl<any>, object: any)
	local birthTime = pool._objectBirthTimes[object]
	if birthTime then
		local lifetime = tick() - birthTime
		table.insert(pool._lifetimeSamples, lifetime)
		pool._objectBirthTimes[object] = nil
		if #pool._lifetimeSamples > Constants.MAX_LIFETIME_SAMPLES then
			table.remove(pool._lifetimeSamples, 1)
		end
		local total = 0
		for _, sample in ipairs(pool._lifetimeSamples) do
			total += sample
		end
		pool._stats.averageLifetime = total / #pool._lifetimeSamples
	end
end
function Analytics.recordBirthTime(pool: Types.ObjectPoolImpl<any>, object: any)
	pool._objectBirthTimes[object] = tick()
end
function Analytics.updatePeakUsage(pool: Types.ObjectPoolImpl<any>, currentUsage: number)
	if currentUsage > pool._stats.peakUsage then
		pool._stats.peakUsage = currentUsage
	end
end
function Analytics.calculateGlobalMemoryEfficiency(pools: { [string]: any }): number
	local totalMemorySaved = 0
	local totalPools = 0
	for _, pool in pairs(pools) do
		local stats = Analytics.calculateEnhancedStats(pool)
		totalMemorySaved += stats.memoryEfficiency
		totalPools += 1
	end
	return totalPools > 0 and totalMemorySaved / totalPools or 0
end
function Analytics.calculateGlobalHitRate(pools: { [string]: any }): number
	local totalHits = 0
	local totalMisses = 0
	for _, pool in pairs(pools) do
		totalHits += pool._stats.hits
		totalMisses += pool._stats.misses
	end
	local total = totalHits + totalMisses
	return total > 0 and totalHits / total or 0
end
function Analytics.getTotalPoolMemory(pools: { [string]: any }): number
	local totalMemory = 0
	for _, pool in pairs(pools) do
		totalMemory += pool._stats.memoryUsage
	end
	return totalMemory
end
function Analytics.initializePool(pool: Types.ObjectPoolImpl<any>)
	pool._optimizationCount = 0
	pool._lastOptimized = 0
	pool._creationRate = 0
	pool._returnRate = 0
	pool._creationTimes = {}
	pool._returnTimes = {}
	pool._lastAdaptivePreload = 0
end
return Analytics
