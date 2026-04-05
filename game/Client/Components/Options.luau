--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

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
	select: ((string) -> ())?,
	rebind: ((number) -> ())?,
}

type SettingUiDefinition = {
	identifier: typemarshaller.SettingId,
	name: string,
	details: string,
	value_type: typemarshaller.SettingType,
	control_type: typemarshaller.SettingControlType?,
	default: typemarshaller.SettingValue,
	min: number?,
	max: number?,
	step: number?,
	choices: { typemarshaller.SettingChoice }?,
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
	control_type: typemarshaller.SettingControlType,
	default: typemarshaller.SettingValue,
	min: number?,
	max: number?,
	step: number?,
	choices: { typemarshaller.SettingChoice }?,
	callbacks: SettingCallbacks?,
	icons: {
		on: string,
		off: string,
	}?,
	value: observer.Observer<typemarshaller.SettingValue>,
}

-- options.luau
-- supports toggle, slider, checkbox, dropdown, and keybind settings.

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
	local choices = option.choices

	local function value_in_choices(candidate: typemarshaller.SettingValue): boolean
		if choices == nil then
			return true
		end

		for _, choice in ipairs(choices) do
			if choice.value == candidate then
				return true
			end
		end

		return false
	end

	if option.value_type == "boolean" then
		if type(value) ~= "boolean" then
			return option.default :: boolean
		end

		if not value_in_choices(value) then
			return option.default
		end

		return value
	end

	if option.value_type == "string" then
		if type(value) ~= "string" then
			return option.default :: string
		end

		if not value_in_choices(value) then
			return option.default
		end

		return value
	end

	if type(value) ~= "number" then
		return normalize_number(option, option.default :: number)
	end

	if value ~= value then
		return normalize_number(option, option.default :: number)
	end

	local normalized = normalize_number(option, value)
	if not value_in_choices(normalized) then
		return option.default
	end

	return normalized
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

local function format_keybind(value: number): string
	local key_code = Enum.KeyCode:FromValue(value)
	if key_code ~= nil then
		return key_code.Name
	end

	local input_type = Enum.UserInputType:FromValue(value)
	if input_type ~= nil then
		return input_type.Name
	end

	return tostring(value)
end

local function format_option_text(option: Option, value: typemarshaller.SettingValue): string
	local details = option.details or ""
	local header = `<b>{option.name}</b><br/>`

	if option.value_type == "number" then
		local numeric_value = value :: number
		local formatted_value = format_number(numeric_value, option.step)
		if option.control_type == "keybind" then
			formatted_value = format_keybind(numeric_value)
		end
		return header
			.. details
			.. ` <font transparency="0.25">({formatted_value})</font>`
	end

	if option.value_type == "string" then
		local string_value = value :: string
		local label = string_value
		local choices = option.choices

		if choices then
			for _, choice in ipairs(choices) do
				if choice.value == string_value then
					label = choice.label
					break
				end
			end
		end

		return header .. details .. ` <font transparency="0.25">({label})</font>`
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
		return
	end

	if option.value_type == "number" then
		local numeric_value = value :: number
		if callbacks.change then
			task.spawn(future.new, callbacks.change, numeric_value)
		end
		if option.control_type == "keybind" and callbacks.rebind then
			task.spawn(future.new, callbacks.rebind, numeric_value)
		end
		return
	end

	local string_value = value :: string
	if callbacks.select then
		task.spawn(future.new, callbacks.select, string_value)
	end
end

local function get_control_type(option: Option): typemarshaller.SettingControlType
	if option.control_type ~= nil then
		return option.control_type
	end

	if option.value_type == "number" then
		return "slider"
	end

	return "toggle"
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

local function render_checkbox(
	option: Option,
	toggle_btn: TextButton,
	slider_frame: Frame,
	text_display: TextLabel
)
	slider_frame.Visible = false
	toggle_btn.Visible = true

	local function sync_button()
		local enabled = option.value:Get() :: boolean
		local symbol = if enabled then "☑" else "☐"
		text_display.Text = format_option_text(option, enabled) .. ` <font transparency="0.15">{symbol}</font>`
	end

	sync_button()

	toggle_btn.Activated:Connect(function()
		local next_value = not (option.value:Get() :: boolean)
		option.value:Set(next_value)
		run_callback(option, next_value)
		save_setting_to_server(option, next_value, true)
		sync_button()
	end)

	option.value.Changed:Connect(sync_button)
