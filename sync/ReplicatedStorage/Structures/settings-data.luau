--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local settings_schema = require(ReplicatedStorage.Structures["settings-schema"])
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- settings-data.luau
-- should be used on the client for UI concerns.

export type SettingCallbacks = {
	on: ((boolean) -> ())?,
	off: ((boolean) -> ())?,
	change: ((number) -> ())?,
}

export type SettingUiDefinition = typemarshaller.SettingDefinition & {
	callbacks: SettingCallbacks?,
	icons: {
		on: string,
		off: string,
	}?,
}

local callbacks_by_identifier: { [typemarshaller.SettingId]: SettingCallbacks } = {
	background_music = {
		on = function()
			-- Utility for later:
			-- Create a dedicated music sound group and unmute it here.
		end,
		off = function()
			-- Utility for later:
			-- Create a dedicated music sound group and mute it here.
		end,
	},
	gui_sound = {
		on = function()
			print("GUI sound effects turned on.")
		end,
		off = function()
			print("GUI sound effects turned off.")
		end,
	},
	background_music_volume = {
		change = function(volume: number)
			-- Utility for later:
			-- Iterate music tracks from your music manager and set their volume to this value.
			local _ = volume
		end,
	},
	fov = {
		change = function(next_fov: number)
			local camera = workspace.CurrentCamera
			if camera then
				camera.FieldOfView = next_fov
			end
		end,
	},
}

local icons_by_identifier: { [typemarshaller.SettingId]: { on: string, off: string } } = {
	background_music = {
		on = "megaphone",
		off = "megaphone-off",
	},
	gui_sound = {
		on = "volume-2",
		off = "volume-x",
	},
	background_music_volume = {
		on = "music-4",
		off = "music-2",
	},
	fov = {
		on = "scan-eye",
		off = "scan-eye",
	},
}

local ui_settings = {} :: { SettingUiDefinition }

for _, definition in ipairs(settings_schema.list) do
	local entry = {
		identifier = definition.identifier,
		name = definition.name,
		details = definition.details,
		value_type = definition.value_type,
		default = definition.default,
		min = definition.min,
		max = definition.max,
		step = definition.step,
		callbacks = callbacks_by_identifier[definition.identifier],
		icons = icons_by_identifier[definition.identifier],
	} :: SettingUiDefinition

	table.insert(ui_settings, entry)
end

return ui_settings
