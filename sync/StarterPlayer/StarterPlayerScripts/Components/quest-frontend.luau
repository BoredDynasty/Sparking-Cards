--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local future = require(ReplicatedStorage.Packages.future)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])
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

	local completed_label = quest_frame.Completed
	local uncompleted_label = quest_frame.Uncompleted

	completed_label.Value.Text = "0"
	uncompleted_label.Value.Text = "0"

	task.spawn(function()
		local counter = text_counter.new(completed_label.Value, completed, 3)
		counter:Start(counter)
	end)
	task.spawn(function()
		local counter = text_counter.new(uncompleted_label.Value, incomplete, 3)
		counter:Start(counter)
	end)
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

	local title_str = '%s<br/><font weight="Regular"><font transparency="0.5">%s</font></font>'
	local acquired_str =
		'<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">clock</font> Acquired %s'

	local holder = quest_frame.Holder

	module:Unload()

	for i, quest in ipairs(player_quests) do
		-- get the quest data from the server idk

		print(tablekit.ToString(quest :: any))

		local card = pool:Get()
		card.Parent = holder

		task.spawn(function()
			while card ~= nil do
				task.wait(1)

				player_quests = get_quest_data:InvokeServer() :: { typemarshaller.Quest }
				if not player_quests then
					warn("couldnt pull player quests.")

					return
				end

				quest = player_quests[i]

				local title = card:WaitForChild("Title")
				local description = card:WaitForChild("Description")

				title.Text = string.format(title_str, quest.name, math.ceil(quest.progress) .. "%")

				local date = DateTime.fromUnixTimestampMillis(quest.date_acquired)

				local local_time = date:FormatLocalTime("MMM D, YYYY", "en-us") or "(unknown)"

				description.Text = string.format(acquired_str, local_time)
			end
		end)

		if quest.completed then
			card.Cancel.Visible = false -- we'll do something with this later
		end

		card.Cancel.Activated:Connect(function()
			-- this doesnt work yet.

			pop(card.Cancel)
			audio:PlayVariation("wood-block", 2)
		end)

		shadow(card)
	end
end

function module:BeginTracking()
	local player_quests = get_quest_data:InvokeServer() :: { typemarshaller.Quest }
	if not player_quests then
		warn("couldnt pull player quests.")

		return
	end

	for i, quest in ipairs(player_quests) do
		local quest_module_name = quest.module

		if not quest_module_name then
			continue
		end

		local directory = ReplicatedStorage.ClientModules["quest-modules"]
		local quest_module = directory:FindFirstChild(quest_module_name) :: ModuleScript?
		if not quest_module then
			continue
		end

		local ok, fn = future.Try(require, quest_module):Unwrap()
		if not ok then
			print(ok, fn)
			continue
		end

		print(type(fn))
		fn(player)

		print("begun tracking: ", quest.name)
	end

	local snackbar = hint.new()
	snackbar:SetText("Begun tracking quests")
	snackbar:SetExpiry(2)
	snackbar:SetCanClick(false)
	snackbar:SetCanDismiss(true)
end

module:BeginTracking()

return module
