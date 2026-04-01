--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local future = require(ReplicatedStorage.Packages.future)
local input_icons = require(StarterPlayer.StarterPlayerScripts.Interface["input-icons"])

-- keybindlink.luau

local module = {}
local tracking = {}

local pool = PoolerPlus:CreatePool("KeybindPool", function()
	return ReplicatedStorage.Interfaces.CombatButton:Clone()
end)

local player = Players.LocalPlayer
local player_gui = player.PlayerGui
local keybind_gui = player_gui.Keybindlink

--[[
   the key enum serialized into a number
]]
function module.register(key: number, name: string)
	local data = {
		key = key,
		button = pool:Get(),
		name = name,
	}

	local icons = input_icons.dark

	data.button.TextLabel.Text = name

	local enum_key = Enum.KeyCode:FromValue(key) or Enum.UserInputType:FromValue(key)

	assert(enum_key, "invalid value for keycode")
	print(enum_key, icons[enum_key])

	future
		.Try(function(...)
			data.button.ImageLabel.Image = icons[enum_key]
			return true
		end)
		:After(print)

	data.button.Parent = keybind_gui.CanvasGroup.Frame

	table.insert(tracking, data)
end

function module.unregister(name: string)
	for i, data in ipairs(tracking) do
		if data.name == name then
			data.button.Parent = nil

			pool:Return(data.button)

			table.remove(tracking, i)

			return
		end
	end
end

return module
