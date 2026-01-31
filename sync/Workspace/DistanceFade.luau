--[[
	A client-side distance fade effect
	Made by xander22 (youtube.com/@xand3r22, x.com/x4nder22)

	HOW TO USE:
	As this is a client-side only effect, the module must be called from a local script or a script using the client run context
	To apply the effect to a part, it must be a BasePart
	
	1. To set the module up, call [var] = [module].new() in a local script. You can add your own settings as a parameter or use step 4
	2. For any face you want to apply the effect to, use [var]:AddFace(part, normalEnum). You can also remove a part using :RemovePart()
	3. Use :Step() to update the effect on all added parts. It's recommended to put this in RunService.Heartbeat. If a position isn't added
	   as an argument, the module will automatically use the local character's HumanoidRootPart
	4. Use :UpdateSettings(settingsTable) to apply your own settings at any time. The default settings are listed below.
	   Note: If you want to reset the settings to default, call :UpdateSettings() with no arguments
	5. If you want to get rid of the effect and clean the workspace, use :Clear()
]]

local DistanceFade = {}
DistanceFade.__index = DistanceFade

-- default settings, can be overriden with custom settings by using UpdateSettings()
local DEFAULT_SETTINGS = {
	["DistanceOuter"] = 16, -- Distance at which the effect starts to appear
	["DistanceInner"] = 4, -- Distance at which the effect is fully visible
	["EffectRadius"] = 16, -- Size of the effect when in range
	["EffectRadiusMin"] = 0, -- Size of the effect when out of range
	["EdgeDistanceCalculations"] = false, -- * When set to true, distance to target is calculated from the face edges rather than the face itself. Can be more accurate in certain cases
	["Texture"] = "rbxassetid://18838056070", -- TextureId
	["TextureTransparency"] = 0, -- Transparency of the texture when in range
	["TextureTransparencyMin"] = 1, -- Transparency of the texture when out of range
	["BackgroundTransparency"] = 1, -- Transparency of the texture background when in range
	["BackgroundTransparencyMin"] = 1, -- Transparency of the texture background when out of range
	["TextureColor"] = Color3.fromRGB(255, 255, 255), -- Color of the texture
	["BackgroundColor"] = Color3.fromRGB(255, 255, 255), -- Color of the texture background
	["TextureSize"] = Vector2.new(8, 8), -- Size of the texture in studs per tile. Can potentially cause clipping issues if greater than EffectRadius * 2
	["TextureOffset"] = Vector2.new(0, 0), -- Texture offset in studs
	-- SurfaceGui settings
	["ZOffset"] = 0,
	["AlwaysOnTop"] = false,
	["Brightness"] = 1,
	["LightInfluence"] = 0,
	["MaxDistance"] = 1000,
	["PixelsPerStud"] = 100,
	["SizingMode"] = Enum.SurfaceGuiSizingMode.PixelsPerStud
}

-- * When EdgeDistanceCalculations is false, distance to target is calculated from the normal. Ex if you're facing the effect head on, and back up, the distance will be accurately
-- calculated, however when you move left and right, the distance remains the same. Tends to look better when multiple target parts are stacked next to each other.
-- When EdgeDistanceCalculations is set to true, distance is calculated from each edge of the target face rather than the normal, which gives an accurate distance calculation even
-- when moving parallel to the face. Sometimes it looks better, sometimes it doesn't, it really depends from case to case

-- sets up folders where SurfaceParts and SurfaceGuis will be stored
local function SetUpFolders(obj)
	--[[if obj.GuiFolder == nil then
		-- search workspace for already existing folder, if none found, create a new one
		local folder = game.Players.LocalPlayer.PlayerGui:FindFirstChild("DistanceFade_SurfaceGuis")
		if folder ~= nil then
			obj.GuiFolder = folder
		else
			obj.GuiFolder = Instance.new("Folder")
			obj.GuiFolder.Name = "DistanceFade_SurfaceGuis"
			if game:GetService("RunService"):IsRunning() then
				obj.GuiFolder.Parent = game.Players.LocalPlayer.PlayerGui
			else
				obj.GuiFolder.Parent = game.StarterGui --for when testing effect with StudioExecutor
			end
		end
	end
	]]
	if obj.WorkspaceFolder == nil then
		local folder = game.Workspace:FindFirstChild("DistanceFade_SurfaceParts")
		if folder ~= nil then
			obj.WorkspaceFolder = folder
		else
			obj.WorkspaceFolder = Instance.new("Folder")
			obj.WorkspaceFolder.Name = "DistanceFade_SurfaceParts"
			obj.WorkspaceFolder.Parent = workspace
		end
	end
end

function DistanceFade.new()
	local obj = {
		Settings = {},
		FaceSettings = {},
		TargetParts = {},
		WorkspaceFolder = nil,
		--GuiFolder = nil,
	}
	setmetatable(obj, DistanceFade)
	obj.Settings = {}
	for i,v in DEFAULT_SETTINGS do
		obj.Settings[i] = v
	end
	SetUpFolders(obj)

	return obj
end

-- updates settings. 'settingsTable' argument should have the same format as DEFAULT_SETTINGS. Leave arguments empty to reset settings to default
function DistanceFade:UpdateSettings(settingsTable)
	if self.Settings == nil then
		self.Settings = {}
	end

	if settingsTable == nil then
		for i,v in DEFAULT_SETTINGS do
			self.Settings[i] = v
		end
		return
	end
	assert(type(settingsTable) == "table", "Expected table as parameter")

	for i,v in DEFAULT_SETTINGS do
		if settingsTable[i] ~= nil then
			self.Settings[i] = settingsTable[i]
		elseif self.Settings[i] == nil then
			self.Settings[i] = v
		end
	end
end

