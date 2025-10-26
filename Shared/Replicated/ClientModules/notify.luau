--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local NotificationModule = require(script.Parent.Notification.notification)
type Notification = NotificationModule.Notification
type NotificationOptions = NotificationModule.NotificationOptions
local spr = require(ReplicatedStorage.Modules.spr)

--[=[
	@class notify
	@client
	Handles the creation, animation, and management of notifications.
]=]
local notify = {}

local activeNotifications: {Notification} = {}
local PADDING = 10

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local notificationUI: ScreenGui = Instance.new("ScreenGui")
notificationUI.Name = "NotificationUI"
notificationUI.Parent = playerGui

local canvasGui = Instance.new("CanvasGui")
canvasGui.Name = "CanvasGui"
canvasGui.Parent = notificationUI

-- NOTE: This module requires a UI template named "NotificationFrame" to be present in ReplicatedStorage.UI
-- The template must be a Frame with the hierarchy defined in Notification/types.luau
local template = ReplicatedStorage:WaitForChild("UI"):WaitForChild("NotificationFrame")
if not template then
	error("NotificationFrame template not found in ReplicatedStorage.UI. Please create it.")
end

local function updateNotificationPositions()
	local yOffset = 0
	for i, notification in ipairs(activeNotifications) do
		local targetPosition = UDim2.new(0.5, 0, 0, yOffset)
		spr.target(notification.ui, 0.5, 20, { Position = targetPosition })
		yOffset += notification.ui.AbsoluteSize.Y + PADDING
	end
end

function notify.show(options: NotificationOptions): Notification
	local frameClone = template:Clone()
	frameClone.AnchorPoint = Vector2.new(0.5, 0)
	frameClone.Parent = canvasGui

	local notification = NotificationModule.new(frameClone, options)

	table.insert(activeNotifications, 1, notification)

	notification:Show()
	updateNotificationPositions()

	notification.promise:finally(function()
		for i, activeNotification in ipairs(activeNotifications) do
			if activeNotification == notification then
				table.remove(activeNotifications, i)
				break
			end
		end
		updateNotificationPositions()
	end)

	return notification
end

return notify
