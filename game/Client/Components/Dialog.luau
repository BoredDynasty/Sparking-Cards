--!strict

-- Dialog.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local DisplayOrder = require(StarterPlayer.StarterPlayerScripts.Modules.DisplayOrder).new()
local Pop = require(StarterPlayer.StarterPlayerScripts.Modules.Pop)
local shunt = require(ReplicatedStorage.Utility.shunt)
local timer = require(ReplicatedStorage.Modules.timer)

local player = Players.LocalPlayer
local PlayerGui = player.PlayerGui

local confirmGui = PlayerGui:WaitForChild("Confirm") :: ScreenGui
local confirmFrame = confirmGui:FindFirstChild("Frame") :: Frame

local dialogs = table.create(10)

local disclaimerTxt = [[
<br/><font transparency="0.5"><font size="12">No other action can be made during this dialog.</font></font>
]]

local timeout = 15

-- THIS YIELDS
return function(titleTxt: string, descriptionTxt: string, icon: string?): boolean?
	local needle = table.find(dialogs, true)
	if needle then
		return nil
	end
	debug.profilebegin("dialog")
	table.insert(dialogs, true)
	DisplayOrder:changeVisibility(true, confirmFrame)
	Pop(confirmFrame)
	local title = confirmFrame:FindFirstChild("Title") :: TextLabel
	local description = confirmFrame:FindFirstChild("Description") :: TextLabel

	local confirmBtn = confirmFrame:FindFirstChild("Confirm") :: TextButton
	local cancelBtn = confirmFrame:FindFirstChild("Cancel") :: TextButton

	if icon then
		local img = confirmFrame:FindFirstChildOfClass("ImageLabel") :: ImageLabel
		img.Image = icon
	end

	local result: boolean? = nil :: boolean?

	title.Text = titleTxt
	description.Text = descriptionTxt .. disclaimerTxt

	confirmBtn.MouseButton1Click:Once(function()
		print("confirm")
		result = true
		Pop(cancelBtn)
		task.wait()
		DisplayOrder:changeVisibility(false, confirmFrame)
	end)
	cancelBtn.MouseButton1Click:Once(function()
		print("cancel")
		result = false
		Pop(cancelBtn)
		task.wait()
		DisplayOrder:changeVisibility(false, confirmFrame)
	end)
	shunt(confirmBtn.MouseButton1Click, cancelBtn.MouseButton1Click)
	local clock = timer.new()
	clock:Start()
	while result ~= type("boolean") do
		task.wait(1)
		local elapsed = clock:GetTime()
		assert(elapsed, "no elapsed time somehow :skull:")
		if elapsed >= timeout then
			result = false
			clock:Stop()
			clock:Destroy()
			break -- remove the loop
		end
	end
	table.remove(dialogs, 1)
	debug.profileend()
	return result
end
