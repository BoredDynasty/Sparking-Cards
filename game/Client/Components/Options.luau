--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hint = require(ReplicatedStorage.ClientModules.Hint)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local lucide = require(ReplicatedStorage.Packages.lucide)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

-- Options.luau

local Options = {
	created = {},
	states = {
		["on"] = {
			name = "on",
			onEnter = function(optionTemplate: optionTemplate)
				print(optionTemplate)
				--optionTemplate.Toggle.Icon.Image = "rbxassetid://7733715400" -- Replace with actual icon ID
			end,
			transitions = {
				off = "off",
			},
		},
		["off"] = {
			name = "off",
			onEnter = function(optionTemplate: optionTemplate)
				print(optionTemplate)
				--optionTemplate.Toggle.Icon.Image = "rbxassetid://10747384394" -- Replace with actual icon ID
			end,
			transitions = {
				on = "on",
			},
		},
	},
}

export type optionTemplate = Frame & {
	Frame: Frame & {
		TextDisplay: Frame,
	},
	Toggle: TextButton & {
		Icon: ImageLabel,
	},
}
export type toggleFunctions = {
	on: (self: optionTemplate) -> boolean, -- must return boolean indicating success
	off: (self: optionTemplate) -> boolean, -- must return boolean indicating success
}

local templates = (ReplicatedStorage.Interfaces :: Folder).Options :: Folder

local player = playerMarshaller.get()
local optionsGui = player.PlayerGui:WaitForChild("Options") :: ScreenGui

local optionsCanvas = optionsGui:WaitForChild("CanvasGroup") :: CanvasGroup
local optionsFrame = optionsCanvas:WaitForChild("Frame") :: Frame

local holder = optionsFrame:WaitForChild("Holder") :: ScrollingFrame

local optionTemplate = templates:WaitForChild("OptionTemplate") :: optionTemplate

local function createOption(optionName: string, description: string, initialIcon: string?): optionTemplate
	local option: optionTemplate = optionTemplate:Clone()
	option.Name = optionName
	option.Parent = holder

	local textDisplay = option.Frame.TextDisplay

	initialIcon = initialIcon or "rbxassetid://7733715400"

	TextPlus.Create(
		textDisplay,
		`{optionName}{"\n\n\n"}{description or " "}`,
		-- the name bolded and the description transparency 0.5
		-- maybe the description should be italic
		{
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.Regular, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 16,
			Color = Color3.fromHex("#ffffff"),
			XAlignment = "Left",
			YAlignment = "Center",
			LineSorting = true,
			WordSorting = true,
			Dynamic = true,
		}
	)
	-- now we do manual rich text
	-- please help
	local line1 = textDisplay["1"] :: Folder -- line 1
	-- Line and word sorting:
	for wordNumber, word in line1:GetChildren() do
		-- 'word' will be a folder.
		for characterNumber, character in word:GetChildren() do
			-- For Roblox fonts, 'character' will be a TextLabel.
			-- For custom fonts, 'character' will be an ImageLabel.
			character.FontFace = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.Bold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			)
		end
	end
	local line2 = textDisplay["2"] :: Folder
	-- Line and word sorting:
	for wordNumber, word in line2:GetChildren() do
		-- 'word' will be a folder.
		for characterNumber, character: TextLabel in word:GetChildren() do
			-- For Roblox fonts, 'character' will be a TextLabel.
			-- For custom fonts, 'character' will be an ImageLabel.
			character.TextTransparency = 0.5
			character.FontFace = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.Regular, -- Weight.
				Enum.FontStyle.Normal -- Style.
			)
		end
	end

	return option :: optionTemplate
end

function Options.createOption(
	optionName: string,
	description: string,
	overrideState: string?,
	toggleFunctions: toggleFunctions?,
	overrideIcons: { [string]: string? }?
): (SignalPlus.Signal<boolean>, optionTemplate)
	local initialIcon = if overrideIcons and overrideIcons.off
		then overrideIcons.off :: string
		else "rbxassetid://7733715400" -- Default off icon
	local option = createOption(optionName, description, initialIcon)
	option.Parent = holder

	local onToggle = SignalPlus() :: SignalPlus.Signal<boolean>

	Options.created[optionName] = {
		interface = option,
		optionName = optionName,
		description = description,
		state = statemachine.new(Options.states, overrideState or "on"),
	}

	option.Toggle.Activated:Connect(function()
		local currentState = Options.created[optionName].state:getCurrentState()
		if currentState == "on" then
			Options.created[optionName].state:transition("off", option)
			if toggleFunctions then
				local offEvent = function()
					if overrideIcons and overrideIcons.off then
						option.Toggle.Icon.Image = overrideIcons.off :: string
					else
						-- Default off icon
						option.Toggle.Icon.Image = "rbxassetid://7733715400"
					end
				end
				offEvent()
				toggleFunctions.off(option)
			else
				print("off")
			end
			onToggle:Fire(false)
		elseif currentState == "off" then
			Options.created[optionName].state:transition("on", option)
			if toggleFunctions then
				local onEvent = function()
					if overrideIcons and overrideIcons.on then
						option.Toggle.Icon.Image = overrideIcons.on :: string
					else
						-- Default on icon
						option.Toggle.Icon.Image = "rbxassetid://10747384394"
					end
				end
				onEvent()
				toggleFunctions.on(option)
			else
				print("on")
			end
			onToggle:Fire(true)
		end
	end)
	option.Toggle.MouseEnter:Connect(function()
		audio:SFX("hover")
	end)
	option.Toggle.MouseLeave:Connect(function()
		audio:SFX("hover")
	end)
	Hint("Toggle the " .. optionName:lower() .. " option.", option.Toggle)
	return onToggle, option :: optionTemplate
end

return Options
