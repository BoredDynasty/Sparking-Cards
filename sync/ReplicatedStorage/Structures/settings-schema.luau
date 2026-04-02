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
		default = true,
	},
	{
		identifier = "gui_sound",
		name = "GUI Sound Effects",
		details = "Toggle the sound effects for GUI interactions on or off.",
		value_type = "boolean",
		default = true,
	},
	{
		identifier = "background_music_volume",
		name = "Background Music Volume",
		details = "Adjust the volume of background music.",
		value_type = "number",
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
		default = 70,
		min = 60,
		max = 100,
		step = 1,
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
