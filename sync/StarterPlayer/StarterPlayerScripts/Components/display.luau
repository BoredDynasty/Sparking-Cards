--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)

local custom_lighting = require(ReplicatedStorage.ClientModules["custom-lighting"])
local hover = require(StarterPlayer.StarterPlayerScripts.Interface.hover)
local markdown = require(ReplicatedStorage.ClientModules.markdown)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)

-- display.luau

-- This module handles displaying text on the screen.

local display = {
	active = observer.new(false),
}

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local character = player.Character or player.CharacterAdded:Wait()

local displayGui = playerGui.Display

shadow(displayGui.CanvasGroup.Frame)

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

	local gradient = Instance.new("UIGradient")
	gradient.Parent = frame

	-- slide in
	spr.target(frame, 0.8, 8, {
		Position = UDim2.fromScale(0.5, 0.5),
	})

	custom_lighting.blur()
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	end

	local typewriter = markdown.typewriter.new()
	typewriter:Play(textLabel, str)

	local function closeDisplay()
		display.hideText()

		typewriter:Skip(typewriter)
		custom_lighting.unblur()
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
		end

		task.defer(typewriter.Destroy)
	end

	hover:Watch(gradient)

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
				-- if you clicked it or not, it'll close anyway
				if bounds.inner(absPos, absSize, mousePos) or not bounds.inner(absPos, absSize, mousePos) then
					closeDisplay()
					ripple(frame)
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
