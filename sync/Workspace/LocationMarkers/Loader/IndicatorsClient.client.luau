-- v.1.3

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


local createNewIndicator = require(script:WaitForChild("CreateNewIndicator"))
local updateIndicatorUI = require(script:WaitForChild("UpdateIndicatorUI"))


local camera = Workspace.CurrentCamera

local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IndicatorGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")


local indicatorTable = {}
-- {attachment, ui, connections}


local function removeIndicator(attachment)
	for index, data in ipairs(indicatorTable) do
		if data[1] == attachment then
			data[2]:Destroy()
			for _, connection in ipairs(data[3]) do
				if connection then
					connection:Disconnect()
				end
			end
			table.remove(indicatorTable, index)
		end
	end
end

local function processWorkspaceDescendantAdded(descendant)
	if descendant:IsA("Attachment") and descendant.Name == "Indicator" then
		removeIndicator(descendant)
		
		local newIndicator = createNewIndicator()
		local connections = {}
		
		local attributeChanged = descendant.AttributeChanged:Connect(function(name)
			if (name == "Image") or (name == "Team") or (name == "Color") or (name == "Enabled") then
				updateIndicatorUI(descendant, newIndicator)
			end
		end)
		table.insert(connections, attributeChanged)
		
		local data = {}
		data[1] = descendant
		data[2] = newIndicator
		data[3] = connections
		table.insert(indicatorTable, data)
		
		updateIndicatorUI(descendant, newIndicator)
		newIndicator.Parent = screenGui
	end
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
	processWorkspaceDescendantAdded(descendant)
end

Workspace.DescendantAdded:Connect(processWorkspaceDescendantAdded)


local function processWorkspaceDescendantRemoving(descendant)
	if descendant:IsA("Attachment") and descendant.Name == "Indicator" then
		removeIndicator(descendant)
	end
end

Workspace.DescendantRemoving:Connect(processWorkspaceDescendantRemoving)

local function updateIndicatorPositions()
	local viewportX = camera.ViewportSize.X
	local viewportY = camera.ViewportSize.Y
	
	if not indicatorTable[1] then return end
	local bufferSize = indicatorTable[1][2].AbsoluteSize.X
	
	
	local maxBoundsX = viewportX - (bufferSize * 2)
	local maxBoundsY = viewportY - (bufferSize * 2)
	
	
	local camCFrame = camera.CFrame
	local screenHypotenuse = math.sqrt((maxBoundsX/2)^2+(maxBoundsY/2)^2)
	
	
	local cameraForward
	do
		local cameraForward3D = camera.CFrame.LookVector
		cameraForward = Vector2.new(cameraForward3D.X, cameraForward3D.Z).Unit
	end

	for _, data in ipairs(indicatorTable) do
		local indicatorUI = data[2]
		if indicatorUI.Visible == false then
			continue
		end

		local position = data[1].WorldPosition

		local screenPosition3d, onScreen = camera:WorldToViewportPoint(position)

		local xPosition = math.clamp(screenPosition3d.X, bufferSize, viewportX - bufferSize)
		local yPosition = math.clamp(screenPosition3d.Y, bufferSize, viewportY - bufferSize)

		

		if (xPosition == screenPosition3d.X) and (yPosition == screenPosition3d.Y) and onScreen then
			indicatorUI.ArrowFrame.Visible = false
		else
			indicatorUI.ArrowFrame.Visible = true
			
			local worldDirection = position - camCFrame.Position
			local relativeDirection = camCFrame:VectorToObjectSpace(worldDirection)
			local relativeDirection2D = Vector2.new(relativeDirection.X, relativeDirection.Y).Unit

			
			local testScreenPoint = relativeDirection2D * screenHypotenuse
			
			local angle = math.atan2(relativeDirection2D.X, relativeDirection2D.Y)
			
			local screenPoint
			if math.abs(testScreenPoint.Y) > maxBoundsY/2 then
				screenPoint = relativeDirection2D * math.abs(maxBoundsY/2/relativeDirection2D.Y)
			else
				screenPoint = relativeDirection2D * math.abs(maxBoundsX/2/relativeDirection2D.X)
			end
			
			xPosition = viewportX / 2 + screenPoint.X
			yPosition = viewportY / 2 - screenPoint.Y
			
			
			indicatorUI.ArrowFrame.Rotation = math.deg(angle)
		end
		

		indicatorUI.Position = UDim2.fromOffset(xPosition, yPosition)
	end
end

RunService.RenderStepped:Connect(updateIndicatorPositions)

player:GetPropertyChangedSignal("TeamColor"):Connect(function()
	for _, data in ipairs(indicatorTable) do
		updateIndicatorUI(data[1], data[2])
	end
end)
