--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local future = require(ReplicatedStorage.Packages.future)
local leventine = require(ReplicatedStorage.Utility.leventine)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require("../Interface/pop")
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local retryer = require(ReplicatedStorage.Utility.retryer)
local settings_data = require(ReplicatedStorage.Structures["settings-data"])
local shadow = require("../Interface/shadow")
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- options.luau
-- only supports toggling options on and off.

local module = {
	tracked = {} :: { Option },
	limit = ratelimit(1, 0.5),
}
export type OptionCallbacks = {
	on: (...unknown) -> ...unknown,
	off: (...unknown) -> ...unknown,
}

type Icons = {
	[string]: typemarshaller.LucideIcon,
}

export type Option = {
	name: string,
	details: string?,
	callbacks: OptionCallbacks,
	icons: Icons?,
	value: observer.Observer<any>,
}

local player = Players.LocalPlayer
local player_gui = player.PlayerGui

local optionsGui = player_gui.Options
local optionsCanvas = optionsGui.CanvasGroup
local optionsFrame = optionsCanvas.Frame

local templates = ReplicatedStorage.Interfaces.Settings

local events = ReplicatedStorage.Events
local get_profile = events.GetProfile

shadow(templates.OptionTemplate.Toggle)
shadow(optionsFrame)

local pool = PoolerPlus:CreatePool("OptionsPool", function()
	return templates.OptionTemplate:Clone()
end)

pool:AdaptivePreload()

local last_check: number = 0.0
local check_interval = 5

-- unfortunately,
-- i will have to figure out just HOW
-- to implement such.
-- hint: use RbxGuiLib by EgoMoose.
local unsupported_types = {
	"number",
}

local function insertData(profile: typemarshaller.Profile)
	for i, saved_option in pairs(profile.Data.options) do
		-- remove this code block once we figure more out.
		if table.find(unsupported_types, type(saved_option)) then
			continue
		end

		local all_option_names = {}

		for j, option_data in ipairs(settings_data) do
			table.insert(all_option_names, option_data.name)
		end

		for j, option_data in ipairs(settings_data) do
			local str = leventine.closest(i, all_option_names)

			local is_similar = str == option_data.name

			if i == option_data.identifier or is_similar then
				local data = {}

				data.value = observer.new(saved_option or option_data.default)
				data.icons = {}

				data.icons.on = lucide.GetAsset(option_data.icons.on)
				data.icons.off = lucide.GetAsset(option_data.icons.off)

				data.callbacks = option_data.callbacks
				data.details = option_data.details
				data.name = option_data.name

				table.insert(module.tracked, data)
			end
		end
	end
end

RunService.Heartbeat:Connect(function(dt)
	-- requires 300 "heartbeats" to run this.

	last_check += dt

	if last_check < check_interval then
		return
	end

	last_check = 0

	local profile = fetchProfile()

	if not profile then
		return
	end

	module:Clear()

	future.Try(insertData, profile)
end)

local function booleanToString(boolean: boolean): "on" | "off"
	if boolean then
		return "on"
	else
		return "off"
	end
end

local function updateIcon(btn_icon: ImageLabel, boolean_state: boolean, icon_data: Icons)
	assert(typeof(boolean_state) == "boolean", "State is not a boolean: " .. typeof(boolean_state))

	local current_icon = select(
		2,
		future
			.Try(function()
				local str = booleanToString(boolean_state)

				return icon_data[str]
			end)
			:Unwrap()
	)

	assert(current_icon, "Could not fetch icon from data table: " .. tablekit.ToString(icon_data :: any))

	task.spawn(function()
		btn_icon.ImageContent = select(2, future.Try(Content.fromAssetId, current_icon.Id):Await())
		btn_icon.ImageRectOffset = current_icon.ImageRectOffset
		btn_icon.ImageRectSize = current_icon.ImageRectSize
	end)

	return true
end

function module:Get(name: string): Option?
	for i, option in ipairs(module.tracked) do
		if string.lower(name) == string.lower(option.name) then
			return option
		end
	end

	return nil
end

function module:Render()
	local holder = optionsFrame.Holder

	-- cleanup existing
	for i, object in ipairs(holder:GetChildren()) do
		if object:IsA("Frame") then
			object:Destroy()
		end
	end

	-- render
	for i, option in ipairs(module.tracked) do
		local option_template = pool:Get()

		local text_display = option_template:FindFirstChild("TextDisplay", true) :: TextLabel
		local toggle_btn = option_template:FindFirstChild("Toggle", true) :: TextButton
		local btn_icon = option_template:FindFirstChild("Icon", true) :: ImageLabel

		local callbacks = option.callbacks :: { [string]: (...unknown) -> () }
		local icon_data = option.icons
		local value = option.value

		assert(icon_data, "Where is the icon data?: " .. tablekit.ToString(option :: any))

		if type(value:Get()) == "boolean" then
			future.new(updateIcon, btn_icon, value:Get(), icon_data)
		end

		local fancy = [[
		<b>%s</b><br/>%s
		]]

		text_display.Text = string.format(fancy :: any, option.name, option.details)

		toggle_btn.Visible = true

		toggle_btn.Activated:Connect(function()
			if module.limit(option.name) then
				return
			end

			pop(toggle_btn)

			value:Map(function(current)
				return not current
			end)

			local boolean_state = value:Get()
			local str_state = booleanToString(boolean_state)

			local next_callback = callbacks[str_state]
			if next_callback then
				task.spawn(future.new, next_callback)

				if type(value:Get()) == "boolean" then
					future.new(updateIcon, btn_icon, value:Get(), icon_data)
				end
			end
		end)

		option_template.Parent = holder
	end
end

function module:Clear()
	return future.new(table.clear, module.tracked)
end

return module
