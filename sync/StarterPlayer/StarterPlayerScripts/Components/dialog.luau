--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local audio = require(ReplicatedStorage.Modules.audio)
local fade = require(StarterPlayer.StarterPlayerScripts.Interface.fade)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local property = require(ReplicatedStorage.Utility.property)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local spr = require(ReplicatedStorage.Modules.spr)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- dialog.luau
-- Dialogs provide important prompts in a user flow

--[[
   - Use dialogs to make sure users act on information
   - Two variants: basic and full-screen
   - Should be dedicated to completing a single task
   - Can also display information relevant to the task
   - Commonly used to confirm high-risk actions like deleting progress
]]

-- TODO: add support for a 'Learn More' button

-- https://m3.material.io/components/dialogs/specs

local module = {}

type BasicDialogData = {
	Title: string,
	Description: string,
	Buttons: { Text: string, Callback: () -> () }?,
	Icon: typemarshaller.LucideIcon?,
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local dialog_holder = playerGui:WaitForChild("Dialog") :: ScreenGui

dialog_holder.DisplayOrder = math.huge -- required to ensure dialogs appear above all else

local assets = ReplicatedStorage.Interfaces

local function loadBasicDialog(
	has_icon: boolean
): typeof(assets.Dialogs.Basic1) | typeof(assets.Dialogs.Basic2)
	-- this function should load the basic dialog template from ReplicatedStorage and return it
	-- it can also set up any necessary connections for the dialog's buttons and functionality

	if not has_icon then
		-- load the basic dialog without an icon
		return assets.Dialogs.Basic1:Clone() :: typeof(assets.Dialogs.Basic1)
	else
		-- load the basic dialog with an icon
		return assets.Dialogs.Basic2:Clone() :: typeof(assets.Dialogs.Basic2)
	end
end

local function loadButton()
	-- this function should load a button template from ReplicatedStorage and return it
	-- it can also set up any necessary connections for the button's functionality

	return assets.Dialogs.OptionButton:Clone()
end

local function animateBasicDialogAppearance(
	dialog: typeof(assets.Dialogs.Basic1) | typeof(assets.Dialogs.Basic2)
)
	-- this function should handle the animation for the basic dialog's appearance
	--[[
      Dialogs appear without warning, requiring users to stop their current task. 
      They should be used sparingly, as not every choice or setting warrants interruption.

      Dialogs use an enter and exit transition pattern to appear on screen.
   ]]

	local starting_size = UDim2.fromScale(0.4, 0.054)
	local target_size = UDim2.fromScale(0.4, 0.4)

	dialog.Size = starting_size
	dialog.Visible = true
	dialog.Parent = dialog_holder

	-- everything inside the dialog should be transparent for a sec.
	for i, descendant in ipairs(dialog:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			task.spawn(function()
				if property.hasProperty(descendant, "Transparency") then
					descendant.Transparency = 1
				end

				fade.fade_out(descendant, 1 / 10000) -- an extra measure
			end)
		end
	end

	-- animate to target size
	-- this should be done in under a second.
	-- use a zero damped spring for a snappy feel that still has some weight to it

	spr.target(dialog, 1, 15, {
		Size = target_size,
	})

	-- fade in while animating size
	for i, descendant in ipairs(dialog:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			task.spawn(function()
				fade.fade_in(descendant, (1 / 15) * 10)
			end)
		end
	end
end

local function animateBasicDialogDisappearance(
	dialog: typeof(assets.Dialogs.Basic1) | typeof(assets.Dialogs.Basic2),
	onComplete: () -> ()
)
	-- this function should handle the animation for the basic dialog's disappearance
	-- it should reverse the appearance animation and then call onComplete when finished

	local target_size = UDim2.fromScale(0.4, 0.054)

	-- fade out while animating size
	for i, descendant in ipairs(dialog:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			task.spawn(function()
				fade.fade_out(descendant, (1 / 15) * 5)
			end)
		end
	end

	spr.target(dialog, 1, 20, {
		Size = target_size,
		BackgroundTransparency = 1,
	})

	task.delay(1, function()
		dialog.Visible = false
		dialog.Parent = nil

		onComplete()
	end)
end

-- note: fullscreen dialogs are not yet implemented, but the structure is in place to support them in the future

function module.create_basic()
	local data = {
		Title = "",
		Description = "",
		Buttons = {}, -- { Text: string, Callback: () -> () }
		Icon = nil :: typemarshaller.LucideIcon?,
	}

	return data
end

function module.display_basic(data: BasicDialogData)
	-- this function is a stub and should be implemented to display the dialog using the provided data
	-- it should create a dialog UI, set the title, description, and icon, and create buttons with their respective callbacks

	local dialog = loadBasicDialog(data.Icon ~= nil)
	dialog.Title.Text = data.Title
	dialog.Holder.Description.Text = data.Description

	if data.Icon then
		assert(dialog.Image) -- we need that intellisense yk
		dialog.Image.ImageContent = Content.fromAssetId(data.Icon.Id)
	end

	animateBasicDialogAppearance(dialog)

	local function disableAllOtherButtons()
		for _, button in ipairs(dialog.OptionHolder:GetChildren()) do
			if button:IsA("GuiButton") then
				button.AutoButtonColor = false
				button.Active = false
			end
		end
	end

	if data.Buttons then
		-- TODO: reverse the table
		for i, buttonData in ipairs(data.Buttons) do
			local button = loadButton()
			button.Text = buttonData.Text
			button.Parent = dialog.OptionHolder

			button.Activated:Connect(function()
				disableAllOtherButtons()

				buttonData.Callback()

				pop(button)
				ripple(button)
				audio:PlaySFX("wood-block-1")

				-- immediately close
				animateBasicDialogDisappearance(dialog, function()
					print("hooray!")
				end)

				task.delay(5, function()
					dialog:Destroy()
					data = nil -- allow gc
				end)
			end)
		end
	end
end

return module
