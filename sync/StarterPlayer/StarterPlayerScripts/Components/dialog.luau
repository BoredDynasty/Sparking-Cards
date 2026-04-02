--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- https://m3.material.io/components/dialogs/specs

local module = {}

local assets = ReplicatedStorage.Assets

local function loadBasicDialog(has_icon: boolean): Frame
	-- this function should load the basic dialog template from ReplicatedStorage and return it
	-- it can also set up any necessary connections for the dialog's buttons and functionality

	if not has_icon then
		-- load the basic dialog without an icon
		return assets.Dialogs.Basic1:Clone()
	else
		-- load the basic dialog with an icon
		return assets.Dialogs.Basic2:Clone()
	end
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

function module.display_basic(data: {
	Title: string,
	Description: string,
	Buttons: { Text: string, Callback: () -> () }?,
	Icon: typemarshaller.LucideIcon?,
})
	-- this function is a stub and should be implemented to display the dialog using the provided data
	-- it should create a dialog UI, set the title, description, and icon, and create buttons with their respective callbacks

	--
end
