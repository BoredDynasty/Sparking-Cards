--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local markdown = require(script.Parent.markdown)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- dialogue.luau

local md = markdown.new("")
local typewriter = markdown.typewriter.new()

type dialogGui = ScreenGui & {
	CanvasGroup: CanvasGroup & {
		Frame: Frame & {
			TextLabel: TextLabel,
		},
	},
}

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local dialogGui = playerGui:WaitForChild("Dialog") :: dialogGui
--
