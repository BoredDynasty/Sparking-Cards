local CalculateStats = {}

local cachedLevels = {}
local exponent = 1.8
local multiplier = 100

-- Level to experience.
local function experienceFormula(level: number): number
	local experience = level ^ exponent * multiplier
	experience = math.floor(experience / 5) * 5
	cachedLevels[level] = experience
	return experience
end

-- Experience to level.
local function levelFormula(experience: number): number
	local level = experience / multiplier ^ (1 / exponent)
	return math.floor(level)
end

function CalculateStats.FromExp(experience: number): number
	local level = levelFormula(experience)
	return level
end

function CalculateStats.FromLevel(level: number): number
	local experience = experienceFormula(level)
	return experience
end

return CalculateStats