end

local function get_choice_label(option: Option, value: typemarshaller.SettingValue): string
	local choices = option.choices
	if choices == nil then
		return tostring(value)
	end

	for _, choice in ipairs(choices) do
		if choice.value == value then
			return choice.label
		end
	end

	return tostring(value)
end

local function render_dropdown(
	option: Option,
	toggle_btn: TextButton,
	slider_frame: Frame
)
	slider_frame.Visible = false
	toggle_btn.Visible = true

	local choices = option.choices
	if choices == nil or #choices == 0 then
		toggle_btn.Text = "No Options"
		toggle_btn.Active = false
		return
	end

	local function find_choice_index(value: typemarshaller.SettingValue): number
		for i, choice in ipairs(choices) do
			if choice.value == value then
				return i
			end
		end

		return 1
	end

	local function sync_button()
		local current_value = option.value:Get()
		local label = get_choice_label(option, current_value)
		toggle_btn.Text = `Next: {label}`
	end

	sync_button()

	toggle_btn.Activated:Connect(function()
		local current_index = find_choice_index(option.value:Get())
		local next_index = current_index + 1
		if next_index > #choices then
			next_index = 1
		end

		local next_choice = choices[next_index]
		option.value:Set(next_choice.value)
		run_callback(option, next_choice.value)
		save_setting_to_server(option, next_choice.value, true)
		sync_button()
	end)

	option.value.Changed:Connect(sync_button)
end

local function render_keybind(
	option: Option,
	option_template: Frame,
	toggle_btn: TextButton,
	slider_frame: Frame
)
	slider_frame.Visible = false
	toggle_btn.Visible = true

	local is_listening = false
	local input_connection: RBXScriptConnection? = nil

	local function stop_listening()
		if input_connection then
			input_connection:Disconnect()
			input_connection = nil
		end
		is_listening = false
	end

	local function sync_button()
		local current_value = option.value:Get() :: number
		if is_listening then
			toggle_btn.Text = "Press any key..."
			return
		end
		toggle_btn.Text = `Rebind: {format_keybind(current_value)}`
	end

	sync_button()

	toggle_btn.Activated:Connect(function()
		if is_listening then
			stop_listening()
			sync_button()
			return
		end

		is_listening = true
		sync_button()

		input_connection = UserInputService.InputBegan:Connect(function(input, game_processed)
			if game_processed then
				return
			end

			local next_value = input.KeyCode.Value
			if input.KeyCode == Enum.KeyCode.Unknown then
				next_value = input.UserInputType.Value
			end

			local sanitized_value = sanitize_value(option, next_value)
			local numeric_value = sanitized_value :: number
			option.value:Set(numeric_value)
			run_callback(option, numeric_value)
			save_setting_to_server(option, numeric_value, true)

			stop_listening()
			sync_button()
		end)
	end)

	option_template.Destroying:Connect(function()
		stop_listening()
	end)

	option.value.Changed:Connect(sync_button)
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
			control_type = definition.control_type or (if definition.value_type == "number" then "slider" else "toggle"),
			default = definition.default,
			min = definition.min,
			max = definition.max,
			step = definition.step,
			choices = definition.choices,
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

		local control_type = get_control_type(option)

		if control_type == "toggle" then
			render_boolean(option, option_template, toggle_btn, slider_frame)
		elseif control_type == "slider" then
			render_number(option, option_template, toggle_btn, slider_frame)
		elseif control_type == "checkbox" then
			render_checkbox(option, toggle_btn, slider_frame, text_display)
		elseif control_type == "dropdown" then
			render_dropdown(option, toggle_btn, slider_frame)
		elseif control_type == "keybind" then
			render_keybind(option, option_template, toggle_btn, slider_frame)
		else
			render_boolean(option, option_template, toggle_btn, slider_frame)
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
