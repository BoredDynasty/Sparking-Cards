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
local switch = require(StarterPlayer.StarterPlayerScripts.Components.switch)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local tooltip = require(StarterPlayer.StarterPlayerScripts.Components.tooltip)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- options.luau
-- only supports toggling options on and off.

local module = {
	tracked = {} :: { Option },
	limit = ratelimit(2, 0.5),
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

local templates = ReplicatedStorage.Interfaces

local events = ReplicatedStorage.Events
local get_profile = events.GetProfile
local save_setting = events.SaveSetting

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

function module:Get(name: string): Option?
	for i, option in ipairs(module.tracked) do
		if string.lower(name) == string.lower(option.name) then
			return option
		end
	end

	return nil
end

function module:Unload()
	local holder = optionsFrame.Holder

	-- cleanup existing
	for i, object in ipairs(holder:GetChildren()) do
		if object:IsA("Frame") then
			object:Destroy()
		end
	end
end

function module:LoadItems()
	local holder = optionsFrame.Holder

	module:Unload()

	-- render
	for i, option in ipairs(module.tracked) do
		local option_template = pool:Get()

		local text_display = option_template:FindFirstChild("TextDisplay", true) :: TextLabel
		local toggle_btn = option_template:FindFirstChild("Toggle", true) :: TextButton
		local btn_icon = option_template:FindFirstChild("Icon", true) :: ImageLabel

		local callbacks = option.callbacks :: { [string]: (...unknown) -> () }
		local icon_data = option.icons
		local value = option.value

		local fancy = [[
		<b>%s</b><br/>%s
		]]

		text_display.Text = string.format(fancy :: any, option.name, option.details)

		toggle_btn.Visible = false

		--tooltip.register(toggle_btn, booleanToString(value:Get()))
		value.Changed:Connect(function(new)
			tooltip.new(toggle_btn, booleanToString(new))
		end)

		local switch_ = switch.new()
		switch_:BindToGui(option_template)
		switch_.switch.Position = UDim2.fromScale(0.975, 0.5)
		switch_:SetScale(2)
		if type(value:Get()) == "boolean" then
			switch_:Toggle()
		end

		switch_.Changed:Connect(function(state)
			value:Set(state)

			local str_state = booleanToString(state)

			local next_callback = callbacks[str_state]
			if next_callback then
				task.spawn(future.new, next_callback)

				if type(value:Get()) == "boolean" then
					save_setting:InvokeServer(option.name, value:Get())
				end
			end
		end)

		option_template.Destroying:Connect(function(...)
			switch_:Destroy()
		end)

		option_template.Parent = holder
	end
end

function module:Clear()
	table.clear(module.tracked)
end

return module
