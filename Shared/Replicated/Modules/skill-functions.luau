--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local skill_chart = require(ReplicatedStorage.Structures["skill-chart"])
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- skill-functions.luau
-- can be used both client and server

local module = {}

function module:GetTotalUpgrades(technique: string)
	local total = 0

	for i, skill in ipairs(skill_chart) do
		if string.lower(skill.technique) == string.lower(technique) then
			total += 1
		end
	end

	if total == 0 then
		warn("its possible that '" .. technique .. "' is not a valid technique.")
	end

	return total
end

function module:GetTechniquesUnlocked(profile: typemarshaller.Profile, technique: string)
	if not profile then
		print("no player data to get techniques unlocked.")
		return 1
	end

	-- basically,
	-- we allow for multiple skill names of the same name
	-- inside the skill table.
	-- let's use that to our advantage:

	local total = 0

	for i, skill_name in ipairs(profile.Data.skills) do
		if string.lower(skill_name) == string.lower(technique) then
			total += 1
		end
	end

	-- run a check
	local total_upgrades = module:GetTotalUpgrades(technique)
	if total > total_upgrades then
		-- what happened??
		warn("the player has unlocked more skills than allowed: ", total .. " > " .. total_upgrades)
	end

	return total
end

function module:GetTotalMultiplierFromTechniques(profile: typemarshaller.Profile, technique: string)
	local total_multiplier = 0

	for i, skill_name in ipairs(profile.Data.skills) do
		if string.lower(skill_name) == string.lower(technique) then
			-- find the skill in the skill chart and get its multiplier
			for j, skill in ipairs(skill_chart) do
				if string.lower(skill.technique) == string.lower(technique) then
					total_multiplier += skill.multiplier
				end
			end
		end
	end

	return total_multiplier
end

return module
