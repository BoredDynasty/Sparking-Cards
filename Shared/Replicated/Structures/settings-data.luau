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
	select: ((string) -> ())?,
	rebind: ((number) -> ())?,
}

export type SettingUiDefinition = typemarshaller.SettingDefinition & {
	callbacks: SettingCallbacks?,
	icons: {
		on: string,
		off: string,
	}?,
}

local events = ReplicatedStorage.Events

local callbacks_by_identifier: { [typemarshaller.SettingId]: SettingCallbacks? } = {
	background_music = {
		on = function()
			print("Background music turned on.")
			events.ToggleMusic:FireServer(true)
		end,
		off = function()
			print("Background music turned off.")
			events.ToggleMusic:FireServer(false)
		end,
	},
	gui_sound = {
		on = function()
			print("GUI sound effects turned on.")
			events.ToggleGUISound:FireServer(true)
		end,
		off = function()
			print("GUI sound effects turned off.")
			events.ToggleGUISound:FireServer(false)
		end,
	},
	background_music_volume = {
		change = function(volume: number)
			events.SetMusicVolume:FireServer(volume)
			--- IGNORE ---
			-- This will trigger a client event that all clients listen to, which will update the volume of all music tracks accordingly.
			-- We have to do it this way because the music tracks are stored on the client, so the server can't directly update their volume.
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
	movement_mode = {
		select = function(mode: string)
			print(`Movement mode set to {mode}.`)
		end,
	},
	dash_keybind = {
		rebind = function(next_key_code: number)
			print(`Dash keybind updated to {next_key_code}.`)
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
		control_type = definition.control_type,
		choices = definition.choices,
		callbacks = callbacks_by_identifier[definition.identifier],
		icons = icons_by_identifier[definition.identifier],
	} :: SettingUiDefinition

	table.insert(ui_settings, entry)
end

return ui_settings
