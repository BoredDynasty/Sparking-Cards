local DEFAULT_SIZE = UDim2.new(0.038, 0, 0.038, 0)

local MIDDLE_ANCHOR_POINT = Vector2.new(0.5, 0.5)
local MIDDLE_POSITION = UDim2.new(0.5, 0, 0.5, 0)

local function createNewIndicator()
	local newMainFrame = Instance.new("Frame")
	newMainFrame.AnchorPoint = MIDDLE_ANCHOR_POINT
	newMainFrame.Size = DEFAULT_SIZE
	newMainFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
	newMainFrame.Name = "MainFrame"
	do
		local newUICorner = Instance.new("UICorner")
		newUICorner.CornerRadius = UDim.new(0.5, 0)
		newUICorner.Parent = newMainFrame

		local newArrowFrame = Instance.new("Frame")
		newArrowFrame.AnchorPoint = MIDDLE_ANCHOR_POINT
		newArrowFrame.Size = UDim2.fromScale(1, 1)
		newArrowFrame.Position = MIDDLE_POSITION
		newArrowFrame.BackgroundTransparency = 1
		newArrowFrame.Parent = newMainFrame
		newArrowFrame.Name = "ArrowFrame"
		do
			local newArrowImage = Instance.new("ImageLabel")
			newArrowImage.BackgroundTransparency = 1
			newArrowImage.Image = "http://www.roblox.com/asset/?id=8213161276"
			newArrowImage.AnchorPoint = MIDDLE_ANCHOR_POINT
			newArrowImage.Position = UDim2.fromScale(0.5, 0.01)
			newArrowImage.Size = UDim2.fromScale(1, 0.58)
			newArrowImage.Parent = newArrowFrame
			newArrowImage.Name = "ArrowImage"
		end

		local newIconImage = Instance.new("ImageLabel")
		newIconImage.AnchorPoint = MIDDLE_ANCHOR_POINT
		newIconImage.Position = MIDDLE_POSITION
		newIconImage.BackgroundTransparency = 1
		newIconImage.Size = UDim2.fromScale(0.87, 0.87)
		newIconImage.Parent = newMainFrame
		newIconImage.Name = "IconImage"
		do
			local newNewUICorner = newUICorner:Clone()
			newNewUICorner.Parent = newIconImage
		end
	end

	return newMainFrame
end

return createNewIndicator