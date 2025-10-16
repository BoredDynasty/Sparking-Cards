--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local markdown = require(script.Parent.markdown)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- dialogue.luau

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

local state = observer.new(false)

local _trove = trove.new()
_trove:Add(state)
_trove:Add(typewriter)

local function speak(speaker: string, text: string)
	return promise.new(function(resolve: () -> ...unknown, reject: (string) -> ...unknown)
		if state:Get() or typewriter:IsPlaying() then
			reject("already speaking")
		end

		state:Set(true)

		spr.target(dialogGui.CanvasGroup.Frame, 1, 1, {
			Position = UDim2.fromScale(0.5, 0.9),
		})

		task.wait(1)

		local str = `{speaker}:<br/>{text}`

		typewriter:Play(dialogGui.CanvasGroup.Frame.TextLabel, str)

		resolve()
	end)
end

local function silence()
	return promise.new(function(resolve: () -> ...unknown)
		if typewriter:IsPlaying() then
			typewriter:Skip()
		end

		dialogGui.CanvasGroup.Frame.TextLabel.Text = ""

		state:Set(false)

		spr.target(dialogGui.CanvasGroup.Frame, 1, 1, {
			Position = UDim2.fromScale(0.5, 1.5),
		})

		resolve()
	end)
end

return {
	_trove = _trove,
	speak = speak,
	silence = silence,
}