-- updates individual settings per face (overrides global settings). Supports all default settings
function DistanceFade:UpdateFaceSettings(targetPart: BasePart, normal:Enum.NormalId?, settingsTable)
	if self.FaceSettings[targetPart] == nil then
		self.FaceSettings[targetPart] = {}
	end
	if self.FaceSettings[targetPart][normal] == nil then
		self.FaceSettings[targetPart][normal] = {}
	end

	if settingsTable == nil then 
		self.FaceSettings[targetPart][normal] = nil
		return
	end
	assert(type(settingsTable) == "table", "Expected table as parameter")

	for i,v in pairs(settingsTable) do
		self.FaceSettings[targetPart][normal][i] = v
	end
end


---------------------- NORMAL FUNCTIONS ----------------------

-- gets look vector of the part's normal
local function GetNormalDirection(normal, targetPart)
	local dir

	if normal == Enum.NormalId.Front then
		dir = targetPart.CFrame.LookVector
	elseif normal == Enum.NormalId.Back then
		dir = -targetPart.CFrame.LookVector
	elseif normal == Enum.NormalId.Left then
		dir = -targetPart.CFrame.RightVector
	elseif normal == Enum.NormalId.Right then
		dir = targetPart.CFrame.RightVector
	elseif normal == Enum.NormalId.Top then
		dir = targetPart.CFrame.UpVector
	elseif normal == Enum.NormalId.Bottom then
		dir = -targetPart.CFrame.UpVector
	end

	return dir
end

-- gets the offset of a normal from the targetPart's origin
local function GetNormalOffset(normal, targetPart)
	local offset = Vector3.new()
	local rotation = CFrame.new()

	if normal == Enum.NormalId.Front then
		offset = (targetPart.Size.Z / 2) * targetPart.CFrame.LookVector
		rotation = CFrame.Angles(0, 0, 0)
	elseif normal == Enum.NormalId.Back then
		offset = (targetPart.Size.Z / 2) * -targetPart.CFrame.LookVector
		rotation = CFrame.Angles(0, math.rad(180), 0)
	elseif normal == Enum.NormalId.Left then
		offset = (targetPart.Size.X / 2) * -targetPart.CFrame.RightVector
		rotation = CFrame.Angles(0, math.rad(90), 0)
	elseif normal == Enum.NormalId.Right then
		offset = (targetPart.Size.X / 2) * targetPart.CFrame.RightVector
		rotation = CFrame.Angles(0, math.rad(-90), 0)
	elseif normal == Enum.NormalId.Top then
		offset = (targetPart.Size.Y / 2) * targetPart.CFrame.UpVector
		rotation = CFrame.Angles(math.rad(90), 0, 0)
	elseif normal == Enum.NormalId.Bottom then
		offset = (targetPart.Size.Y / 2) * -targetPart.CFrame.UpVector
		rotation = CFrame.Angles(math.rad(-90), 0, 0)
	end

	return offset, rotation
end

-- gets the positions of the sides of a BasePart based on an inputted normal
local function GetSidePositionsOfPartAlongNormal(worldPosition, partCFrame, normal, size) --partCFrame is to get the right/up vectors along the front normal
	local halfWidth, halfHeight, halfLength
	local rightVector, upVector

	local faceOffset
	if normal == Enum.NormalId.Front or normal == Enum.NormalId.Back then
		halfWidth = size.X / 2
		halfHeight = size.Y / 2
		halfLength = size.Z / 2
		rightVector = normal == Enum.NormalId.Front and partCFrame.RightVector or -partCFrame.RightVector
		upVector = partCFrame.UpVector

		faceOffset = normal == Enum.NormalId.Front and partCFrame.LookVector * halfLength or -partCFrame.LookVector * halfLength
	elseif normal == Enum.NormalId.Left or normal == Enum.NormalId.Right then
		halfWidth = size.Z / 2
		halfHeight = size.Y / 2
		halfLength = size.X / 2
		rightVector = normal == Enum.NormalId.Left and partCFrame.LookVector or -partCFrame.LookVector
		upVector = partCFrame.UpVector

		faceOffset = normal == Enum.NormalId.Left and -partCFrame.RightVector * halfLength or partCFrame.RightVector * halfLength
	elseif normal == Enum.NormalId.Top or normal == Enum.NormalId.Bottom then
		halfWidth = size.X / 2
		halfHeight = size.Z / 2
		halfLength = size.Y / 2
		rightVector = partCFrame.RightVector
		upVector = normal == Enum.NormalId.Top and -partCFrame.LookVector or partCFrame.LookVector

		faceOffset = normal == Enum.NormalId.Top and partCFrame.UpVector * halfLength or -partCFrame.UpVector * halfLength
	end
	local facePosition = worldPosition + faceOffset

	local left = facePosition - rightVector * halfWidth
	local right = facePosition + rightVector * halfWidth
	local top = facePosition + upVector * halfHeight
	local bottom = facePosition - upVector * halfHeight

	return {
		Left = left,
		Right = right,
		Top = top,
		Bottom = bottom
	}
end

-- converts a position to a normal's local space
local function ToNormalSpace(targetCFrame, worldPosition, surfaceNormal)
	local newCFrame = targetCFrame
	local localPosition = newCFrame:PointToObjectSpace(worldPosition)
	local projectedPosition
	if surfaceNormal == Enum.NormalId.Front then
		projectedPosition = localPosition
	elseif surfaceNormal == Enum.NormalId.Back then
		projectedPosition = Vector3.new(-localPosition.X, localPosition.Y, localPosition.Z)
	elseif surfaceNormal == Enum.NormalId.Left then
		projectedPosition = Vector3.new(-localPosition.Z, localPosition.Y, localPosition.X)
	elseif surfaceNormal == Enum.NormalId.Right then
		projectedPosition = Vector3.new(localPosition.Z, localPosition.Y, localPosition.X)	
	elseif surfaceNormal == Enum.NormalId.Top then
		projectedPosition = Vector3.new(localPosition.X, localPosition.Z, localPosition.Y)
	else	
		projectedPosition = Vector3.new(localPosition.X, -localPosition.Z, localPosition.Y)
	end

	return projectedPosition
end


---------------------- ADD/REMOVE PARTS ----------------------

