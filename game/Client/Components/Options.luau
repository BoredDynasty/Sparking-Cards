--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local fetch_profile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local settings_data = require(ReplicatedStorage.Structures["settings-data"])
local shadow = require("../Interface/shadow")
local slider = require(StarterPlayer.StarterPlayerScripts.Classes.slider)
local switch = require(StarterPlayer.StarterPlayerScripts.Components.switch)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

type SettingCallbacks = {
	on: ((boolean) -> ())?,
	off: ((boolean) -> ())?,
	change: ((number) -> ())?,
}

type SettingUiDefinition = {
	identifier: typemarshaller.SettingId,
	name: string,
	details: string,
	value_type: typemarshaller.SettingType,
	default: typemarshaller.SettingValue,
	min: number?,
	max: number?,
	step: number?,
	callbacks: SettingCallbacks?,
	icons: {
		on: string,
		off: string,
	}?,
}

type Option = {
	identifier: string,
	name: string,
	details: string?,
	value_type: typemarshaller.SettingType,
	default: typemarshaller.SettingValue,
	min: number?,
	max: number?,
	step: number?,
	callbacks: SettingCallbacks?,
	icons: {
		on: string,
		off: string,
	}?,
	value: observer.Observer<typemarshaller.SettingValue>,
}

-- options.luau
-- supports boolean and number settings.

-- TODO: allow for dropdown support, checkboxes, and keybinds in the future. for now this is just a simple slider and toggle system.
-- e.g keybinds are a bit more complex since we need to listen for the next key input after clicking the bind button,
-- and we also need to handle mouse buttons and possibly controller buttons in the future.

local module = {
	tracked = {} :: { Option },
	limit = ratelimit(8, 0.33),
}

local player = Players.LocalPlayer
local player_gui = player.PlayerGui

local options_gui = player_gui.Options
local options_canvas = options_gui.CanvasGroup
local options_frame = options_canvas.Frame

local templates = ReplicatedStorage.Interfaces

local events = ReplicatedStorage.Events
local save_setting = events:FindFirstChild("SaveSetting")

shadow(templates.OptionTemplate.Toggle)
shadow(options_frame)

local pool = PoolerPlus:CreatePool("OptionsPool", function()
	return templates.OptionTemplate:Clone()
end)

pool:AdaptivePreload()

local function round_to_step(value: number, step: number?): number
	if step == nil or step <= 0 then
		return value
	end

	return math.round(value / step) * step
end

local function normalize_number(option: Option, value: number): number
	local min_value = option.min
	local max_value = option.max

	if min_value ~= nil and max_value ~= nil and max_value < min_value then
		min_value, max_value = max_value, min_value
	end

	if min_value ~= nil then
		value = math.max(value, min_value)
	end

	if max_value ~= nil then
		value = math.min(value, max_value)
	end

	value = round_to_step(value, option.step)

	if min_value ~= nil then
		value = math.max(value, min_value)
	end

	if max_value ~= nil then
		value = math.min(value, max_value)
	end

	return value
end

local function sanitize_value(option: Option, value: any): typemarshaller.SettingValue
	if option.value_type == "boolean" then
		if type(value) ~= "boolean" then
			return option.default :: boolean
		end

		return value
	end

	if type(value) ~= "number" then
		return normalize_number(option, option.default :: number)
	end

	if value ~= value then
		return normalize_number(option, option.default :: number)
	end

	return normalize_number(option, value)
end

local function format_number(value: number, step: number?): string
	if step ~= nil and step >= 1 then
		return tostring(math.round(value))
	end

	local formatted = string.format("%.2f", value)
	formatted = formatted:gsub("0+$", "")
	formatted = formatted:gsub("%.$", "")

	return formatted
end

local function format_option_text(option: Option, value: typemarshaller.SettingValue): string
	local details = option.details or ""
	local header = `<b>{option.name}</b><br/>`

	if option.value_type == "number" then
		local numeric_value = value :: number
		return header
			.. details
			.. ` <font transparency="0.25">({format_number(numeric_value, option.step)})</font>`
	end

	return header .. details
end

local function run_callback(option: Option, value: typemarshaller.SettingValue)
	local callbacks = option.callbacks
	if callbacks == nil then
		return
	end

	if option.value_type == "boolean" then
		local state = value :: boolean
		local next_callback = if state then callbacks.on else callbacks.off

		if next_callback then
			task.spawn(future.new, next_callback, state)
		end
	else
		local numeric_value = value :: number
		local next_callback = callbacks.change
		if next_callback then
			task.spawn(future.new, next_callback, numeric_value)
		end
	end
end

local function save_setting_to_server(option: Option, value: typemarshaller.SettingValue, force: boolean?)
	if not save_setting or not save_setting:IsA("RemoteFunction") then
		return
	end

	if not force and not module.limit(option.identifier) then
		return
	end

	task.spawn(function()
		future.Try(function()
			save_setting:InvokeServer(option.identifier, value)
		end)
	end)
end

