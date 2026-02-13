--!strict

-- settings-data.luau
-- should be used on the client

return {
	{
		name = "Background Music",
		details = "Toggle the background music on or off.",
		callbacks = {
			on = function()
				print("Background music turned on.")
			end,
			off = function()
				print("Background music turned off.")
			end,
		},
		icons = {
			on = "megaphone",
			off = "megaphone-off",
		},
		identifier = "background_music",
		default = true,
	},
	{
		name = "GUI Sound Effects",
		details = "Toggle the sound effects for GUI interactions on or off.",
		callbacks = {
			on = function()
				print("GUI sound effects turned on.")
			end,
			off = function()
				print("GUI sound effects turned off.")
			end,
		},
		icons = {
			on = "volume-2",
			off = "volume-x",
		},
		identifier = "gui_sound",
		default = true,
	},
}
