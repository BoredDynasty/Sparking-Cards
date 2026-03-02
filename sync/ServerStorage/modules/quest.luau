--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local _Players = game:GetService("Players")
local _RunService = game:GetService("RunService")

local leventine = require(ReplicatedStorage.Utility.leventine)
local registered = require(ServerStorage.modules.quest.registered)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- quest.luau
-- should be ran on the server

local module = {}

local events = ReplicatedStorage.Events

local get_quest_data = events.GetQuestData

local get_profile = events.GetProfileServer

function module:GetRegistered(): { string }
	local list = table.create(#registered) :: { string }

	for i, data in ipairs(registered) do
		table.insert(list, data.name)
	end

	return list
end

function module:IsRegistered(name: string)
	local list = module:GetRegistered()

	for i, quest_name in ipairs(list) do
		if string.lower(quest_name) == string.lower(name) then
			return true
		end
	end

	return false
end

function module:GetModuleFromName(name: string): ModuleScript?
	local all_names = module:GetRegistered()

	for i, data in ipairs(registered) do
		-- is the name registered?

		if not module:IsRegistered(name) then
			continue
		end

		-- find out if the name is similar to one of the names

		if leventine.has_match(all_names[i], name, false) then
			-- well done.

			return data.module
		end
	end

	return nil
end

-- helper to return a sanitized copy of a player's quest list
function module:GetPlayerQuests(player: Player): { typemarshaller.Quest }
	local profile = get_profile:Invoke(player) :: typemarshaller.ProfileData
	if not profile then
		return {}
	end

	-- we return a shallow copy so callers can't accidentally mutate the stored table
	local out: { typemarshaller.Quest } = {}

	for i, q in ipairs(profile.quests or {}) do
		local copy: typemarshaller.Quest = {
			name = q.name,
			description = q.description,
			inquirer_img = q.inquirer_img,
			progress = q.progress,
			date_acquired = q.date_acquired,
			date_completed = q.date_completed,
			completed = q.completed,
		}
		-- module fields are not serialised to the client
		out[i] = copy
	end

	return out
end

-- RemoteFunctions exposed for client requests
get_quest_data.OnServerInvoke = function(player: Player)
	return module:GetPlayerQuests(player)
end

-- clients will fire this event whenever they make progress on a quest.  the
-- payload should be { name = string, progress = number }.
local report_progress = events.ReportQuestProgress

report_progress.OnServerEvent:Connect(function(player: Player, name: string, progress: number)
	if not module:IsRegistered(name) then
		warn("quest not registered: ", name)
	end

	local profile = get_profile:Invoke(player) :: typemarshaller.ProfileData
	if not profile then
		return
	end

	for _, q in ipairs(profile.quests) do
		if q.name == name then
			q.progress = progress or q.progress

			if q.progress >= 100 and not q.completed then
				q.completed = true
				q.date_completed = DateTime.now().UnixTimestampMillis
			end

			break
		end
	end
end)

return module
