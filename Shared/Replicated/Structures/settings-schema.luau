--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

export type SettingDefinition = typemarshaller.SettingDefinition

--[=[
	@within SettingsSchema
	@prop list {SettingDefinition}
	A deterministic settings list used by both the client and server.
]=]
local list: { SettingDefinition } = {
	{
		identifier = "background_music",
		name = "Background Music",
		details = "Toggle the background music on or off.",
		value_type = "boolean",
		control_type = "toggle",
		default = true,
	},
	{
		identifier = "gui_sound",
		name = "GUI Sound Effects",
		details = "Toggle the sound effects for GUI interactions on or off.",
		value_type = "boolean",
		control_type = "toggle",
		default = true,
	},
	{
		identifier = "background_music_volume",
		name = "Background Music Volume",
		details = "Adjust the volume of background music.",
		value_type = "number",
		control_type = "slider",
		default = 1,
		min = 0,
		max = 1,
		step = 0.01,
	},
	{
		identifier = "fov",
		name = "Field of View",
		details = "Adjust your camera field of view.",
		value_type = "number",
		control_type = "slider",
		default = 70,
		min = 60,
		max = 100,
		step = 1,
	},
	{
		identifier = "show_damage_numbers",
		name = "Damage Numbers",
		details = "Show floating damage numbers during combat.",
		value_type = "boolean",
		control_type = "checkbox",
		default = true,
	},
	{
		identifier = "movement_mode",
		name = "Movement Mode",
		details = "Pick between your preferred movement behavior.",
		value_type = "string",
		control_type = "dropdown",
		default = "classic",
		choices = {
			{ label = "Classic", value = "classic" },
			{ label = "Strafe", value = "strafe" },
			{ label = "Tank", value = "tank" },
		},
	},
	{
		identifier = "dash_keybind",
		name = "Dash Keybind",
		details = "Select the key used to dash.",
		value_type = "number",
		control_type = "keybind",
		default = Enum.KeyCode.LeftShift.Value,
		choices = {
			{ label = "Left Shift", value = Enum.KeyCode.LeftShift.Value },
			{ label = "Q", value = Enum.KeyCode.Q.Value },
			{ label = "F", value = Enum.KeyCode.F.Value },
			{ label = "Mouse Button 4", value = Enum.UserInputType.MouseButton4.Value },
		},
	},
}

--[=[
	@within SettingsSchema
	@prop map {[string]: SettingDefinition}
	
	Fast lookup table by setting identifier.
]=]
local map = {} :: { [string]: SettingDefinition }

for _, definition in ipairs(list) do
	map[definition.identifier] = definition
end

return table.freeze({
	list = list,
	map = map,
})
