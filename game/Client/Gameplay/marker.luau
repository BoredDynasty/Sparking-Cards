--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local spr = require(ReplicatedStorage.Modules.spr)

-- marker.luau

local player = playerMarshaller.get()
local character = player.Character

local camera = gamecamera.camera

export type indicator = {
	attachment: Attachment,
	interface: CanvasGroup,
}

export type indicator_instance = BasePart & {
	Marker: BillboardGui & {
		CanvasGroup: CanvasGroup & {
			Background: Frame & {
				TextLabel: TextLabel, -- Label to show damage amount
			},
			Arrow: ImageLabel,
		},
	},
}

local marker_module = {
	indicators = {} :: { indicator },
	newIndicator = SignalPlus(),
	_offset = bit32.band(45, 25) * 5, -- 45
}

function marker_module._remove(attachment)
	for i, data in ipairs(marker_module.indicators) do
		if data.attachment ~= attachment or not data.interface or not data.update then
			return
		end
		data.interface:Destroy()

		table.remove(marker_module.indicators, i)
	end
end

function marker_module._updateMeters(marker: indicator_instance)
	local rootPart = character.PrimaryPart

	local position = rootPart.Position
	local marker_position = marker.Position

	local meters = (position - marker_position).Magnitude * 0.28

	marker.Marker.CanvasGroup.Background.TextLabel.Text = `{meters}m`
end

function marker_module._update(marker: indicator_instance)
	if not marker then
		return
	end

	local viewportX, viewportY = camera.ViewportSize.X, camera.ViewportSize.Y

	local bufferSize = marker.Marker.CanvasGroup.Background.AbsoluteSize.X

	local maxBoundsX = viewportX - (bufferSize * 2)
	local maxBoundsY = viewportY - (bufferSize * 2)

	local coordinate = camera.CFrame
	local screenHypotenuse = math.sqrt((maxBoundsX / 2) ^ 2 + (maxBoundsY / 2) ^ 2)

	local forward_vec = coordinate.LookVector
	forward_vec = Vector2.new(forward_vec.X, forward_vec.Z).Unit

	local attachment = marker:FindFirstAncestorOfClass("Attachment") :: Attachment

	local position = attachment.WorldPosition

	local screenPosition, onScreen = camera:WorldToViewportPoint(position)

	local xPosition, yPosition =
		math.clamp(screenPosition.X, bufferSize, viewportX - bufferSize),
		math.clamp(screenPosition.Y, bufferSize, viewportY - bufferSize)

	local completed_flag = observer.new(true)

	if (xPosition == screenPosition.X) and (yPosition == screenPosition.Y) and onScreen then
		marker.Marker.CanvasGroup.Arrow.Visible = false
	else
		spr.completed(marker.Marker.CanvasGroup.Arrow, function()
			completed_flag:Set(true)
		end)

		if not completed_flag:Get() then
			return
		end

		marker.Marker.CanvasGroup.Arrow.Visible = true

		local world_direction = position - coordinate.Position
		local relative_direction = coordinate:VectorToObjectSpace(world_direction)
		local relative_direction2D = Vector2.new(relative_direction.X, relative_direction.Y).Unit

		local testScreen_Point = relative_direction2D * screenHypotenuse

		local angle = math.atan2(relative_direction2D.X, relative_direction.Y)

		local screen_point = 0
		if math.abs(testScreen_Point.Y) > maxBoundsY / 2 then
			screen_point = relative_direction2D * math.abs(maxBoundsY / 2 / relative_direction2D.Y)
		else
			screen_point = relative_direction2D * math.abs(maxBoundsX / 2 / relative_direction2D.X)
		end

		xPosition = viewportX / 2 + screen_point.X
		yPosition = viewportY / 2 - screen_point.Y

		marker.Marker.CanvasGroup.Arrow.Rotation = math.deg(angle) - marker_module._offset
		spr.target(marker.Marker.CanvasGroup.Arrow, 0.7, 1, {
			Rotaion = math.deg(angle) - marker_module._offset,
		})
	end

	marker.Marker.CanvasGroup.Position = UDim2.fromOffset(xPosition, yPosition)
end

local function instanceAdded(instance: Instance)
	if instance:IsA("Attachment") and instance:GetAttribute("Indicator") then
		marker_module._remove(instance)

		local marker = fetchAsset("Marker") :: indicator_instance
		marker.Marker.Adornee = instance

		table.insert(marker_module.indicators, {
			attachment = instance,
			interface = marker.Marker.CanvasGroup,
		})
	end
end

local function update()
	for i, data in ipairs(marker_module.indicators) do
		marker_module._update(data.interface.Parent.Parent :: indicator_instance)
	end
end

gamecamera:Bind("indicator", update)
