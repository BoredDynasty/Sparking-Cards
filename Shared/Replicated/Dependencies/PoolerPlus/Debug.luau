--!strict
--!optimize 2
-- Pooler+
-- riftkuro '25

local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local Analytics = require(script.Parent.Analytics)
local Types = require(script.Parent.Types)
local Utils = require(script.Parent.Utils)

local Debug = {}

function Debug.serializePoolState(pool: Types.ObjectPoolImpl<any>): string
	local state = {
		name = pool._name,
		available = #pool._available,
		inUse = pool:_getInUseCount(),
		maxSize = pool._maxSize,
		stats = pool._stats,
		enhancedStats = Analytics.calculateEnhancedStats(pool),
		timestamp = tick(),
	}

	return HttpService:JSONEncode(state)
end

function Debug.printAllPools(pools: { [string]: any })
	print(
		"â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«"
	)
	print("POOLER DEBUG REPORT - " .. os.date("%X"))
	print(
		"â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«"
	)

	local memoryPressure = Utils.getMemoryPressure()
	print(("Memory Pressure: %s (%.1f MB)"):format(memoryPressure, Stats:GetTotalMemoryUsageMb()))

	local poolCount = 0
	for _ in pairs(pools) do
		poolCount += 1
	end
	print(("Total Pools: %d"):format(poolCount))

	for poolName, pool in pairs(pools) do
		local stats = Analytics.calculateEnhancedStats(pool)
		local status = pool:GetStatus()

		print("â«â«â«â«â«â«â«â«â«â«â«â«â«â«")
		print(("Pool: %s"):format(poolName))
		print("â«â«â«â«â«â«â«â«â«â«â«â«â«â«")
		print(
			("  Available: %d | In Use: %d | Total: %d"):format(status.Available, status.InUse, status.Total)
		)
		print(
			("  Hits: %d | Misses: %d | Hit Rate: %.1f%%"):format(
				stats.hits,
				stats.misses,
				stats.hitRate * 100
			)
		)
		print(("  Peak Usage: %d | Total Created: %d"):format(stats.peakUsage, stats.totalCreated))
		print(
			("  Efficiency: %.1f%% | Memory Usage: %.1f KB"):format(
				stats.efficiency * 100,
				stats.memoryUsage / 1024
			)
		)
		print(("  Creation Rate: %.2f/s | Return Rate: %.2f/s"):format(stats.creationRate, stats.returnRate))
		print(
			("  Optimizations: %d | Last Optimized: %.1fs ago"):format(
				stats.optimizationCount,
				stats.lastOptimized > 0 and tick() - stats.lastOptimized or -1
			)
		)
		print(("  Avg Lifetime: %.3fs"):format(stats.averageLifetime))
	end

	print(
		"â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«"
	)
	print("END DEBUG REPORT")
	print(
		"â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«"
	)
end

function Debug.getPerformanceReport(pools: { [string]: any }): string
	local report = {}
	table.insert(report, "POOLER PERFORMANCE REPORT")
	table.insert(report, "Generated: " .. os.date("%c"))
	table.insert(report, "")

	local totalHits = 0
	local totalMisses = 0
	local totalMemory = 0
	local totalPools = 0

	for poolName, pool in pairs(pools) do
		local stats = Analytics.calculateEnhancedStats(pool)
		totalHits += stats.hits
		totalMisses += stats.misses
		totalMemory += stats.memoryUsage
		totalPools += 1

		table.insert(report, string.format("Pool '%s':", poolName))
		table.insert(
			report,
			string.format(
				"  Performance: %.1f%% hit rate, %.1f%% efficiency",
				stats.hitRate * 100,
				stats.efficiency * 100
			)
		)
		table.insert(
			report,
			string.format("  Activity: %.2f creates/s, %.2f returns/s", stats.creationRate, stats.returnRate)
		)
		table.insert(report, string.format("  Memory: %.1f KB used", stats.memoryUsage / 1024))
		table.insert(report, "")
	end

	local globalHitRate = totalHits + totalMisses > 0 and totalHits / (totalHits + totalMisses) or 0
	table.insert(report, "GLOBAL SUMMARY:")
	table.insert(report, string.format("  Total Pools: %d", totalPools))
	table.insert(report, string.format("  Global Hit Rate: %.1f%%", globalHitRate * 100))
	table.insert(report, string.format("  Total Memory Used: %.1f KB", totalMemory / 1024))
	table.insert(report, string.format("  System Memory Pressure: %s", Utils.getMemoryPressure()))

	return table.concat(report, "\n")
