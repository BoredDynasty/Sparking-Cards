--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local characterIteration = require(ReplicatedStorage.ClientModules.characterIteration)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)

-- Options.luau

local Options = {}
Options.created = {}

export type Option = {
	name: string,
	description: string,
	toggleFunctions: {
		on: (self: optionTemplate) -> boolean,
		off: (self: optionTemplate) -> boolean,
	}?,
	icons: {
		on: string?,
		off: string?,
	}?,
	reactor: observer.Observer<string>,
	interface: optionTemplate?,
}

export type Icons = {
	on: string?,
	off: string?,
}?

export type optionTemplate = Frame & {
	Frame: Frame & {
		TextDisplay: Frame,
	},
	Toggle: TextButton & {
		Icon: ImageLabel,
	},
}

local DEFAULT_ICONS = {
	on = "rbxassetid://10747384394",
	off = "rbxassetid://7733715400",
}

local templates = (ReplicatedStorage.Interfaces :: Folder).Options :: Folder
local player = playerMarshaller.get()
local optionsGui = player.PlayerGui:WaitForChild("Options") :: ScreenGui
local optionsCanvas = optionsGui:WaitForChild("CanvasGroup") :: CanvasGroup
local optionsFrame = optionsCanvas:WaitForChild("Frame") :: Frame
local holder = optionsFrame:WaitForChild("Holder") :: ScrollingFrame
local optionTemplate = templates:WaitForChild("OptionTemplate") :: optionTemplate

local function createOptionInterface(option: Option): optionTemplate
	local interface: optionTemplate = optionTemplate:Clone()
	interface.Name = option.name
	interface.Parent = holder

	local textDisplay = interface.Frame.TextDisplay

	-- Create text display with TextPlus
	TextPlus.Create(textDisplay, `{option.name}{"\n\n\n"}{option.description or " "}`, {
		Font = Font.new(
			"rbxasset://fonts/families/Montserrat.json",
			Enum.FontWeight.Regular,
			Enum.FontStyle.Normal
		),
		Size = 16,
		Color = Color3.fromHex("#ffffff"),
		XAlignment = "Left",
		YAlignment = "Center",
		LineSorting = true,
		WordSorting = true,
		Dynamic = true,
	})

	-- Style the title text (first line)
	local line1 = characterIteration.getLine(textDisplay, 1)
	characterIteration:bolden(line1)

	-- Style the description text (second line)
	local line2 = characterIteration.getLine(textDisplay, 2)
	characterIteration:regularize(line2)

	return interface
end

function Options:create(name: string, description: string, toggleFunctions, icons: Icons?)
	local option: Option = {
		name = name,
		description = description,
		toggleFunctions = toggleFunctions,
		icons = icons or DEFAULT_ICONS,
		reactor = observer.new("off"),
	}

	option.interface = createOptionInterface(option)
	Options.created[name] = option

	return option
end

function Options:render()
	for _, option in pairs(Options.created :: { Option }) do
		if not option.interface then
			continue
		end

		local toggle = option.interface.Toggle

		toggle.Activated:Connect(function()
			local newState = option.reactor:Get() == "on" and "off" or "on"
			option.reactor:Set(newState)
			audio:SFX("click")
		end)

		toggle.MouseEnter:Connect(function()
			audio:SFX("hover")
		end)

		toggle.MouseLeave:Connect(function()
			audio:SFX("hover")
		end)

		option.reactor:Watch(function(newState: string)
			local icon = if newState == "on"
				then option.icons.on or DEFAULT_ICONS.on
				else option.icons.off or DEFAULT_ICONS.off

			toggle.Icon.Image = icon

			if option.toggleFunctions then
				if newState == "on" then
					option.toggleFunctions.on(option.interface)
				else
					option.toggleFunctions.off(option.interface)
				end
			end
		end)
	end
end

function Options:toggle(optionName: string)
	local option = Options.created[optionName] :: Option
	local value = nil
	if option then
		local newState = option.reactor:Get() == "on" and "off" or "on"
		option.reactor:Set(newState)

		value = option.reactor:Get()
	end
	return value
end

function Options:clear()
	for _, option in pairs(Options.created :: { Option }) do
		if option.interface then
			option.interface:Destroy()
		end
	end
	table.clear(Options.created :: { Option })
end

function Options:hide()
	if optionsGui then
		optionsGui.Enabled = false
	end
end

function Options:show()
	if optionsGui then
		optionsGui.Enabled = true
	end
end

return Options
