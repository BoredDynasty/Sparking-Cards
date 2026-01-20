--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packet = require(ReplicatedStorage.Packet)
local future = require(ReplicatedStorage.Packages.future)
local messagepack = require(ReplicatedStorage.Modules.Serialization.messagepack)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- quest.luau
-- should be ran on the client

local quest_module = {}

export type quest = {
	name: string,
	description: string,
	inquirer_img: number | Instance, -- img id or a model
	progress: number,
	date_acquired: number, -- unix timestamp millis
	date_completed: number?,
	completed: boolean?,
	module: ModuleScript?,
}

type module_run = (data: quest, Player) -> quest?

quest_module.registered = {
	{
		name = "Take a hike",
		description = "Walk 200m",
		inquirer = "",
		progress = 1,
		date_acquired = 0,
		data_completed = 0,
		module = script["take-a-hike"],
	},
} :: { quest }

function quest_module._getFromName(name: string)
	return future.new(function()
		for i, quest in ipairs(quest_module.registered) do
			if string.lower(quest.name) == string.lower(name) then
				return quest
			end
		end

		return nil
	end)
end

local getProfileRF = ReplicatedStorage.Events.GetProfile

local function expectProfile()
	local fut = future.new(function()
		return getProfileRF:InvokeServer()
	end)

	return fut:Await() :: typemarshaller.Profile
end

--[[
   Adds a new quest for the player

   @param player - The player given the quest
	@param name - The name of the quest

   ```luau
   quest_module.new(player, "take a hike")
	print("added new quest!"
   ```

]]
function quest_module.new(player: Player, name: string)
	-- manipulate player data

	-- check if the quest does not exist within player data first
	local data = expectProfile()
	if not data or not data.Data then
		return
	end

	local quest = quest_module._getFromName(name):Await()
	if not quest then
		warn("couldnt get quest. invalid quest name?")
		return
	end

	if table.find(data.Data.quests, quest) then
		print("already has quest")
		return
	end

	-- serialize it for the server
	local serialized = messagepack.encode(quest)
	print("serialized quest data: ", serialized)

	return Packet.AddQuest.send({
		player,
		questData = serialized,
	})
end

--[[
   Loops through all player quests and updates them.

   @param player - The player the quests should be tracked for.

	@return RBXScriptConnection
]]
function quest_module:Track(player: Player)
	local lastCheck: number = 0.0
	local checkInterval = 0.25 -- seconds

	local conn = nil :: RBXScriptConnection?

	conn = RunService.Heartbeat:Connect(function(deltaTime: number)
		debug.profilebegin("track-quests")

		lastCheck += deltaTime :: number
		if lastCheck < checkInterval then
			debug.profileend()

			return
		end

		lastCheck = 0.0

		local data = expectProfile()
		if not data or not data.Data then
			debug.profileend()

			return
		end

		-- loop through all quests and update
		for i, quest in ipairs(data.Data.quests :: { quest }) do
			local module = quest.module
			if not module then
				-- it takes too long to print:
				-- "we have to module to call!!"
				return
			end

			if quest.completed and quest.completed == true then
				return
			end

			local ok, result: module_run? = pcall(require, module)

			local quest_module = nil :: module_run?

			if ok and type(result) == "function" then
				quest_module = result
			else
				return
			end

			local new_data = quest_module(quest, player)
			if not new_data then
				-- something went wrong lmao
				return
			end

			if new_data.completed and new_data.completed == true then
				print("completed quest!")
			end

			data.Data[quest] = new_data

			task.wait(checkInterval)
			-- we cant be getting data, requiring and calling modules
			-- all in one loop at the same time
			-- we need to **optimize** it.
		end
	end)

	return conn
end

--[[
   Gets all player quests or a specific quest from the provided player.

   @param player - The player to get the quest(s) from.
   @param quest_name? - The optional specific quest to get.

   @yields

   @return `Promise<quest | {quest}>`

   ```luau
   local quest = quest_module:Get(player, "take a hike")
   :catch(print):andThen(function(quest_data: quest_module.quest)
      print("quest_data: ", table.unpack(quest_data))
   end)

   -- else

   local quest_list = quest_module:Get(player)
   :catch(warn)
   :andThen(function(list)
      print("quest_list: " .. table.unpack(list))
   end)
   ```
]]

function quest_module:Get(player: Player, quest_name: string?)
	return future.new(function()
		local data = expectProfile()
		if not data or not data.Data then
			return nil
		end

		if quest_name then
			local final = nil
			for i, quest_data in ipairs(data.Data.quests :: { quest }) do
				if string.lower(quest_data.name) == string.lower(quest_name) then
					final = quest_data
				end
			end

			return final
		else
			return data.Data.quests :: { quest }
		end
	end)
end

return quest_module
