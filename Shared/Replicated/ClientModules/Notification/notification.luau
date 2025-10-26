--!strict

--[=[
	@class Notification
	@client
	A class that represents a single notification.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local types = require(script.Parent.types)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local spr = require(ReplicatedStorage.Modules.spr)
local fade = require(script.Parent.Parent.UIEffects.fade)
local pop = require(script.Parent.Parent.UIEffects.pop)
local Promise = require(ReplicatedStorage.Packages.promise)

type NotificationUI = types.NotificationUI

export type NotificationOptions = {
	Title: string,
	Message: string,
	Duration: number?,
	Type: ("Simple" | "Timeout" | "Input" | "Options")?,
	-- Add more options as needed
}

local Notification_prototype = {}
Notification_prototype.__index = Notification_prototype

export type Notification = typeof(setmetatable({} :: {
	ui: Frame,
	options: NotificationOptions,
	visible: boolean,
	glare: Frame,
	promise: typeof(Promise.new(function() end)),
	_resolve: (any) -> (),
	_reject: (any) -> (),
}, Notification_prototype))

function Notification_prototype:Show()
	self.ui.Visible = true
	self.visible = true

	-- Pop animation
	pop(self.ui, 0.95)

	-- Fade in animation
	fade.fadeIn(self.ui, 0.3, true)

	-- Glare animation
	if self.glare and self.glare.Parent then
		self.glare.Size = UDim2.new(0, self.ui.AbsoluteSize.X * 0.4, 1, 0)
		self.glare.Visible = true
		local tween = TweenPlus(self.glare, {
			Position = UDim2.new(1.4, 0, 0, 0),
		}, {
			Time = 0.5,
			EasingStyle = "Linear",
		})
		tween:Start()
		tween.Completed:Once(function()
			if self.glare and self.glare.Parent then
				self.glare.Visible = false
			end
		end)
	end
end

function Notification_prototype:Hide(result: any?)
	if not self.visible then return end
	self.visible = false

	-- Fade out animation
	fade.fadeOut(self.ui, 0.3, true):andThen(function()
		self._resolve(result)
		self:Destroy()
	end)
end

function Notification_prototype:Destroy()
	self.ui:Destroy()
end


local Notification = {}

function Notification.new(ui: Frame, options: NotificationOptions): Notification
	local self = setmetatable({} :: any, Notification_prototype)

	self.ui = ui
	self.options = options
	self.visible = false

	local resolve, reject
	self.promise = Promise.new(function(res, rej)
		resolve = res
		reject = rej
	end)
	self._resolve = resolve
	self._reject = reject

	-- Initialize the UI
	local title = self.ui:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = options.Title
	end

	local message = self.ui:FindFirstChild("Message")
	if message and message:IsA("TextLabel") then
		message.Text = options.Message
	end

	-- Set initial state for animations
	self.ui.Visible = false
	self.ui.BackgroundTransparency = 1

	-- Glare effect
	local glareHolder = Instance.new("Frame")
	glareHolder.Name = "GlareHolder"
	glareHolder.BackgroundTransparency = 1
	glareHolder.Size = UDim2.fromScale(1, 1)
	glareHolder.ClipsDescendants = true
	glareHolder.Parent = self.ui

	local glare = Instance.new("Frame")
	glare.Name = "GlareOverlay"
	glare.BackgroundTransparency = 1
	glare.BorderSizePixel = 0
	glare.Size = UDim2.new(0, 0, 1, 0) -- Initial size, will be updated in Show
	glare.Position = UDim2.new(-0.4, 0, 0, 0)
	glare.Rotation = -45
	glare.Parent = glareHolder
	glare.Visible = false

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = 45
	gradient.Parent = glare

	self.glare = glare

	-- Type specific logic
	local notificationType = self.options.Type or "Simple"
	if notificationType == "Input" then
		local input = self.ui:FindFirstChild("Input", true)
		local submit = self.ui:FindFirstChild("Submit", true)
		if input and submit and input:IsA("TextBox") and submit:IsA("TextButton") then
			input.Visible = true
			submit.Visible = true
			submit.MouseButton1Click:Connect(function()
				self:Hide(input.Text)
			end)
		end
	elseif notificationType == "Options" then
		local optionsFrame = self.ui:FindFirstChild("Options", true)
		if optionsFrame then
			optionsFrame.Visible = true
			local ok = optionsFrame:FindFirstChild("OK")
			local cancel = optionsFrame:FindFirstChild("Cancel")
			if ok and ok:IsA("TextButton") then
				ok.MouseButton1Click:Connect(function()
					self:Hide(true)
				end)
			end
			if cancel and cancel:IsA("TextButton") then
				cancel.MouseButton1Click:Connect(function()
					self:Hide(false)
				end)
			end
		end
	elseif notificationType == "Simple" then
		local gotIt = self.ui:FindFirstChild("GotIt", true)
		if gotIt and gotIt:IsA("TextButton") then
			gotIt.Visible = true
			gotIt.MouseButton1Click:Connect(function()
				self:Hide(true)
			end)
		end
	end

	-- Timeout and Progress Bar
	if self.options.Duration then
		local progressBar = self.ui:FindFirstChild("ProgressBar", true)
		if progressBar and progressBar:IsA("Frame") then
			local progress = progressBar:FindFirstChild("Progress")
			if progress and progress:IsA("Frame") then
				progress.Size = UDim2.new(1, 0, 1, 0)
				local tween = TweenPlus(progress, {
					Size = UDim2.new(0, 0, 1, 0)
				}, {
					Time = self.options.Duration,
					EasingStyle = "Linear"
				})
				tween:Start()
			end
		end

		task.delay(self.options.Duration, function()
			self:Hide()
		end)
	end

	return self
end


return Notification