end

function Debug.exportPoolStates(pools: { [string]: any }): string
	local states = {}
	for name, pool in pairs(pools) do
		states[name] = HttpService:JSONDecode(Debug.serializePoolState(pool))
	end

	local export = {
		timestamp = tick(),
		poolCount = 0,
		memoryPressure = Utils.getMemoryPressure(),
		systemMemory = Stats:GetTotalMemoryUsageMb(),
		pools = states,
	}

	for _ in pairs(pools) do
		export.poolCount += 1
	end

	return HttpService:JSONEncode(export)
end

function Debug.analyzePool(pool: Types.ObjectPoolImpl<any>): string
	local analysis = {}
	local stats = Analytics.calculateEnhancedStats(pool)
	local status = pool:GetStatus()

	table.insert(analysis, string.format("=== POOL ANALYSIS: %s ===", pool._name))
	table.insert(analysis, "")

	table.insert(analysis, "BASIC STATISTICS:")
	table.insert(analysis, string.format("  Available Objects: %d", status.Available))
	table.insert(analysis, string.format("  Objects In Use: %d", status.InUse))
	table.insert(analysis, string.format("  Total Objects: %d", status.Total))
	table.insert(analysis, string.format("  Max Pool Size: %d", pool._maxSize))
	table.insert(analysis, "")

	table.insert(analysis, "PERFORMANCE METRICS:")
	table.insert(
		analysis,
		string.format(
			"  Hit Rate: %.2f%% (%d hits, %d misses)",
			stats.hitRate * 100,
			stats.hits,
			stats.misses
		)
	)
	table.insert(analysis, string.format("  Pool Efficiency: %.2f%%", stats.efficiency * 100))
	table.insert(analysis, string.format("  Peak Usage: %d objects", stats.peakUsage))
	table.insert(analysis, string.format("  Total Created: %d objects", stats.totalCreated))
	table.insert(analysis, "")

	table.insert(analysis, "ACTIVITY RATES:")
	table.insert(analysis, string.format("  Creation Rate: %.2f objects/second", stats.creationRate))
	table.insert(analysis, string.format("  Return Rate: %.2f objects/second", stats.returnRate))
	table.insert(analysis, string.format("  Average Lifetime: %.3f seconds", stats.averageLifetime))
	table.insert(analysis, "")

	table.insert(analysis, "MEMORY USAGE:")
	table.insert(analysis, string.format("  Pool Memory: %.2f KB", stats.memoryUsage / 1024))
	table.insert(analysis, string.format("  Memory Efficiency: %.2f KB saved", stats.memoryEfficiency / 1024))
	table.insert(
		analysis,
		string.format(
			"  Avg Memory/Object: %.1f bytes",
			status.Total > 0 and stats.memoryUsage / status.Total or 0
		)
	)
	table.insert(analysis, "")

	table.insert(analysis, "OPTIMIZATION:")
	table.insert(analysis, string.format("  Times Optimized: %d", stats.optimizationCount))
	if stats.lastOptimized > 0 then
		table.insert(
			analysis,
			string.format("  Last Optimized: %.1f seconds ago", tick() - stats.lastOptimized)
		)
	else
		table.insert(analysis, "  Last Optimized: Never")
	end
	table.insert(analysis, "")

	table.insert(analysis, "CONFIGURATION:")
	table.insert(
		analysis,
		string.format("  Analytics Enabled: %s", pool._config.enableAnalytics and "Yes" or "No")
	)
	table.insert(
		analysis,
		string.format("  Adaptive Preload: %s", pool._config.enableAdaptivePreload and "Yes" or "No")
	)
	table.insert(
		analysis,
		string.format("  Validation Enabled: %s", pool._config.enableValidation and "Yes" or "No")
	)

	return table.concat(analysis, "\n")
