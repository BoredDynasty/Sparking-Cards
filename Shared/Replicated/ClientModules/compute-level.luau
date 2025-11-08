--!strict

-- compute-level.luau

local compute_module = {
	-- constants
	exponent = 1.8,
	multiplier = 100,
}

export type mode = "rank" | "experience"

--[[
	Level to experience formula derivation:
	`l ^ 1.8 * 100`

	@param level number
	@return number
]]
local function computeExperience(level: number): number
	local experience = level ^ compute_module.exponent * compute_module.multiplier
	experience = math.floor(experience / 5) * 5

	return experience
end

--[[
	Exerience to level formula derivation:
	`e / 100 ^ (1 / 1.8)`

	@param experience number
	@return number
]]
local function computeRank(experience: number): number
	local level = experience / compute_module.multiplier ^ (1 / compute_module.exponent)

	return math.floor(level)
end

-- Ordered list of ranks (1-based). Keep in sync with `Shared/Replicated/Structures/RankStructure.luau`.
local rankOrder: { string } = {
	"Bronze I",
	"Iron II",
	"Gold III",
	"Platinum IV",
	"Emerald V",
	"Master VI",
	"Elite VII",
	"Ruby VIII",
	"Prismatic IX",
	"Sparking X",
}

local nameToNumber = table.create(#rankOrder) :: { [string]: number }
for i, name in ipairs(rankOrder) do
	nameToNumber[name] = i
end

--[[
	Convert a 1-based rank number to its rank name.

	@param rankNumber number (1-based)
	@return string? rank name or nil if out of range
]]
local function rankNumberToName(rankNumber: number): string?
	if type(rankNumber) ~= "number" then
		return nil
	end

	rankNumber = math.floor(rankNumber)
	if rankNumber < 1 or rankNumber > #rankOrder then
		return nil
	end

	return rankOrder[rankNumber]
end

--[[
	Convert a rank name to its 1-based rank number.

	@param rankName string
	@return number? rank number or nil if not found
]]
local function rankNameToNumber(rankName: string): number?
	return table.find(rankOrder, rankName)
end

return setmetatable({
	fromLevel = computeExperience,
	fromExperience = computeRank,
	rankNumberToName = rankNumberToName,
	rankNameToNumber = rankNameToNumber,
}, {
	__call = function(mode: mode, value: number): number?
		if mode == "experience" then
			return computeRank(value)
		elseif mode == "rank" then
			return computeExperience(value)
		else
			return nil
		end
	end,
})
