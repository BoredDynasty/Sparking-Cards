--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local markdown = require(script.Parent.markdown)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- dialogue.luau

type dialogGui = ScreenGui & {
	CanvasGroup: CanvasGroup & {
		Frame: Frame & {
			TextLabel: TextLabel,
		},
	},
}

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local character = characterMarshaller.get(player)

local dialogGui = playerGui:WaitForChild("Dialog") :: dialogGui

local state = observer.new(false)

local module = {}

function module.new(npc: characterMarshaller.Character, lexicon: string?)
	local self = setmetatable({}, module)

	self.npc = npc
	self.lexicon = lexicon
	self.prompt = nil -- TODO) make a custom prompt
end
