--!strict
-- CardFactory.luau
-- This module is responsible for creating the UI for the detail cards in the loadout screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local pop = require(script.Parent.pop)

local CardFactory = {}

export type CardData = {
	Title: string,
	Text: string,
	Icon: string?,
}

function CardFactory.create(data: CardData, parent: Instance, playerGui: PlayerGui)
	local card = Instance.new("Frame")
	card.Name = data.Title
	card.BackgroundColor3 = Color3.fromRGB(35, 25, 23)
	card.BorderSizePixel = 0
	card.Parent = parent
	card.ClipsDescendants = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(245, 245, 245)
	stroke.Thickness = 0
	stroke.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	local titleFrame = Instance.new("Frame")
	titleFrame.BackgroundTransparency = 1
	titleFrame.Parent = card
	titleFrame.LayoutOrder = 1
	titleFrame.Size = UDim2.new(1, 0, 0, 20)

	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Horizontal
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.SortOrder = Enum.SortOrder.LayoutOrder
	titleLayout.Padding = UDim.new(0, 5)
	titleLayout.Parent = titleFrame

	if data.Icon then
		local icon = Instance.new("ImageLabel")
		icon.Image = data.Icon
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.new(0, 24, 0, 24)
		icon.LayoutOrder = 1
		icon.Parent = titleFrame
	end

	local titleTextFrame = Instance.new("Frame")
	titleTextFrame.BackgroundTransparency = 1
	titleTextFrame.Size = UDim2.new(1, -30, 1, 0)
	titleTextFrame.LayoutOrder = 2
	titleTextFrame.Parent = titleFrame

	TextPlus.Create(titleTextFrame, data.Title, {
		Font = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Size = 16,
		Color = Color3.fromHex("#f5f5f5"),
		XAlignment = "Left",
		YAlignment = "Center",
	})

	local textFrame = Instance.new("Frame")
	textFrame.BackgroundTransparency = 1
	textFrame.Parent = card
	textFrame.LayoutOrder = 2
	textFrame.Size = UDim2.new(1, -20, 1, -40)
	textFrame.Position = UDim2.fromOffset(10, 30)

	local textLabel = Instance.new("TextLabel")
	textLabel.RichText = true
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromHex("#f5f5f5")
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 14
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Parent = textFrame

	-- Add hover and click effects
	local originalSize
	card.MouseEnter:Connect(function()
		if not originalSize then
			originalSize = card.Size
		end
		TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = originalSize * 1.05 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Thickness = 2 }):Play()
	end)

	card.MouseLeave:Connect(function()
		if originalSize then
			TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = originalSize }):Play()
		end
		TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Thickness = 0 }):Play()
	end)

	card.MouseButton1Click:Connect(function()
		pop(card)

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "CardViewer"
		screenGui.DisplayOrder = 999
		screenGui.ResetOnSpawn = false

		local background = Instance.new("Frame")
		background.Name = "Background"
		background.BackgroundColor3 = Color3.new(0, 0, 0)
		background.BackgroundTransparency = 0.5
		background.Size = UDim2.new(1, 0, 1, 0)
		background.Parent = screenGui

		local closeButton = Instance.new("TextButton")
		closeButton.Name = "CloseButton"
		closeButton.Size = UDim2.new(1, 0, 1, 0)
		closeButton.BackgroundTransparency = 1
		closeButton.Text = ""
		closeButton.Parent = background

		local cardClone = card:Clone()
		cardClone.Parent = background
		cardClone.AnchorPoint = Vector2.new(0.5, 0.5)
		cardClone.Position = UDim2.fromScale(0.5, 0.5)
		cardClone.Size = UDim2.fromScale(0.5, 0.7)
		cardClone.Active = false

		closeButton.MouseButton1Click:Connect(function()
			screenGui:Destroy()
		end)

		screenGui.Parent = playerGui
	end)

	return card, textLabel
end

return CardFactory