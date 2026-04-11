--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local _Players = game:GetService("Players")
local _RunService = game:GetService("RunService")

local bufferencoder = require(ReplicatedStorage.Packages.bufferencoder)
local future = require(ReplicatedStorage.Packages.future)
local leventine = require(ReplicatedStorage.Utility.leventine)
local log_analytics = require(ReplicatedStorage.Utility["log-analytics"])
local registered = require(ServerStorage.modules.quest.registered)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- quest.luau
-- should be ran on the server

local module = {}

local events = ReplicatedStorage.Events

local get_quest_data = events.GetQuestData

local get_profile = events.GetProfileServer

function module:GetRegistered(): ({ string }, number)
	local list = {}

	local j = 0
	for i, data in ipairs(registered) do
		j = i
		table.insert(list, data.name)
	end

	return list, j
end

function module:IsRegistered(name: string)
	local list, j = module:GetRegistered()

	local data = nil

	for i, quest_name in ipairs(list) do
		if string.lower(quest_name) == string.lower(name) then
			data = registered[j]
			return true, data
		end
	end

	return false, data
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
			print("has match.")

			return data.module
		end
	end

	return nil
end

-- helper to return a sanitized copy of a player's quest list
function module:GetPlayerQuests(player: Player): { typemarshaller.Quest }
	local profile = get_profile:Invoke(player) :: typemarshaller.ProfileData
	if not profile then
		warn("could not invoke profile. out: empty table.")

		return {}
	end

	-- we return a shallow copy so callers can't accidentally mutate the stored table
	local out = {}

	for i, q in ipairs(profile.quests or {}) do
		if typeof(q) ~= "table" then
			warn("quest is not a table: ", q, typeof(q))
		end

		out[i] = q
	end

	--print("out: ", out)

	return out
end

-- RemoteFunctions exposed for client requests
get_quest_data.OnServerInvoke = function(player: Player)
	return module:GetPlayerQuests(player)
end

-- clients will fire this event whenever they make progress on a quest.  the
-- payload should be { name = string, progress = number }.
local report_progress = events.ReportQuestProgress
local report_progress_server = events.ReportQuestProgressServer
local send_reward_server = events.SendExpRewardServer

report_progress.OnServerEvent:Connect(function(player: Player, bfr: buffer)
	local data = bufferencoder.read(bfr)

	local name = data.name
	local progress = data.progress

	if not module:IsRegistered(name) then
		warn("quest not registered: ", name)
	end

	local profile = get_profile:Invoke(player) :: typemarshaller.ProfileData
	if not profile then
		warn("no profile, halting progress report.")

		return
	end

	for _, q in ipairs(profile.quests) do
		if q.name == name then
			q.progress = progress or q.progress

			if q.progress >= 100 and not q.completed then
				q.completed = true
				q.date_completed = DateTime.now().UnixTimestampMillis

				log_analytics.onboarding_funnel_step(player, {
					step = 6,
					step_name = "Completed First Quest",
				})

				-- tell the server about our rewards.
				local b, registered_tbl = module:IsRegistered(name)

				local reward = registered_tbl.experience_reward
				if not reward then
					reward = 5
				end

				if player then
					task.wait(5)
					-- this is currently erroring.
					-- TODO: add this back!
					--send_reward_server:Invoke(player, reward or 5, "Quest Completion", name) -- experience, reason, quest name
				end
			end

			local serialized = bufferencoder.write(q :: any)

			report_progress_server:Invoke(player, serialized)

			break
		end
	end
end)

return module
