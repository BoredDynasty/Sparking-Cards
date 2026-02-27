--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local skill_chart = require(ReplicatedStorage.Structures["skill-chart"])
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- skill-manager.luau
-- client-sided

local module = {}

local events = ReplicatedStorage.Events

function module:GetSkills()
	local profile = fetchProfile()

	return profile.Data.skills
end

function module:GetDataFromName(name: string): typemarshaller.Skill?
	-- can yield lmao

	for i, data in ipairs(skill_chart) do
		if string.lower(data.name) == string.lower(name) then
			return data :: typemarshaller.Skill
		end
	end

	return nil
end

function module:GetTotalMultiplier(name: string)
	local skills = module:GetSkills()

	-- find out if it even is in the player skills array.
	local i = table.find(skills, name)
	if not i then
		return 1
	end

	local skill = skills[i]

	local data = module:GetDataFromName(skill)

	-- find out how many occurences of `name` is in player skills array

	local count = 0
	for _, skill_name in ipairs(skills) do
		if skill_name == name then
			count += 1
		end
	end

	if data then
		local multiplier = data.multiplier

		return 1 + (multiplier or 1.05 * count)
	else
		return 1
	end
end

function module:Insert(name: string)
	-- is it a registered skill?

	local data = module:GetDataFromName(name)
	if not data then
		warn("[ " .. name .. " ] is not a registered skill.")
	end

	local ok = events.InsertSkill:InvokeServer(name)
	if ok then
		print("skill insertion was successful. ", ok)
	end
end

function module:Remove(name: string)
	-- is it a registered skill?

	local data = module:GetDataFromName(name)
	if not data then
		warn("[ " .. name .. " ] is not a registered skill.")
	end

	local ok = events.RemoveSkill:InvokeServer(name)
	if ok then
		print("skill deletion was successful. ", ok)
	end
end

return module
