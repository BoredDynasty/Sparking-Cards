--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Saturation = require(script.Parent.Saturation)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)

-- Ripple.lua

type ripple = ScreenGui & {
	dot: Frame,
	circle: Frame,
}
type rippleContainer = Frame & {
	corner: UICorner,
	stroke: UIStroke,
}

local update_connection: RBXScriptConnection? = nil

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local function newRipple(color: Color3): ripple
	local gui = Instance.new("ScreenGui")
	gui.Name = "Ripple"
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.DisplayOrder = 2 * 102
	gui.Parent = playerGui

	-- UserInputService.MouseIconEnabled = false

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.BackgroundColor3 = color
	dot.BackgroundTransparency = 0
	dot.BorderSizePixel = 0
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(0, 0, 0, 0)
	dot.ZIndex = 10001
	dot.Parent = gui

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot

	local circle = Instance.new("Frame")
	circle.Size = UDim2.fromScale(14, 14)
	circle.BackgroundTransparency = 1
	circle.BorderSizePixel = 0
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.new()
	circle.ZIndex = 10000
	circle.Parent = gui

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = circle

	local circleStroke = Instance.new("UIStroke")
	circleStroke.Color = color
	circleStroke.Thickness = 2
	circleStroke.Parent = circle
	return gui
end

local function newContainer<T, R, C>(x, y, rippleContainer: ripple, color: Color3): rippleContainer
	local ripple = Instance.new("Frame")
	ripple.Size = UDim2.new()
	ripple.Position = UDim2.fromScale(x, y)
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.BackgroundTransparency = 1
	ripple.BorderSizePixel = 0
	ripple.ZIndex = 9999
	ripple.Parent = rippleContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ripple

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 3
	stroke.Transparency = 0
	stroke.Parent = ripple
	return ripple
end

local function updatePosition(container: ripple)
	if update_connection then
		return
	end
	update_connection = RunService.RenderStepped:Connect(function()
		local mousePos = UserInputService:GetMouseLocation()
		local x, y = mousePos.X, mousePos.Y

		container.dot.Position = UDim2.fromScale(x, y)
		container.circle.Position = UDim2.fromScale(x, y)

		local objects = playerGui:GetGuiObjectsAtPosition(x, y)
		-- Returns an array of all GuiObject instances occupying the given point on the screen.

		local overGui = false
		for _, guiElement in ipairs(objects) do
			if
				guiElement.Visible and guiElement:IsA("GuiButton")
				or guiElement:IsA("TextLabel")
				or guiElement:IsA("ImageLabel")
			then
				overGui = true
				break
			end
		end

		container.dot.Visible = not overGui
		container.circle.Visible = overGui
	end)
end

return function(color: Color3?)
	color = color or Saturation.generateBrightColor()
	local position = UserInputService:GetMouseLocation()
	local rippleGui = newRipple()
	local ripple = newContainer(position.X, position.Y, rippleGui, color)
	updatePosition(rippleGui)
	for i = 1, 1 do
		local targetSize = 30 + (i * 10)
		local expand = TweenPlus(ripple, {
			Size = UDim2.new(0, targetSize, 0, targetSize),
		}, { Time = 0.8, EasingStyle = "Sine", EasingDirection = "Out" })

		local fade = TweenPlus(ripple, {
			Transparency = 1,
		}, { Time = 0.8, EasingStyle = "Sine", EasingDirection = "Out" })

		expand:Start()
		fade:Start()

		task.delay(0.8, function()
			ripple:Destroy()
			task.wait()
			if update_connection then
				update_connection:Disconnect()
			end
		end)
	end
end
