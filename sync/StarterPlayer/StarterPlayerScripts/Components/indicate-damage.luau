--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local spr = require(ReplicatedStorage.Modules.spr)
local temporary_layer_collector = require(script.Parent.Parent.Utilities["temporary-layer-collector"])

-- indicate-damage.luau
-- not to be confused with damage-indicator.
-- allows players to identify
-- what direction they were hit from.

local module = {}
module._connection = nil

local expiry_time = 5

local camera = workspace.CurrentCamera

local function createIndicator(ancestor: Instance?)
	local Instances = {
		DamageIndicatorImage = Instance.new("ImageLabel"),
	}

	Instances.DamageIndicatorImage.Name = "DamageIndicatorImage"
	Instances.DamageIndicatorImage.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.DamageIndicatorImage.Size = UDim2.new(0.3, 0, 0.03, 0)
	Instances.DamageIndicatorImage.BorderColor3 = Color3.fromRGB(27, 42, 53)
	Instances.DamageIndicatorImage.BackgroundTransparency = 1
	Instances.DamageIndicatorImage.Position = UDim2.new(0.5, 0, 0.09, 0)
	Instances.DamageIndicatorImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instances.DamageIndicatorImage.ImageColor3 = Color3.fromRGB(255, 0, 0)
	Instances.DamageIndicatorImage.ScaleType = Enum.ScaleType.Fit
	Instances.DamageIndicatorImage.Image = "rbxassetid://12177429438"
	Instances.DamageIndicatorImage.Parent = ancestor or ReplicatedStorage

	return Instances.DamageIndicatorImage
end

local function getCentreCoordinate()
	local coordinate = camera.CFrame

	local position = coordinate.Position
	local look_at = coordinate.LookVector * Vector3.new(1, 0, 1)

	local centre = CFrame.new(position, position + look_at)

	return centre
end

local function calculateAngle(centre: CFrame, point: Vector3)
	local damage_direction = centre:PointToObjectSpace(point)

	local theta = math.atan2(damage_direction.Z, damage_direction.X)
	local angle = math.deg(theta) * 90

	return angle -- angle in degrees
end

--[[
   @param origin `Vector3` - The origin of the damage
]]
function module:OnDamaged(origin: Vector3)
	local centre_coordinate = getCentreCoordinate()
	local angle = calculateAngle(centre_coordinate, origin)

	local layer_collector = temporary_layer_collector.new("DamageIndicator") :: ScreenGui

	local indicator = createIndicator(layer_collector)

	indicator.Visible = true
	spr.target(indicator, 0.3, 1, {
		ImageTransparency = 0,
	})
	spr.target(indicator, 0.7, 0.5, {
		Rotation = angle,
	})

	local conn = nil

	conn = RunService.Heartbeat:Connect(function()
		local centre_coordinate = getCentreCoordinate()
		local angle = calculateAngle(centre_coordinate, origin)

		indicator.Rotation = angle
	end)

	task.wait(expiry_time)

	spr.target(indicator, 0.95, 1, {
		ImageTransparency = 0,
	})
	spr.completed(indicator, function()
		if conn then
			conn:Disconnect()
		end

		temporary_layer_collector:Remove(layer_collector)
	end)
end

return module
