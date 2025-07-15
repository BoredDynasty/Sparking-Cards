--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Utility.SignalPlus)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local characterIteration = require(ReplicatedStorage.ClientModules.characterIteration)
local lucide = require(ReplicatedStorage.Packages.lucide)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

export type dialog = ScreenGui & {
	Frame: Frame & {
		Cancel: TextButton & {
			TextHolder: Frame,
		},
		Confirm: TextButton & {
			TextHolder: Frame,
		},
		ImageLabel: ImageLabel,
		Description: Frame,
		Title: Frame,
	},
}

local dialog = playerGui:WaitForChild("Confirm") :: dialog

TextPlus.Create(dialog.Frame.Cancel.TextHolder, "Nah", {
	Font = Font.new(
		"rbxasset://fonts/families/Montserrat.json", -- Family.
		Enum.FontWeight.Bold, -- Weight.
		Enum.FontStyle.Normal -- Style.
	),
	Size = 14,
	Color = Color3.fromRGB(255, 219, 209),
	XAlignment = "Center",
	YAlignment = "Center",
	Dynamic = true,
})
TextPlus.Create(dialog.Frame.Cancel.TextHolder, "Yeah, sure", {
	Font = Font.new(
		"rbxasset://fonts/families/Montserrat.json", -- Family.
		Enum.FontWeight.Bold, -- Weight.
		Enum.FontStyle.Normal -- Style.
	),
	Size = 14,
	Color = Color3.fromRGB(255, 219, 209),
	XAlignment = "Center",
	YAlignment = "Center",
	Dynamic = true,
})

local state = statemachine.new({
	active = {
		name = "active",
		transitions = {
			inactive = "inactive",
		},
	},
	inactive = {
		name = "inactive",
		transitions = {
			inactive = "active",
		},
	},
}, "inactive")

type signal = SignalPlus.Signal<boolean>

local icon = lucide.GetAsset("info")
dialog.Frame.ImageLabel.Image = icon.Url
dialog.Frame.ImageLabel.ImageRectOffset = icon.ImageRectOffset
dialog.Frame.ImageLabel.ImageRectSize = icon.ImageRectSize

return function(title: string, description: string)
	if state:getCurrentState() ~= "inactive" then
		print("active dialog")
	end
	TextPlus.Create(dialog.Frame.Title, title, {
		Font = Font.new(
			"rbxasset://fonts/families/Montserrat.json", -- Family.
			Enum.FontWeight.Bold, -- Weight.
			Enum.FontStyle.Normal -- Style.
		),
		Size = 20,
		Color = Color3.fromRGB(255, 219, 209),
		XAlignment = "Center",
		YAlignment = "Center",
		Dynamic = true,
	})
	TextPlus.Create(dialog.Frame.Description, title, {
		Font = Font.fromName("Montserrat"),
		Size = 20,
		Color = Color3.fromRGB(255, 219, 209),
		XAlignment = "Center",
		YAlignment = "Center",
		Dynamic = true,
	})
	characterIteration:fadeIn(dialog.Frame.Title)
	characterIteration:fadeIn(dialog.Frame.Description)
	dialog.Frame.Description.Text = description
	local activated: signal = SignalPlus()
	dialog.Frame.Confirm.Activated:Connect(function()
		activated:Fire(true)
		dialog.Frame.Confirm.Interactable = false
		dialog.Frame.Cancel.Interactable = false
	end)
	dialog.Frame.Cancel.Activated:Connect(function()
		activated:Fire(false)
		dialog.Frame.Confirm.Interactable = false
		dialog.Frame.Cancel.Interactable = false
	end)
	task.delay(3, function()
		dialog.Frame.Confirm.Interactable = true
		dialog.Frame.Cancel.Interactable = true
	end)
	return activated
end
