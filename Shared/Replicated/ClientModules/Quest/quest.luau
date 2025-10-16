--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local stores = require(ReplicatedStorage.Datastore.stores)

-- quest.luau

local quest_module = {}

export type quest = {
	name: string,
	description: string,
	inquirer_img: string | Instance, -- img id or a model
	progress: number,
	date_acquired: number, -- unix timestamp millis
	date_completed: number?,
	module: ModuleScript?,
}

type module_run = (data: quest, playerMarshaller.player) -> quest

quest_module.registered = {
	{
		name = "Take a hike",
		description = "Walk 200m",
		inquirer = "",
		progress = 1,
		date_acquired = 0,
		data_completed = 0,
	},
} :: { quest }

function quest_module._getFromName(name: string): quest?
	local value = nil

	for i, quest in ipairs(quest_module.registered) do
		if quest.name == name then
			value = quest
			break
		end
	end

	return value
end

function quest_module.new(player: playerMarshaller.player, quest: string)
	-- manipulate player data

	-- check if the quest does not exist within player data first
	local data = stores.get(player)

	if table.find(data.Data.quests, quest) then
		print("already has quest")

		return
	end

	return stores:addQuest(player, quest)
end

return quest_module