end

function Debug.generateRecommendations(pool: Types.ObjectPoolImpl<any>): { string }
	local recommendations = {}
	local stats = Analytics.calculateEnhancedStats(pool)
	local status = pool:GetStatus()

	if stats.hitRate < 0.5 and stats.hits + stats.misses > 50 then
		table.insert(
			recommendations,
			string.format(
				"Low hit rate (%.1f%%). Consider increasing maxSize or preloadCount.",
				stats.hitRate * 100
			)
		)
	end

	if status.Available > stats.peakUsage * 3 and status.Available > 20 then
		table.insert(
			recommendations,
			string.format(
				"Pool may be oversized. %d available vs %d peak usage. Consider reducing maxSize.",
				status.Available,
				stats.peakUsage
			)
		)
	end

	if status.Available == 0 and stats.misses > stats.hits then
		table.insert(recommendations, "Pool frequently empty. Consider increasing maxSize or preloadCount.")
	end

	if stats.averageLifetime > 300 then
		table.insert(
			recommendations,
			string.format(
				"High average lifetime (%.1fs). Objects may be held too long.",
				stats.averageLifetime
			)
		)
	end

	if stats.averageLifetime < 1 and stats.hits > 100 then
		table.insert(
			recommendations,
			string.format("Very short lifetime (%.3fs). Pool might not be beneficial.", stats.averageLifetime)
		)
	end

	if stats.creationRate > stats.returnRate * 1.5 and stats.totalCreated > 100 then
		table.insert(recommendations, "Creation rate exceeds return rate. Check for object leaks.")
	end

	if stats.memoryUsage > 1024 * 1024 * 10 then
		table.insert(
			recommendations,
			string.format(
				"High memory usage (%.1f MB). Consider optimization.",
				stats.memoryUsage / (1024 * 1024)
			)
		)
	end

	if not pool._config.enableValidation and status.Total > 100 then
		table.insert(recommendations, "Consider enabling validation for large pools to detect issues early.")
	end

	if not pool._config.enableAdaptivePreload and stats.peakUsage > 50 then
		table.insert(recommendations, "Consider enabling adaptive preloading for better performance.")
	end

	if #recommendations == 0 then
		table.insert(recommendations, "Pool appears to be well-configured!")
	end

	return recommendations
end

function Debug.createDebugDump(pools: { [string]: any }): string
	local dump = {}

	table.insert(dump, "POOLER DEBUG DUMP")
	table.insert(dump, "Generated: " .. os.date("%c"))
	table.insert(dump, "Timestamp: " .. tick())
	table.insert(dump, "")

	table.insert(dump, "SYSTEM INFORMATION:")
	table.insert(dump, string.format("  Memory Pressure: %s", Utils.getMemoryPressure()))
	table.insert(dump, string.format("  Total Memory: %.1f MB", Stats:GetTotalMemoryUsageMb()))
	table.insert(dump, "")

	table.insert(dump, "POOL SUMMARIES:")
	for name, pool in pairs(pools) do
		local stats = Analytics.calculateEnhancedStats(pool)
		table.insert(
			dump,
			string.format(
				"  %s: %d available, %d in use, %.1f%% hit rate",
				name,
				#pool._available,
				pool:_getInUseCount(),
				stats.hitRate * 100
			)
		)
	end
	table.insert(dump, "")

	for name, pool in pairs(pools) do
		table.insert(dump, Debug.analyzePool(pool))
		table.insert(dump, "")

		local recommendations = Debug.generateRecommendations(pool)
		table.insert(dump, string.format("RECOMMENDATIONS FOR %s:", name))
		for _, rec in ipairs(recommendations) do
			table.insert(dump, "  â¢ " .. rec)
		end
		table.insert(dump, "")
		print(
			"â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«â«"
		)
		table.insert(dump, "")
	end

	return table.concat(dump, "\n")
end

return Debug