local function get_number_bounds(option: Option): (number, number)
	local min_value = option.min or 0
	local max_value = option.max or 1

	if max_value <= min_value then
		max_value = min_value + 1
	end

	return min_value, max_value
end

local function render_boolean(
	option: Option,
	option_template: Frame,
	toggle_btn: TextButton,
	slider_frame: Frame
)
	toggle_btn.Visible = false
	slider_frame.Visible = false

	local switch_ = switch.new()
	switch_:BindToGui(option_template)
	switch_.switch.Position = UDim2.fromScale(0.975, 0.5)
	switch_:SetScale(2)

	local current_value = option.value:Get() :: boolean

	if current_value then
		switch_:Toggle()
	end

	switch_.Changed:Connect(function(state)
		option.value:Set(state)
		run_callback(option, state)
		save_setting_to_server(option, state, true)
	end)

	option_template.Destroying:Connect(function()
		switch_:Destroy()
	end)
end

local function render_number(
	option: Option,
	option_template: Frame,
	toggle_btn: TextButton,
	slider_frame: Frame
)
	toggle_btn.Visible = false
	slider_frame.Visible = true

	local slider_control = slider.new(slider_frame, "x")
	slider_control.TweenClick = false

	local min_value, max_value = get_number_bounds(option)
	local range = max_value - min_value

	if option.step and option.step > 0 then
		slider_control.Interval = math.clamp(option.step / range, 0, 1)
	end

	local initial_value = option.value:Get() :: number
	local alpha = (initial_value - min_value) / range
	slider_control:Set(alpha, false)

	local function sync_slider(force_save: boolean?)
		local slider_alpha = slider_control:Get()
		local numeric_value = min_value + slider_alpha * range
		numeric_value = normalize_number(option, numeric_value)

		local current = option.value:Get() :: number
		if current ~= numeric_value then
			option.value:Set(numeric_value)
			run_callback(option, numeric_value)
		end

		save_setting_to_server(option, numeric_value, force_save)
	end

	slider_control.Changed:Connect(function()
		sync_slider(false)
	end)

	if slider_control.DragStop then
		slider_control.DragStop:Connect(function()
			sync_slider(true)
		end)
	end

	option_template.Destroying:Connect(function()
		slider_control:Destroy()
	end)
end

function module:Get(name: string): Option?
	local lowered_name = string.lower(name)
	for _, option in ipairs(module.tracked) do
		if lowered_name == string.lower(option.name) or lowered_name == string.lower(option.identifier) then
			return option
		end
	end

	return nil
end

function module:Unload()
	local holder = options_frame.Holder

	for _, object in ipairs(holder:GetChildren()) do
		if object:IsA("Frame") then
			object:Destroy()
		end
	end
end

function module:Clear()
	for _, option in ipairs(module.tracked) do
		option.value:Destroy()
	end

	table.clear(module.tracked)
end

function module:Hydrate(profile: typemarshaller.Profile?)
	module:Clear()

	local saved_options = {} :: { [string]: typemarshaller.SettingValue }

	if profile and profile.Data and type(profile.Data.options) == "table" then
		saved_options = profile.Data.options
	end

	for _, definition in ipairs(settings_data :: { SettingUiDefinition }) do
		local option = {
			identifier = definition.identifier,
			name = definition.name,
			details = definition.details,
			value_type = definition.value_type,
			default = definition.default,
			min = definition.min,
			max = definition.max,
			step = definition.step,
			callbacks = definition.callbacks,
			icons = definition.icons,
			value = observer.new(definition.default),
		} :: Option

		local saved_value = saved_options[option.identifier]
		option.value:Set(sanitize_value(option, saved_value))

		table.insert(module.tracked, option)
	end
end

function module:LoadItems()
	local holder = options_frame.Holder
	local profile = fetch_profile()

	module:Hydrate(profile)
	module:Unload()

	for _, option in ipairs(module.tracked) do
		local option_template = pool:Get()

		local text_display = option_template:FindFirstChild("TextDisplay", true)
		local toggle_btn = option_template:FindFirstChild("Toggle", true)
		local slider_frame = option_template:FindFirstChild("SliderFrame", true)

		if not text_display or not text_display:IsA("TextLabel") then
			option_template:Destroy()
			continue
		end

		if not toggle_btn or not toggle_btn:IsA("TextButton") then
			option_template:Destroy()
			continue
		end

		if not slider_frame or not slider_frame:IsA("Frame") then
			option_template:Destroy()
			continue
		end

		text_display.Text = format_option_text(option, option.value:Get())
		option.value.Changed:Connect(function(next_value)
			text_display.Text = format_option_text(option, next_value)
		end)

		if option.value_type == "boolean" then
			render_boolean(option, option_template, toggle_btn, slider_frame)
		else
			render_number(option, option_template, toggle_btn, slider_frame)
		end

		option_template.Parent = holder

		run_callback(option, option.value:Get())
	end
end

task.spawn(function()
	local profile = fetch_profile()
	module:Hydrate(profile)

	for _, option in ipairs(module.tracked) do
		run_callback(option, option.value:Get())
	end
end)

return module
