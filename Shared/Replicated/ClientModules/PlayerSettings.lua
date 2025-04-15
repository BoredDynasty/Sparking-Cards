--!strict

-- PlayerSettings.lua

--[[ 
    Module to alter and configure
    The Player settings UI

    Note: Runs on client side
--]]

local PlayerSettings = {}

export type PlayerSetting = typeof(setmetatable(
	{} :: {
		preset: { [string]: any },
		enabled: { [string]: true },
		disabled: { [string]: false },
		str: { [string]: string },
	},
	PlayerSettings
))

PlayerSettings.tableType = typeof(setmetatable(
	{} :: {
		preset: { [string]: any },
		enabled: { [string]: true },
		disabled: { [string]: false },
		str: { [string]: string },
	},
	PlayerSettings
))
PlayerSettings.__index = PlayerSettings

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Red = require(ReplicatedStorage.Packages.Red)

function PlayerSettings.new(preset: { [string]: any }): PlayerSetting
	local self = setmetatable({}, PlayerSettings)

	self.preset = preset
	self.enabled = {} :: { [string]: true }
	self.disabled = {} :: { [string]: false }
	self.str = {} :: { [string]: string }

	return self
end

local saveOptions = Red.Event("SaveOptions", function(args)
	return args
end):Client()

function PlayerSettings:send(args)
	saveOptions:Fire(args)
	print("sent setting data", args)
end

function PlayerSettings:Destroy()
	self.str = nil
	self.disabled = nil
	self.enabled = nil
	self.preset = nil
end

return PlayerSettings
