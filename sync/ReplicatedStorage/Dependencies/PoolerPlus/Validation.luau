--!strict
--!optimize 2
-- Pooler+
-- riftkuro '25

local Types = require(script.Parent.Types)

local Validation = {}

function Validation.validatePool(pool: Types.ObjectPoolImpl<any>): boolean
	if not pool._config.enableValidation then
		return true
	end

	local issues = {}

	local totalTracked = pool:_getTotalSize()
	if totalTracked > pool._stats.totalCreated then
		table.insert(issues, "Object count exceeds total created")
	end

	for obj in pairs(pool._inUse) do
		if typeof(obj) == "Instance" and not obj.Parent then
			table.insert(issues, "Found orphaned instance in use")
		end
	end

	for _, obj in ipairs(pool._available) do
		if pool._inUse[obj] then
			table.insert(issues, "Object appears in both available and in-use")
		end
	end

	if #pool._available < 0 then
		table.insert(issues, "Negative available count")
	end

	local calculatedMemory = 0
	for _ in pairs(pool._inUse) do
		calculatedMemory += 256 -- Rough estimate
	end
	for _, obj in ipairs(pool._available) do
		calculatedMemory += 256 -- Rough estimate
	end

	if math.abs(calculatedMemory - pool._stats.memoryUsage) > 1024 * 10 then -- 10KB tolerance
		table.insert(issues, "Memory usage tracking inconsistent")
	end

	if #pool._lifetimeSamples > 150 then
		table.insert(issues, "Excessive lifetime samples")
	end

	if pool._stats.hits < 0 or pool._stats.misses < 0 or pool._stats.totalCreated < 0 then
		table.insert(issues, "Negative statistics values")
	end

	if
		pool._stats.totalCreated > 0
		and pool._stats.hits + pool._stats.misses > math.max(pool._stats.totalCreated * 100, 1000)
	then
		table.insert(issues, "Hit/miss count exceeds reasonable bounds")
	end

	if #issues > 0 then
		warn(("[Pooler] Pool '%s' validation failed: %s"):format(pool._name, table.concat(issues, ", ")))
		return false
	end

	return true
end

function Validation.checkMemoryLeaks(pool: Types.ObjectPoolImpl<any>): { string }
	local issues = {}

	local totalTracked = pool:_getTotalSize()
	if totalTracked > pool._stats.totalCreated then
		table.insert(
			issues,
			string.format(
				"Memory leak detected: tracking %d objects but only created %d",
				totalTracked,
				pool._stats.totalCreated
			)
		)
	end

	local excessObjects = #pool._available + pool:_getInUseCount() - pool._maxSize
	if excessObjects > pool._maxSize * 0.1 then
		table.insert(
			issues,
			string.format("Potential memory leak: %d excess objects beyond max size", excessObjects)
		)
	end

	return issues
end

function Validation.checkOrphanedInstances(pool: Types.ObjectPoolImpl<any>): { string }
	local issues = {}

	for obj in pairs(pool._inUse) do
		if typeof(obj) == "Instance" then
			local instance = obj :: Instance
			if not instance.Parent then
				table.insert(
					issues,
					string.format("Orphaned instance in use: %s (no parent)", instance.Name or "Unknown")
				)
			end
		end
	end

	for i, obj in ipairs(pool._available) do
		if typeof(obj) == "Instance" then
			local instance = obj :: Instance
			if not instance.Parent then
				table.insert(
					issues,
					string.format(
						"Orphaned instance in available pool at index %d: %s",
						i,
						instance.Name or "Unknown"
					)
				)
			end
		end
	end

	return issues
end

function Validation.checkDataIntegrity(pool: Types.ObjectPoolImpl<any>): { string }
	local issues = {}

	for _, obj in ipairs(pool._available) do
		if pool._inUse[obj] then
			table.insert(issues, "Object found in both available and in-use collections")
		end
	end

	local stats = pool._stats
	if stats.hits < 0 then
		table.insert(issues, "Negative hits count")
	end
	if stats.misses < 0 then
		table.insert(issues, "Negative misses count")
	end
	if stats.totalCreated < 0 then
		table.insert(issues, "Negative total created count")
	end
	if stats.peakUsage < 0 then
		table.insert(issues, "Negative peak usage")
	end
	if stats.memoryUsage < 0 then
		table.insert(issues, "Negative memory usage")
	end

	if stats.peakUsage > stats.totalCreated * 2 then
		table.insert(issues, "Peak usage exceeds reasonable bounds")
	end

	print(
		("DEBUG: Pool %s - hits+misses=%d, totalCreated=%d, threshold=%d"):format(
			pool._name,
			stats.hits + stats.misses,
			stats.totalCreated,
			stats.totalCreated * 10
		)
	)
	if stats.totalCreated > 0 and stats.hits + stats.misses > math.max(stats.totalCreated * 100, 1000) then
		table.insert(issues, "Total operations exceed reasonable bounds")
	end

	return issues
