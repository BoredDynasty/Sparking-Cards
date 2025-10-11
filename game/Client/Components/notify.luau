--!nonstrict

-- notify.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local markdown = require(ReplicatedStorage.ClientModules.markdown)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local unicode_width = require(ReplicatedStorage.Modules.Serialization["unicode-width"])

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

export type notification = ScreenGui & {
	Pill: Frame & {
		ImageLabel: ImageLabel,
		TextLabel: TextLabel,
	},
}

local state = observer.new("close")

local notification = playerGui:WaitForChild("Notify") :: notification

local themes = {
	success = {
		color = Color3.fromRGB(66, 154, 102),
		icon = "rbxassetid://10709790644",
		text = "Complete",
	},
	info = {
		color = Color3.fromHex("#4f6fc2"),
		icon = "rbxassetid://10723415903",
		text = "Info",
	},
	error = {
		color = Color3.fromHex("#c14040"),
		icon = "rbxassetid://10747384394",
		text = "Failed",
	},
	warning = {
		color = Color3.fromHex("#d88123"),
		icon = "rbxassetid://10723374276",
		text = "Warning",
	},
	draft = {
		color = Color3.fromHex("#757d92"),
		icon = "rbxassetid://10734919691",
		text = "Draft",
	},
}

local function getTheme(_type: string): { color: Color3, icon: string, text: string }?
	return promise
		.new(function(resolve: (unknown) -> ...unknown)
			resolve(themes[_type])
		end)
		:catch(warn)
		:expect()
end

local function showNotification(title: string, content: string, _type: string?, duration: number?)
	-- Default values
	duration = duration or 5

	state:Set("open")

	local theme = getTheme(_type) or themes.draft
	notification.Pill.ImageLabel.ImageContent = Content.fromUri(theme.icon) or Content.none

	promise
		.new(function()
			-- color
			spr.target(notification.Pill, 0.5, 1.1, {
				BackgroundColor3 = theme.color,
			})

			local content_width = unicode_width.width(content) :: number
			-- if the content width is over 20, make the frame wider accordingly
			if content_width > 20 then
				spr.target(notification.Pill, 0.5, 1.1, {
					Size = UDim2.fromOffset(400 + (content_width - 20) * 10, 50),
				})
			else
				spr.target(notification.Pill, 0.5, 1.1, {
					Size = UDim2.fromScale(0.227, 0.045),
				})
			end
		end)
		:catch(warn)

	promise
		.new(function()
			local typewriter = markdown.typewriter.new({
				cps = 1 / duration * 100, -- characters per second
				instantFinishKey = Enum.KeyCode.Unknown,
			})

			notification.Pill.TextLabel.RichText = true

			typewriter:Play(notification.Pill.TextLabel, theme.text)

			repeat
				RunService.Heartbeat:Wait()
			until typewriter:IsPlaying() == false

			typewriter:Destroy()
		end)
		:catch(warn)

	task.delay(duration, function()
		state:Set("close")
	end)
end

state:Watch(function(newState: string)
	promise.new(function()
		if newState == "close" then
			-- slide out
			spr.target(notification.Pill, 0.8, 1.1, {
				Position = UDim2.fromScale(-1, 0.95),
			})
			task.delay(1, function()
				notification.Pill.Visible = false
			end)
		else
			notification.Pill.Visible = true
			spr.target(notification.Pill, 0.8, 1.1, {
				Position = UDim2.fromScale(0.135, 0.95),
			})
		end
	end)
end)

return {
	info = function(title: string, content: string, duration: number?, _type: string?)
		showNotification(title, content, _type, duration)
	end,
	success = function(title: string, content: string, duration: number?, _type: string?)
		showNotification(title, content, _type, duration)
	end,
	warning = function(title: string, content: string, duration: number?, _type: string?)
		showNotification(title, content, _type, duration)
	end,
	error = function(title: string, content: string, duration: number?, _type: string?)
		showNotification(title, content, _type, duration)
	end,
}
