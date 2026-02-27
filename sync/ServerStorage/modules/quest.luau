--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local leventine = require(ReplicatedStorage.Utility.leventine)
local registered = require(ServerStorage.modules.quest.registered)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- quest.luau
-- should be ran on the server

local module = {}

local events = ReplicatedStorage.Events

local get_progress = events.GetQuestProgress -- remote function
local send_progress = events.SendQuestProgress -- bindable function
local get_quest_data = events.GetQuestData

local get_profile = events.GetProfileServer

function module:GetRegistered(): { string }
	local list = table.create(#registered)

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

function module:StartTracking()
	local conn = nil

	local last_check: number = 0.0
	local check_interval = 2

	local registered_list = module:GetRegistered()

	conn = RunService.Heartbeat:Connect(function(dt)
		last_check += dt

		if last_check < check_interval then
			return
		end

		last_check = 0

		-- map a list of modules.
		-- [quest_name]: modulescript

		local map = {}
		for i, name in ipairs(registered_list) do
			local quest_module = module:GetModuleFromName(name)

			map[name] = quest_module
		end

		--  invoke the client

		for i, player in ipairs(Players:GetPlayers()) do
			if not player.Parent then
				continue
			end

			local progress = get_progress:InvokeClient(player, {
				list = registered_list,
				map = map,
			})

			send_progress:Invoke(progress)
		end
	end)
end

get_quest_data.OnServerInvoke = function(player: Player): { typemarshaller.Quest }?
	local profile = get_profile:Invoke(player) :: typemarshaller.ProfileData

	if not profile then
		return nil
	end

	-- give the player all their quest data.

	local quest_data = profile.quests

	return quest_data
end

return module