end

function Validation.healthCheck(pool: Types.ObjectPoolImpl<any>): {
	isHealthy: boolean,
	issues: { string },
	warnings: { string },
	memoryLeaks: { string },
	orphanedInstances: { string },
	dataIntegrityIssues: { string },
}
	local memoryLeaks = Validation.checkMemoryLeaks(pool)
	local orphanedInstances = Validation.checkOrphanedInstances(pool)
	local dataIntegrityIssues = Validation.checkDataIntegrity(pool)

	local allIssues = {}
	local warnings = {}

	for _, issue in ipairs(memoryLeaks) do
		table.insert(allIssues, issue)
	end
	for _, issue in ipairs(orphanedInstances) do
		table.insert(allIssues, issue)
	end
	for _, issue in ipairs(dataIntegrityIssues) do
		table.insert(allIssues, issue)
	end

	local hitRate = pool._stats.hits + pool._stats.misses > 0
			and pool._stats.hits / (pool._stats.hits + pool._stats.misses)
		or 0

	if hitRate < 0.5 and pool._stats.hits + pool._stats.misses > 100 then
		table.insert(
			warnings,
			string.format("Low hit rate: %.1f%% (consider increasing pool size)", hitRate * 100)
		)
	end

	if pool._stats.averageLifetime > 300 then
		table.insert(
			warnings,
			string.format(
				"High average lifetime: %.1fs (objects held too long?)",
				pool._stats.averageLifetime
			)
		)
	end

	if #pool._available > pool._stats.peakUsage * 3 then
		table.insert(
			warnings,
			string.format(
				"Excessive available objects: %d available vs %d peak usage",
				#pool._available,
				pool._stats.peakUsage
			)
		)
	end

	return {
		isHealthy = #allIssues == 0,
		issues = allIssues,
		warnings = warnings,
		memoryLeaks = memoryLeaks,
		orphanedInstances = orphanedInstances,
		dataIntegrityIssues = dataIntegrityIssues,
	}
end

function Validation.quickValidate(pool: Types.ObjectPoolImpl<any>): boolean
	if not pool._config.enableValidation then
		return true
	end

	local totalTracked = pool:_getTotalSize()
	if totalTracked > pool._stats.totalCreated then
		return false
	end

	if pool._stats.hits < 0 or pool._stats.misses < 0 or pool._stats.totalCreated < 0 then
		return false
	end

	return true
end

function Validation.autoRepair(pool: Types.ObjectPoolImpl<any>): { string }
	local repairs = {}

	local cleanedAvailable = {}
	for _, obj in ipairs(pool._available) do
		if typeof(obj) == "Instance" then
			local instance = obj :: Instance
			if instance.Parent then
				table.insert(cleanedAvailable, obj)
			else
				table.insert(repairs, "Removed orphaned instance from available pool")
			end
		else
			table.insert(cleanedAvailable, obj)
		end
	end
	pool._available = cleanedAvailable

	local cleanedInUse = {}
	for obj, _ in pairs(pool._inUse) do
		if typeof(obj) == "Instance" then
			local instance = obj :: Instance
			if instance.Parent then
				cleanedInUse[obj] = true
			else
				table.insert(repairs, "Removed orphaned instance from in-use tracking")
			end
		else
			cleanedInUse[obj] = true
		end
	end
	pool._inUse = cleanedInUse

	if pool._stats.hits < 0 then
		pool._stats.hits = 0
		table.insert(repairs, "Reset negative hits count")
	end
	if pool._stats.misses < 0 then
		pool._stats.misses = 0
		table.insert(repairs, "Reset negative misses count")
	end
	if pool._stats.totalCreated < 0 then
		pool._stats.totalCreated = pool:_getTotalSize()
		table.insert(repairs, "Reset negative total created count")
	end
	if pool._stats.memoryUsage < 0 then
		pool._stats.memoryUsage = 0
		table.insert(repairs, "Reset negative memory usage")
	end

	if #pool._lifetimeSamples > 100 then
		while #pool._lifetimeSamples > 100 do
			table.remove(pool._lifetimeSamples, 1)
		end
		table.insert(repairs, "Trimmed excessive lifetime samples")
	end

	return repairs
end

return Validation
