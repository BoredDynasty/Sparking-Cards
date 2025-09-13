--!nonstrict

-- notify.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local characterIteration = require(ReplicatedStorage.ClientModules.characterIteration)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

export type notification = ScreenGui & {
	Frame: Frame & {
		Icon: ImageLabel,
		Content: Frame,
		Title: Frame,
	},
}

local state = observer.new("close")

local notification = playerGui:WaitForChild("Notify") :: notification

shadow(notification.Frame, Color3.new(), 0, 14)

-- Set up default styling for the notification
local function createText(ancestor: Instance, text: string, size: number)
	TextPlus.Create(ancestor, text, {
		Font = Font.new(
			"rbxasset://fonts/families/Montserrat.json",
			Enum.FontWeight.Bold,
			Enum.FontStyle.Normal
		),
		Size = size,
		Color = Color3.fromRGB(255, 219, 209),
		XAlignment = "Left",
		YAlignment = "Center",
		Dynamic = true,
		LineSorting = true,
		WordSorting = true,
	})
end

local function showNotification(title: string, content: string, iconName: string?, duration: number?)
	-- Default values
	duration = duration or 5
	iconName = iconName or "rbxassetid://10709775560" -- bell icon

	state:Set("open")

	notification.Frame.Icon.Image = iconName

	promise.new(function()
		createText(notification.Frame.Title, title, 16)
		createText(notification.Frame.Content, content, 14)
	end)

	notification.Frame.Visible = true
	notification.Frame.Title.Visible = true
	notification.Frame.Content.Visible = true

	characterIteration:fadeIn(notification.Frame.Title)
	characterIteration:fadeIn(notification.Frame.Content)

	task.delay(duration, function()
		state:Set("close")
	end)
end

state:Watch(function(newState)
	promise.new(function()
		if newState == "close" then
			-- slide out
			characterIteration:fade(notification.Frame.Title)
			characterIteration:fade(notification.Frame.Content)
			spr.target(notification.Frame, 0.8, 8, {
				Position = UDim2.fromScale(-1, 0.953),
			})
			task.delay(1, function()
				notification.Frame.Visible = false
			end)
		else
			notification.Frame.Visible = true
			spr.target(notification.Frame, 0.8, 8, {
				Position = UDim2.fromScale(-1, 0.953),
			})
		end
	end)
end)

return {
	info = function(title: string, content: string, duration: number?)
		showNotification(title, content, "rbxassetid://10723415903", duration)
	end,
	success = function(title: string, content: string, duration: number?)
		showNotification(title, content, "rbxassetid://10709790644", duration)
	end,
	warning = function(title: string, content: string, duration: number?)
		showNotification(title, content, "rbxassetid://10709753149", duration)
	end,
	error = function(title: string, content: string, duration: number?)
		showNotification(title, content, "rbxassetid://10709775560", duration)
	end,
	custom = function(title: string, content: string, iconName: string?, duration: number?)
		showNotification(title, content, iconName, duration)
	end,
}