-- creates an individual tile and sets all necessary values, used by CreateGrid()
local function NewTile()
	local tile = Instance.new("Frame")
	tile.BackgroundTransparency = 1
	local scaleFrame = Instance.new("Frame")
	scaleFrame.BackgroundTransparency = 1
	scaleFrame.ClipsDescendants = true
	scaleFrame.AnchorPoint = Vector2.new(.5, .5)
	scaleFrame.Position = UDim2.new(.5, 0, .5, 0)
	scaleFrame.Size = UDim2.new(1, 0, 1, 0)
	scaleFrame.Name = "ScaleFrame"
	scaleFrame.Parent = tile
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.BackgroundTransparency = 1
	imageLabel.Parent = scaleFrame
	imageLabel.AnchorPoint = Vector2.new(.5, .5)
	imageLabel.Position = UDim2.new(.5, 0, .5, 0)
	imageLabel.Size = UDim2.new(9, 0, 9, 0)
	imageLabel.ScaleType = Enum.ScaleType.Tile
	imageLabel.TileSize = UDim2.new(.111, 0, .111, 0)
	return tile
end

-- creates grid of tiles inside the SurfaceGui, used by SetUpSurface()
local function CreateGrid(resolution, surfaceGui)
	local sizeNum = 4
	local tiles = {}
	local size = 1 / sizeNum
	for i = 1, sizeNum do
		for j = 1, sizeNum do
			local tile = NewTile()
			tile.Parent = surfaceGui.ScaleFrame
			tile.Size = UDim2.new(size, 0, size, 0)
			tile.Position = UDim2.new((j - 1) * size, 0, (i - 1) * size, 0)
			tile.BorderSizePixel = 0
			table.insert(tiles, tile)
			tile.Name = tostring(#tiles)
		end
	end
	return tiles
end

-- applies UIGradient to the tiles, used by SetUpSurface()
local function ApplyCircularGradient(frames)
	local cornerGradients = {
		[1] = 45, -- index of frame on the grid, angle of UIGradient
		[4] = 135,
		[13] = -45,
		[16] = -135
	}
	local sideGradients = {
		[2] = 75,
		[3] = 105,
		[5] = 15,
		[8] = 165,
		[9] = -15,
		[12] = -165,
		[14] = -75,
		[15] = -105
	}
	-- loops through the grid of tiles, creates UIGradient, and applies rotation based on the above values
	for i = 1, #frames do
		local frame = frames[i]
		local isCorner = false
		for index,angle in cornerGradients do
			if index == i then
				local gradient = Instance.new("UIGradient")
				gradient.Parent = frame.ScaleFrame.ImageLabel
				gradient.Rotation = angle
				isCorner = true
				break
			end
		end
		if isCorner then continue end --check next frame
		for index,angle in sideGradients do
			if index == i then
				local gradient = Instance.new("UIGradient")
				gradient.Parent = frame.ScaleFrame.ImageLabel
				gradient.Rotation = angle
				break
			end
		end
	end
end

-- sets up surface part and SurfaceGui for a targeted face
local function SetUpSurface(targetPart, normal, obj)
	local surfacePart = Instance.new("Part")
	surfacePart.Transparency = 1
	surfacePart.Parent = obj.WorkspaceFolder
	surfacePart.Size = Vector3.zero
	surfacePart.Anchored = true
	surfacePart.CanCollide = false
	surfacePart.CanTouch = false
	surfacePart.CanQuery = false
	surfacePart.Locked = true
	local offset, rotation = GetNormalOffset(normal, targetPart)
	surfacePart.CFrame = targetPart.CFrame * CFrame.new(offset) * rotation
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.ResetOnSpawn = false
	surfaceGui.ClipsDescendants = true
	--surfaceGui.Parent = obj.GuiFolder
	surfaceGui.Parent = game.Players.LocalPlayer.PlayerGui
	surfaceGui.Adornee = surfacePart
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 1000
	local scaleFrame = Instance.new("Frame")
	scaleFrame.Size = UDim2.new(1, 0, 1, 0)
	scaleFrame.AnchorPoint = Vector2.new(.5, .5)
	scaleFrame.Position = UDim2.new(.5, 0, .5, 0)
	scaleFrame.BackgroundTransparency = 1
	scaleFrame.Name = "ScaleFrame"
	scaleFrame.Parent = surfaceGui
	surfaceGui.Enabled = false --set true whenever in range
	local resolution = obj.Settings.EffectResolution
	local tiles = CreateGrid(resolution, surfaceGui)
	ApplyCircularGradient(tiles, resolution)

	return surfacePart, surfaceGui
end

-- adds a part's face to the target list (can have multiple faces on the same part). 'targetPart' should be a BasePart and 'normal' should be an Enum.NormalId
function DistanceFade:AddFace(targetPart: BasePart, normal: Enum.NormalId?)
	if normal == nil then
		normal = Enum.NormalId.Front
	end
	local surfacePart, surfaceGui = SetUpSurface(targetPart, normal, self)
	local info = {
		["SurfaceNormal"] = normal,
		["SurfacePart"] = surfacePart,
		["SurfaceGui"] = surfaceGui
	}
	if self.TargetParts[targetPart] == nil then
		self.TargetParts[targetPart] = {}
	end
	self.TargetParts[targetPart][normal] = info
end

-- removes a face from the target list and clears the effect from workspace/gui
function DistanceFade:RemoveFace(targetPart: BasePart, normal: Enum.NormalId?)
	if normal == nil then
		normal = Enum.NormalId.Front
	end
	if self.TargetParts[targetPart] == nil then return end
	local info = self.TargetParts[targetPart][normal]
	if info == nil then return end
	info.SurfacePart:Destroy()
	info.SurfaceGui:Destroy()
	self.TargetParts[targetPart][normal] = nil
	if next(self.TargetParts[targetPart]) == nil then -- dictionary is empty
		self.TargetParts[targetPart] = nil
		-- destroy workspace/gui folders if empty
		if self.WorkspaceFolder ~= nil and #self.WorkspaceFolder:GetChildren() == 0 then
			self.WorkspaceFolder:Destroy()
			self.WorkspaceFolder = nil
		end
		--[[if self.GuiFolder ~= nil and #self.GuiFolder:GetChildren() == 0 then
			self.GuiFolder:Destroy()
			self.GuiFolder = nil
		end
		]]
	end
end

-- clears all distancefades from the workspace 
function DistanceFade:Clear()
	for _,targetPart in self.TargetParts do
		for normal, info in targetPart do
			info.SurfacePart:Destroy()
			info.SurfaceGui:Destroy()
		end
	end
	-- destroy workspace/gui folders if empty
	if self.WorkspaceFolder ~= nil and #self.WorkspaceFolder:GetChildren() == 0 then
		self.WorkspaceFolder:Destroy()
		self.WorkspaceFolder = nil
	end
	--[[if self.GuiFolder ~= nil and #self.GuiFolder:GetChildren() == 0 then
		self.GuiFolder:Destroy()
		self.GuiFolder = nil
	end
	]]
	table.clear(self.TargetParts)
end


---------------------- STEP ----------------------

-- the offset amount multipliers aka their distance on the grid from the origin tile on the bottom right. Modifying can mess with the seamless effect
local offsetMultipliers = {
	[1] = {
		["OffsetX"] = 3,
		["OffsetY"] = 3
	},
	[2] = {
		["OffsetX"] = 2,
		["OffsetY"] = 3
	},
	[3] = {
		["OffsetX"] = 1,
		["OffsetY"] = 3
	},
	[4] = {
		["OffsetX"] = 0,
		["OffsetY"] = 3
	},
	[5] = {
		["OffsetX"] = 3,
		["OffsetY"] = 2
	},
	[6] = {
		["OffsetX"] = 2,
		["OffsetY"] = 2
	},
	[7] = {
		["OffsetX"] = 1,
		["OffsetY"] = 2
	},
	[8] = {
		["OffsetX"] = 0,
		["OffsetY"] = 2
	},
	[9] = {
		["OffsetX"] = 3,
		["OffsetY"] = 1
	},
	[10] = {
		["OffsetX"] = 2,
		["OffsetY"] = 1
	},
	[11] = {
		["OffsetX"] = 1,
		["OffsetY"] = 1
	},
	[12] = {
		["OffsetX"] = 0,
		["OffsetY"] = 1
	},
	[13] = {
		["OffsetX"] = 3,
		["OffsetY"] = 0
	},
	[14] = {
		["OffsetX"] = 2,
		["OffsetY"] = 0
	},
	[15] = {
		["OffsetX"] = 1,
		["OffsetY"] = 0
	},
	[16] = {
		["OffsetX"] = 0,
		["OffsetY"] = 0
	},
}

-- updates imageLabel's position to create the illusion of a seamless tiling texture
local function UpdateTextureOffset(offsetX, offsetY, sizeOfOneTileX, sizeOfOneTileY)
	local function ConvertToRange(value, sizeOfOneTile)
		local decimalPart = math.abs(value) / sizeOfOneTile % 1
		if value < 0 then
			return -decimalPart
		else
			return decimalPart
		end
	end
	local percentOffsetU = ConvertToRange(offsetX, sizeOfOneTileX)
	local percentOffsetV = ConvertToRange(offsetY, sizeOfOneTileY)
	return UDim2.new(.5 + percentOffsetU * sizeOfOneTileX, 0, .5 + percentOffsetV * sizeOfOneTileY, 0)
end

-- makes gradient offset not local to UIGradient rotation, used by UpdateSideGradient and UpdateCornerGradient
local function AdjustGradientOffset(uiGradient, offset)
	local rotationRadians = math.rad(uiGradient.Rotation)
	local cosTheta = math.cos(rotationRadians)
	local sinTheta = math.sin(rotationRadians)
	local adjustedOffsetX = offset.X * cosTheta - offset.Y * sinTheta
	local adjustedOffsetY = offset.X * sinTheta + offset.Y * cosTheta

	return Vector2.new(adjustedOffsetX, adjustedOffsetY)
end

-- updates tile's UIGradient transparency curve
function UpdateSideGradient(tile)
	local uiGradient = tile.ScaleFrame.ImageLabel.UIGradient
	local tileSize = tile.ScaleFrame.Size
	local imagePosition = tile.ScaleFrame.ImageLabel.Position

	local switchCorrectionX = -(imagePosition.X.Scale + 0.5) / 200--when image position switches from -.5 to 0.5, there's a noticeable cut, this value helps mitigate it
	if tile.Name == "2" or tile.Name == "3" or tile.Name == "14" or tile.Name == "15" then
		switchCorrectionX = 0
	end
	local switchCorrectionY = -(imagePosition.Y.Scale + 0.5) / 200
	if tile.Name == "5" or tile.Name == "8" or tile.Name == "9" or tile.Name == "12" then
		switchCorrectionY = 0
	end
	if tile.Name == "5" or tile.Name == "9" then
		switchCorrectionX += 0.01
	end
	if tile.Name == "2" or tile.Name == "3" then
		switchCorrectionY += 0.01
	end
	local offsetX = (imagePosition.X.Scale - 0.5) / 9 + switchCorrectionX
	local offsetY = (imagePosition.Y.Scale - 0.5) / 9 + switchCorrectionY
	if tile.Name == "12" or tile.Name == "9" or tile.Name == "2" or tile.Name == "3" then
		offsetY = -offsetY
	end
	if tile.Name == "5" or tile.Name == "9" or tile.Name == "15" or tile.Name == "3" then
		offsetX = -offsetX
	end
	if tile.Name == "2" or tile.Name == "3" or tile.Name == "14" or tile.Name == "15" then
		local tempX = offsetX
		offsetX = offsetY
		offsetY = tempX
	end

	local defaultCurve = { --indexes to construct transparency curve
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(.444, 1),
		NumberSequenceKeypoint.new(.466, 1),
		NumberSequenceKeypoint.new(.555, 0),
		NumberSequenceKeypoint.new(1, 0)
	}

	local newCurveTable = {}
	for i = 1, #defaultCurve do
		local keypoint = defaultCurve[i]
		local newTime = keypoint.Time + offsetX
		newCurveTable[i] = NumberSequenceKeypoint.new(math.clamp(newTime, 0, 1), keypoint.Value)
	end

	if newCurveTable[1].Time > 0 then
		table.insert(newCurveTable, 1, NumberSequenceKeypoint.new(0, newCurveTable[1].Value))
	end
	if newCurveTable[#newCurveTable].Time < 1 then
		table.insert(newCurveTable, NumberSequenceKeypoint.new(1, newCurveTable[#newCurveTable].Value))
	end

	for _,v in newCurveTable do
		if v.Time < 0 then
			v.Time = 0
		elseif v.Time > 1 then
			v.Time = 1
		end
	end
	uiGradient.Transparency = NumberSequence.new(newCurveTable)
	uiGradient.Offset = AdjustGradientOffset(uiGradient, Vector2.new((-offsetY / 4), 0))
end

-- same as above, slightly different logic for corner gradient because it deals with offsets on X and Y axis at the same time, rather than one or the other
function UpdateCornerGradient(tile)
	local uiGradient = tile.ScaleFrame.ImageLabel.UIGradient
	local tileSize = tile.ScaleFrame.Size
	local imagePosition = tile.ScaleFrame.ImageLabel.Position

	local switchCorrectionX = -(imagePosition.X.Scale + 0.5) / 75
	local switchCorrectionY = -(imagePosition.Y.Scale + 0.5) / 75

	local offsetX = (imagePosition.X.Scale - 0.5) / 9 + switchCorrectionX
	local offsetY = (imagePosition.Y.Scale - 0.5) / 9 + switchCorrectionY

	if tile.Name == "13" or tile.Name == "1" then
		offsetX = -offsetX
	end
	if tile.Name == "1" or tile.Name == "4" then
		offsetY = -offsetY
	end

	-- I got these values by eye balling the gradient, they can be adjusted to potentially get a more accurate circle
	local extraOffset = 0
	if tile.Name == "1" then
		extraOffset = -.015
	elseif tile.Name == "4" then
		extraOffset = .0025
	elseif tile.Name == "16" then
		extraOffset = .02
	elseif tile.Name == "13" then
		extraOffset = .0025	
	end

	local adjustedOffsetX = (offsetX + offsetY) / math.sqrt(2) + extraOffset
	local adjustedOffsetY = (offsetX + offsetY) / math.sqrt(2) + extraOffset

	local defaultCurve = {
		NumberSequenceKeypoint.new(0, 1), 
		NumberSequenceKeypoint.new(0.444, 1),
		NumberSequenceKeypoint.new(.51, 1),
		NumberSequenceKeypoint.new(.555, .2),
		NumberSequenceKeypoint.new(1, .2)
	}

	local newCurveTable = {}
	for i = 1, #defaultCurve do
		local keypoint = defaultCurve[i]
		local newTime = keypoint.Time + adjustedOffsetX
		newCurveTable[i] = NumberSequenceKeypoint.new(math.clamp(newTime, 0, 1), keypoint.Value)
	end

	if newCurveTable[1].Time > 0 then
		table.insert(newCurveTable, 1, NumberSequenceKeypoint.new(0, newCurveTable[1].Value))
	end
	if newCurveTable[#newCurveTable].Time < 1 then
		table.insert(newCurveTable, NumberSequenceKeypoint.new(1, newCurveTable[#newCurveTable].Value))
	end

	if tile.Name == "1" or tile.Name == "4" then --corrects weird gradient behavior on tile 1 and 4 when multiple points have a time value of 1
		local tempCurve = {}
		for i,v in newCurveTable do
			if v.Time == 1 then
				for index = 1, i do
					table.insert(tempCurve, newCurveTable[index])
				end
				newCurveTable = tempCurve
				break
			end
		end
	end

	for _,v in newCurveTable do
		if v.Time < 0 then
			v.Time = 0
		elseif v.Time > 1 then
			v.Time = 1
		end
	end
	uiGradient.Transparency = NumberSequence.new(newCurveTable)
	uiGradient.Offset = AdjustGradientOffset(uiGradient, Vector2.new((-adjustedOffsetY / 4), 0))
end

-- main logic of the module, called every interval. Put in RunService.Heartbeat for smooth interpolation. targetPos = the position the effect is based around
function DistanceFade:Step(targetPos: Vector3?) 
	SetUpFolders(self) --call every frame in case folders were deleted at runtime

	-- modify settings to make sure they're in bounds
	local settingsTable = self.Settings
	if settingsTable.EffectRadiusMin > settingsTable.EffectRadius then
		settingsTable.EffectRadiusMin = settingsTable.EffectRadius
	end
	if settingsTable.DistanceInner > settingsTable.DistanceOuter then
		settingsTable.DistanceInner = settingsTable.DistanceOuter
	end

	if targetPos == nil then
		local localChar = game.Players.LocalPlayer.Character
		if localChar == nil then return end --no valid position to target, don't update simulation
		targetPos = localChar.HumanoidRootPart.Position
	end

	for targetPart, faces in self.TargetParts do
		for face, info in faces do
			-- set unique settings for the face if applicable
			local newTable = {}
			if self.FaceSettings[targetPart] ~= nil and self.FaceSettings[targetPart][face] ~= nil then
				for i,v in settingsTable do
					newTable[i] = v
					if self.FaceSettings[targetPart][face][i] ~= nil then
						newTable[i] = self.FaceSettings[targetPart][face][i]
					end
				end
			end
			local settingsTable = settingsTable
			if next(newTable) ~= nil then
				settingsTable = newTable
			end

			-- declare main variables and set surfaceGui settings
			local surfacePart = info.SurfacePart
			local surfaceGui = info.SurfaceGui
			surfaceGui.ZOffset = settingsTable.ZOffset
			surfaceGui.AlwaysOnTop = settingsTable.AlwaysOnTop
			surfaceGui.Brightness = settingsTable.Brightness
			surfaceGui.LightInfluence = settingsTable.LightInfluence
			surfaceGui.MaxDistance = settingsTable.MaxDistance
			surfaceGui.PixelsPerStud = settingsTable.PixelsPerStud
			surfaceGui.SizingMode = settingsTable.SizingMode
			local targetCFrame = targetPart.CFrame

			-- move info.SurfacePart along target normal, based on input targetPos
			local normalOffset, rotation = GetNormalOffset(info.SurfaceNormal, targetPart)
			local targetNormal = GetNormalDirection(info.SurfaceNormal, targetPart)
			local targetOffset = targetPos - (targetPart.Position + normalOffset)
			local perpendicularOffset = targetOffset - targetNormal * targetOffset:Dot(targetNormal)		
			local newPosition = targetPart.Position + perpendicularOffset + normalOffset	
			local objectCFrame = targetPart.CFrame * CFrame.new(normalOffset) * rotation
			surfacePart.CFrame = CFrame.new(newPosition) * CFrame.fromMatrix(Vector3.new(), objectCFrame.RightVector, objectCFrame.UpVector)

			-- calculate size percent based on distance from surface part/edges of target face
			local distFromPart = (targetPos - surfacePart.Position).Magnitude -- distance calculation first type: checks distance of targetPos from the target part's normal. Has a smoother transition for when multiple target parts are stacked next to eachother
			local targetPartSidePositions = GetSidePositionsOfPartAlongNormal(targetPart.Position, targetPart.CFrame, info.SurfaceNormal, targetPart.Size)
			if settingsTable.EdgeDistanceCalculations then -- distance calculation second type: checks distance of targetPos from each edge of the target part, sets distance based on whichever edge is farthest
				local closestEdgeDistance = math.huge
				local distFromTop = ToNormalSpace(CFrame.new(targetPartSidePositions.Top) * (targetPart.CFrame - targetPart.CFrame.Position), targetPos, info.SurfaceNormal)
				distFromTop = Vector3.new(0, distFromTop.Y, distFromTop.Z).Magnitude
				if distFromTop < closestEdgeDistance then
					closestEdgeDistance = distFromTop
				end
				local distFromBottom = ToNormalSpace(CFrame.new(targetPartSidePositions.Bottom) * (targetPart.CFrame - targetPart.CFrame.Position), targetPos, info.SurfaceNormal)
				distFromBottom = Vector3.new(0, distFromBottom.Y, distFromBottom.Z).Magnitude
				if distFromBottom < closestEdgeDistance then
					closestEdgeDistance = distFromBottom
				end
				local distFromLeft = ToNormalSpace(CFrame.new(targetPartSidePositions.Left) * (targetPart.CFrame - targetPart.CFrame.Position), targetPos, info.SurfaceNormal)
				distFromLeft = Vector3.new(distFromLeft.X, 0, distFromLeft.Z).Magnitude
				if distFromLeft < closestEdgeDistance then
					closestEdgeDistance = distFromLeft
				end
				local distFromRight = ToNormalSpace(CFrame.new(targetPartSidePositions.Right) * (targetPart.CFrame - targetPart.CFrame.Position), targetPos, info.SurfaceNormal)
				distFromRight = Vector3.new(distFromRight.X, 0, distFromRight.Z).Magnitude
				if distFromRight < closestEdgeDistance then
					closestEdgeDistance = distFromRight
				end
				if closestEdgeDistance < distFromPart then
					distFromPart = closestEdgeDistance
				end
			end
			-- sets distancePercent based on distFromPart and DistanceInner/DistanceOuter settings
			local sizeModifier = 1 / (settingsTable.TextureSize.X * 2 / settingsTable.EffectRadius)
			local distancePercent
			if distFromPart < settingsTable.DistanceInner then
				surfaceGui.Enabled = true
				distancePercent = sizeModifier
			elseif distFromPart < settingsTable.DistanceOuter then
				surfaceGui.Enabled = true
				distancePercent = sizeModifier - math.clamp((distFromPart - settingsTable.DistanceInner) / (settingsTable.DistanceOuter - settingsTable.DistanceInner), 0, 1)
			else -- out of bounds, disable gui and continue loop
				surfaceGui.Enabled = false
				distancePercent = 0
				continue
			end

			-- modify size/position of info.SurfacePart based on distance percent and if it's positioned outside of target part bounds
			local modifiedEffectRadius = settingsTable.EffectRadius / sizeModifier
			local distancePercentMod = settingsTable.TextureSize.X * 2 / settingsTable.EffectRadius
			local size = (settingsTable.EffectRadiusMin + (settingsTable.EffectRadius - settingsTable.EffectRadiusMin) * distancePercent * distancePercentMod) * 2
			surfacePart.Size = Vector3.new(size, size, surfacePart.Size.Z)
			local surfacePartSidePositions = GetSidePositionsOfPartAlongNormal(surfacePart.Position, surfacePart.CFrame, Enum.NormalId.Front, surfacePart.Size)
			local targetPartSidePositionsLocal = {
				["Left"] = ToNormalSpace(targetPart.CFrame, targetPartSidePositions.Left, info.SurfaceNormal),
				["Right"] = ToNormalSpace(targetPart.CFrame, targetPartSidePositions.Right, info.SurfaceNormal),
				["Top"] = ToNormalSpace(targetPart.CFrame, targetPartSidePositions.Top, info.SurfaceNormal),
				["Bottom"] = ToNormalSpace(targetPart.CFrame, targetPartSidePositions.Bottom, info.SurfaceNormal)
			}		
			local surfacePartSidePositionsLocal = {
				["Left"] = ToNormalSpace(targetPart.CFrame, surfacePartSidePositions.Left, info.SurfaceNormal),
				["Right"] = ToNormalSpace(targetPart.CFrame, surfacePartSidePositions.Right, info.SurfaceNormal),
				["Top"] = ToNormalSpace(targetPart.CFrame, surfacePartSidePositions.Top, info.SurfaceNormal),
				["Bottom"] = ToNormalSpace(targetPart.CFrame, surfacePartSidePositions.Bottom, info.SurfaceNormal)
			}
			local leftScale = 1
			local rightScale = 1
			if surfacePartSidePositionsLocal.Left.X < targetPartSidePositionsLocal.Left.X then
				leftScale = 1 - (targetPartSidePositionsLocal.Left.X - surfacePartSidePositionsLocal.Left.X) / surfacePart.Size.X
			end
			if surfacePartSidePositionsLocal.Right.X > targetPartSidePositionsLocal.Right.X then
				rightScale = 1 - (surfacePartSidePositionsLocal.Right.X - targetPartSidePositionsLocal.Right.X) / surfacePart.Size.X
			end			
			local topScale = 1
			local bottomScale = 1
			if surfacePartSidePositionsLocal.Bottom.Y < targetPartSidePositionsLocal.Bottom.Y then
				bottomScale = 1 - (targetPartSidePositionsLocal.Bottom.Y - surfacePartSidePositionsLocal.Bottom.Y) / surfacePart.Size.Y
			end
			if surfacePartSidePositionsLocal.Top.Y > targetPartSidePositionsLocal.Top.Y then
				topScale = 1 - (surfacePartSidePositionsLocal.Top.Y - targetPartSidePositionsLocal.Top.Y) / surfacePart.Size.Y
			end		
			if topScale < 0 or bottomScale < 0 or leftScale < 0 or rightScale < 0 then -- if any of the scales are less than 0, then it's out of bounds
				surfaceGui.Enabled = false
				continue 
			end			
			local horizontalScaleMod = 1 - ((1 - leftScale) + (1 - rightScale))
			local verticalScaleMod = 1 - ((1 - topScale) + (1 - bottomScale))
			local horizontalDirMod = (rightScale >= leftScale and 1 or -1)
			local verticalDirMod = (topScale >= bottomScale and 1 or -1)
			local newSize = surfacePart.Size * Vector3.new(horizontalScaleMod, verticalScaleMod, 1)
			local newPosX
			if rightScale < 1 and leftScale < 1 then
				local modifiedHorizontalDirMod = (rightScale - leftScale) * 2
				newPosX = (surfacePart.Size.X - newSize.X) / 2 * modifiedHorizontalDirMod
				local surfacePartCenterX = (surfacePartSidePositionsLocal.Right.X + surfacePartSidePositionsLocal.Left.X) / 2
				local targetPartCenterX = (targetPartSidePositionsLocal.Right.X + targetPartSidePositionsLocal.Left.X) / 2
				local targetPartSizeX = math.abs(targetPartSidePositionsLocal.Right.X - targetPartSidePositionsLocal.Left.X)
				local xOff = (surfacePartCenterX + newPosX + newSize.X) - (targetPartCenterX + targetPartSizeX)
				newPosX = newPosX - xOff

				local maxRange = (rightScale + leftScale) - 1
				horizontalDirMod = modifiedHorizontalDirMod / ((1 - maxRange) * 2)
			else
				newPosX = (surfacePart.Size.X - newSize.X) / 2 * horizontalDirMod
			end
			local newPosY
			if topScale < 1 and bottomScale < 1 then
				local modifiedVerticalDirMod = (topScale - bottomScale) * 2
				newPosY = (surfacePart.Size.Y - newSize.Y) / 2 * modifiedVerticalDirMod
				local surfacePartCenterY = (surfacePartSidePositionsLocal.Top.Y + surfacePartSidePositionsLocal.Bottom.Y) / 2
				local targetPartCenterY = (targetPartSidePositionsLocal.Top.Y + targetPartSidePositionsLocal.Bottom.Y) / 2
				local targetPartSizeY = math.abs(targetPartSidePositionsLocal.Top.Y - targetPartSidePositionsLocal.Bottom.Y)
				local yOff = (surfacePartCenterY + newPosY + newSize.Y) - (targetPartCenterY + targetPartSizeY)
				newPosY = newPosY - yOff

				local maxRange = (topScale + bottomScale) - 1
				verticalDirMod = modifiedVerticalDirMod / ((1 - maxRange) * 2)
			else
				newPosY = (surfacePart.Size.Y - newSize.Y) / 2 * verticalDirMod
			end
			-- ex. if the surfacePart is a stud out of bounds to the right, it scales it in by a stud and repositions it to the right. the texture is also modified
			-- to offset the scale/position change
			surfacePart.CFrame = surfacePart.CFrame * CFrame.new(newPosX, newPosY, 0)
			surfacePart.Size = newSize

			-- multiply info.SurfaceGui.ScaleFrame size and position inverse to info.SurfacePart size/position, so the texture will clip outside TargetPart bounds
			surfaceGui.ScaleFrame.Size = UDim2.new(1 / horizontalScaleMod, 0, 1 / verticalScaleMod, 0)
			surfaceGui.ScaleFrame.Position = UDim2.new(.5 - ((1 - (1 / horizontalScaleMod)) / 2) * horizontalDirMod, 0, .5 - ((1 - (1 / verticalScaleMod)) / 2) * verticalDirMod, 0)

			-- modify transparency based on distance & size
			local transparencyLerpMod = 1
			if sizeModifier > 1 then
				transparencyLerpMod = sizeModifier
			end
			local transparencyLerp = math.min((1 - (distancePercent + (1 - sizeModifier))) / (.8 - (1 - sizeModifier)), 1) * transparencyLerpMod
			if transparencyLerp < 0 then
				transparencyLerp = 1
			end
			local transparency = settingsTable.TextureTransparency + (settingsTable.TextureTransparencyMin - settingsTable.TextureTransparency) * transparencyLerp
			local backgroundTransparency = settingsTable.BackgroundTransparency + (settingsTable.BackgroundTransparencyMin - settingsTable.BackgroundTransparency) * transparencyLerp
			-- reusable variables to be reapplied to each tile in the grid
			local tileSizeMod = 1 / (distancePercent + (sizeModifier - distancePercent) * (settingsTable.EffectRadiusMin / settingsTable.EffectRadius))
			local worldPosition = surfacePart.Position
			local offset = worldPosition - targetNormal * worldPosition:Dot(targetNormal) --offset is distance from the surface part to the target part along the target normal
			local localOffset = ToNormalSpace(targetPart.CFrame, offset, info.SurfaceNormal)
			local scaleOffset = ((1 / tileSizeMod) - 1) * 3 * tileSizeMod
			local borderOffsetX = (-(1 - horizontalScaleMod) / .5) * horizontalDirMod
			local borderOffsetY = (-(1 - verticalScaleMod) / .5) * verticalDirMod
			local textureOffsetX = (-settingsTable.TextureOffset.X / settingsTable.TextureSize.X) * tileSizeMod
			local yScaleMod = settingsTable.TextureSize.Y / settingsTable.TextureSize.X -- needed to calculate tile offset when y size is different from x. Ex if offset is 8,6 yScaleMod is .75
			local yScaleOffsetCoeff = yScaleMod - 1
			local textureOffsetY = (-settingsTable.TextureOffset.Y / settingsTable.TextureSize.X) * tileSizeMod
			-- loops through each tile in the grid and modifies "texture" based on info.SurfacePart size/position, TextureOrigin, and TextureOffset
			for _,v in surfaceGui.ScaleFrame:GetChildren() do
				local imageLabel = v.ScaleFrame.ImageLabel
				imageLabel.Image = settingsTable.Texture
				imageLabel.ImageTransparency = transparency
				imageLabel.ImageColor3 = settingsTable.TextureColor
				imageLabel.BackgroundTransparency = backgroundTransparency
				imageLabel.BackgroundColor3 = settingsTable.BackgroundColor

				local mult = offsetMultipliers[tonumber(v.Name)]
				local sizeOffsetX = ((1 / tileSizeMod) - 1) * tileSizeMod * mult["OffsetX"]
				local sizeOffsetY = ((1 / tileSizeMod) - 1) * tileSizeMod * mult["OffsetY"]

				local offsetX = textureOffsetX + sizeOffsetX + borderOffsetX + scaleOffset + (localOffset.X / (modifiedEffectRadius / 2)) * tileSizeMod
				local offsetY = textureOffsetY + sizeOffsetY + borderOffsetY + scaleOffset + (localOffset.Y / (modifiedEffectRadius / 2)) * tileSizeMod

				-- since imageLabels don't supports offsets when tiled, this recreates the offset effect by moving imageLabel inside a clipDescendants frame.
				-- because there's a UIGradient effect on the imageLabel, there can only be one imageLabel, which can lead to tiling issues when the tile size becomes too large.
				-- it would've been more accurate with multiple imageLabels being rearranged for the tiling effect, but then it wouldn't have supported the gradient.
				-- another option was having 16 viewport frames with a textured part in each viewport frame, but it was way too resource-intensive and had some visual issues
				imageLabel.TileSize = UDim2.new(math.max(.111 * tileSizeMod, .001), 0, math.max(.111 * tileSizeMod * yScaleMod, .001), 0) --math.max is to prevent a size of 0 which causes errors
				-- modified y offset based on yScaleMod. centered around 2nd row so offset is multiplied based on row offset from 2nd row
				if v.Name == "1" or v.Name == "2" or v.Name == "3" or v.Name == "4" then
					offsetY -= (yScaleOffsetCoeff * tileSizeMod)
				elseif v.Name == "9" or v.Name == "10" or v.Name == "11" or v.Name == "12" then
					offsetY += (yScaleOffsetCoeff * tileSizeMod)
				elseif v.Name == "13" or v.Name == "14" or v.Name == "15" or v.Name == "16" then
					offsetY += (yScaleOffsetCoeff * tileSizeMod) * 2
				end
				local textureOffset = UpdateTextureOffset(offsetX, offsetY, tileSizeMod, tileSizeMod * yScaleMod)
				-- this attempts to somewhat offset the tiling issue outlined above
				local outOfBoundsX = 0
				local outOfBoundsY = 0
				if textureOffset.X.Scale > 4.5 then
					outOfBoundsX = textureOffset.X.Scale - 4.5
				elseif textureOffset.X.Scale < -3.5 then
					outOfBoundsX = textureOffset.X.Scale + 3.5
				end
				if textureOffset.Y.Scale > 4.5 then
					outOfBoundsY = textureOffset.Y.Scale - 4.5
				elseif textureOffset.Y.Scale < -3.5 then
					outOfBoundsY = textureOffset.Y.Scale + 3.5
				end
				local clippingOffset = Vector2.new(-outOfBoundsX, -outOfBoundsY)
				if outOfBoundsY < 0 then
					if distancePercent < .125 then
						clippingOffset = Vector2.new(clippingOffset.X, -outOfBoundsY)
					else
						clippingOffset = Vector2.new(clippingOffset.X, 1 * tileSizeMod)
					end
				end
				if outOfBoundsX < 0 then
					if distancePercent < .125 then
						clippingOffset = Vector2.new(-outOfBoundsX, clippingOffset.Y)
					else
						clippingOffset = Vector2.new(1 * tileSizeMod, clippingOffset.Y)
					end
				end
				textureOffset = UDim2.new(textureOffset.X.Scale + clippingOffset.X, 0, textureOffset.Y.Scale + clippingOffset.Y, 0)

				imageLabel.Position = textureOffset

				-- updates gradients on each imageLabel based on its position in the clipsDescendants frame. slightly different logic for side/corner gradients
				local sideGradients = {
					2, 3, 5, 9, 8, 12, 14, 15
				}
				local cornerGradients = {
					1, 4, 13, 16
				}
				if table.find(sideGradients, tonumber(v.Name)) then
					local success, err = pcall(function() -- wrapped in pcall to catch "time must be a valid number" error, prevents output clutter
						UpdateSideGradient(v)
					end)
				elseif table.find(cornerGradients, tonumber(v.Name)) then
					local success, err = pcall(function() -- same as above
						UpdateCornerGradient(v)
					end)
				end			
			end
		end	
	end
end

return DistanceFade
