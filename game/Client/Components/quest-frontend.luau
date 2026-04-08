--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- quest-frontend.luau
-- a frontend for the quest system, should be ran on the client

local module = {}

local player = Players.LocalPlayer
local player_gui = player.PlayerGui

local quest_gui = player_gui.Objective
local quest_canvas = quest_gui.CanvasGroup
local quest_frame = quest_canvas.Frame

local events = ReplicatedStorage.Events

local get_quest_data = events.GetQuestData

shadow(quest_frame)

export type QuestInfo = {
	name: string,
	description: string?,
	progress: number,
	completed: boolean?,
	date_acquired: number,
	date_completed: number?,
}

local pool = PoolerPlus:CreatePool("ObjectivePool", function()
	return ReplicatedStorage.Interfaces.ObjectiveTemplate:Clone()
end)

pool:AdaptivePreload()

function module:DisplayCompletions()
	local player_quests = get_quest_data:InvokeServer() :: { typemarshaller.Quest }

	if not player_quests then
		warn("couldnt pull player quests.")

		return
	end

	local completed = 0
	local incomplete = 0
	for i, quest in ipairs(player_quests) do
		if quest.completed then
			completed += 1
		end
	end

	incomplete = #player_quests - completed

	print("completed quests: ", completed)
	print("incomplete quests: ", incomplete)

	quest_frame.Completed.Value.Text = tostring(completed)
	quest_frame.Uncompleted.Value.Text = tostring(incomplete)
end

function module:Unload()
	for i, object in ipairs(pool:GetActiveObjects()) do
		object:Destroy()
	end
end

function module:LoadItems()
	local player_quests = get_quest_data:InvokeServer() :: { typemarshaller.Quest }
	if not player_quests then
		warn("couldnt pull player quests.")

		return
	end

	print(tablekit.ToString(player_quests :: any))

	local title_str = '%s<br/><font weight="Regular"><font transparency="0.5">%s%</font></font>'
	local acquired_str =
		'<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">clock</font> Acquired %s'

	local holder = quest_frame.Holder

	module:Unload()

	for i, quest in ipairs(player_quests) do
		local card = pool:Get()
		card.Parent = holder

		card.Title.Text = string.format(title_str, quest.name, quest.progress)

		local deserialized_date_acquired = DateTime.fromUnixTimestampMillis(quest.date_acquired)
			:FormatLocalTime("MMM D, YYYY", "en-us") or "(unknown)"
		print(deserialized_date_acquired)

		card.Description.Text = string.format(acquired_str, deserialized_date_acquired)

		card.Cancel.Activated:Connect(function()
			-- this doesnt work yet.

			pop(card.Cancel)
			audio:PlayVariation("wood-block", 2)
		end)

		shadow(card)
	end
end

return module
