--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local stores = require(ReplicatedStorage.Datastore.stores)

local quest_module = {}
quest_module.ClassName = "quest_module"

--[=[
	@class quest
	@server

	A quest that can be given to a player.
]=]
export type quest = {
	name: string,
	description: string,
	inquirer_img: string | Instance,
	progress: number,
	goal: number,
	date_acquired: number,
	date_completed: number?,
	module: string,
	completed: boolean,
}

--[=[
	@type module_run (player: playerMarshaller.player) -> number
	@server

	The function that is ran by the quest tracker module. It should return the current progress value.
]=]
type module_run = (player: playerMarshaller.player) -> number

local Trackers = script:WaitForChild("Trackers")
local tracker_modules: { [string]: { run: module_run } } = {}

for _, module in ipairs(Trackers:GetChildren()) do
	if module:IsA("ModuleScript") then
		tracker_modules[module.Name] = require(module)
	end
end

quest_module.registered = {
	{
		name = "Take a hike",
		description = "Walk 200m",
		inquirer_img = "",
		progress = 0,
		goal = 200,
		date_acquired = 0,
		date_completed = nil,
		module = "walk",
		completed = false,
	},
} :: { quest }

--[=[
	@function _getFromName
	@private
	@param name string -- The name of the quest to get.
	@return quest? -- The quest object if found.

	Gets a quest from the registered quests list by its name.
]=]
function quest_module._getFromName(name: string): quest?
	for _, questData in ipairs(quest_module.registered) do
		if questData.name == name then
			return questData
		end
	end
	return nil
end

--[=[
	@function Get
	@param player playerMarshaller.player -- The player to get the quest data from.
	@param questName string? -- The name of the quest to get.
	@return quest | {quest}? -- The quest object if a name is provided, otherwise a table of all quests.

	Gets a player's quest data.
]=]
function quest_module:Get(player: playerMarshaller.player, questName: string?): any
	local data = stores.get(player)
	if not data then
		return nil
	end

	if questName then
		for _, quest in ipairs(data.Data.quests) do
			if quest.name == questName then
				return quest
			end
		end
		return nil
	else
		return data.Data.quests
	end
end

--[=[
	@function new
	@param player playerMarshaller.player -- The player to give the quest to.
	@param questName string -- The name of the quest to give.
	@return promise

	Gives a player a new quest.
]=]
function quest_module.new(player: playerMarshaller.player, questName: string)
	local questData = quest_module._getFromName(questName)
	if not questData then
		warn(`Quest "{questName}" not found.`)
		return promise.reject()
	end

	local data = stores.get(player)
	if not data then
		warn("Player data not found.")
		return promise.reject()
	end

	for _, pQuest in ipairs(data.Data.quests) do
		if pQuest.name == questName then
			warn(`Player already has quest "{questName}".`)
			return promise.reject()
		end
	end

	local newQuestData = table.clone(questData)
	newQuestData.date_acquired = os.time()

	return stores:addQuest(player, newQuestData)
end

--[=[
	@function init

	Initializes the quest progression loop.
]=]
function quest_module.init()
	task.spawn(function()
		while task.wait(0.25) do
			for _, player in ipairs(Players:GetPlayers()) do
				local p = playerMarshaller.new(player)
				local data = stores.get(p)

				if data and data.Data.quests then
					local quests = data.Data.quests
					local updated = false

					for i, quest in ipairs(quests) do
						if not quest.completed then
							local tracker = tracker_modules[quest.module]
							if tracker then
								local progress = tracker.run(p)
								if progress > 0 then
									quest.progress += progress
									updated = true
								end

								if quest.progress >= quest.goal and not quest.completed then
									quest.completed = true
									quest.date_completed = os.time()
									updated = true
								end
							end
						end
					end

					if updated then
						stores:update(p, { quests = quests })
					end
				end
			end
		end
	end)
end

return quest_module