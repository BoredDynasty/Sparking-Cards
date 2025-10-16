--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Letterbox = require(script.Parent.Letterbox)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local custom_lighting = require(ReplicatedStorage.ClientModules["custom-lighting"])
local markdown = require(ReplicatedStorage.ClientModules.markdown)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local spr = require(ReplicatedStorage.Modules.spr)

-- display.luau

-- This module handles displaying text on the screen.

local display = {
	active = observer.new(false),
}

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local character = characterMarshaller.get(player)

local displayGui = playerGui:WaitForChild("Display") :: ScreenGui & {
	CanvasGroup: CanvasGroup & {
		Frame: Frame & {
			TextLabel: TextLabel,
		},
	},
}

function display.showText(str: string, duration: number?)
	if display.active:Get() then
		print("already visible")
		return
	end
	print("Displaying text:", str)
	-- Implementation to display text on screen for 'duration' seconds

	display.active:Set(true)

	local frame = displayGui.CanvasGroup.Frame
	local textLabel = displayGui.CanvasGroup.Frame.TextLabel

	-- slide in
	spr.target(frame, 0.8, 8, {
		Position = UDim2.fromScale(0.5, 0.5),
	})

	Letterbox:on()
	custom_lighting.blur()
	characterMarshaller.halt(character)

	local typewriter = markdown.typewriter.new()
	typewriter:Play(textLabel, str)

	local function closeDisplay()
		display.hideText()

		typewriter:Skip(typewriter)
		custom_lighting.unblur()
		Letterbox:off()
		characterMarshaller.continue(character)

		task.defer(typewriter.Destroy)
	end

	if duration then
		repeat
			task.wait()
		until not typewriter:IsPlaying()

		task.delay(duration, closeDisplay)
	else
		-- when clicked off the display, close
		local connection = nil
		connection = frame.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local mousePos = input.Position:Abs()
				local absPos = frame.AbsolutePosition
				local absSize = frame.AbsoluteSize
				if
					not (
						mousePos.X >= absPos.X
						and mousePos.X <= absPos.X + absSize.X
						and mousePos.Y >= absPos.Y
						and mousePos.Y <= absPos.Y + absSize.Y
					)
				then
					closeDisplay()
					if connection then
						connection:Disconnect()
					end
				end
			end
		end)
	end
end

function display.hideText()
	local frame = displayGui.CanvasGroup.Frame
	local textLabel = displayGui.CanvasGroup.Frame.TextLabel

	spr.target(frame, 0.8, 8, {
		Position = UDim2.fromScale(0.5, 0.5),
	})

	textLabel.Text = ""

	display.active:Set(false)
end

return display
