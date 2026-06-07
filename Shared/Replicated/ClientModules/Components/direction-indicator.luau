--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local spr = require(ReplicatedStorage.Modules.spr)

-- direction-indicator.luau

local module = {}

local player = Players.LocalPlayer
local player_gui = player.PlayerGui

local camera = workspace.CurrentCamera

local expiry_time = 5

local pool = PoolerPlus:CreatePool("IndicatorPool", function()
	return ReplicatedStorage.Interfaces.Indicator:Clone()
end)
pool:AdaptivePreload()

local conn = nil

type Indicator = {
	indicator_image: typeof(pool:Get()),
	expiry_time: number,
	origin: Vector3,
	color: Color3,
}

type DirectionIndicator = setmetatable<Indicator, typeof(module)>

local tracking: { Indicator } = {}

local function getCenter(point: CFrame)
	local look_at = point.LookVector * Vector3.new(1, 0, 1)
	local position = point.Position

	local center = CFrame.new(position, position + look_at)

	return center
end

local function getAngle(center: CFrame, point: Vector3)
	local direction = center:PointToObjectSpace(point)

	local theta = math.atan2(direction.Z, direction.X)
	local angle = math.deg(theta) + 90

	return angle
end

conn = RunService.PreRender:Connect(function()
	if next(tracking) == nil then
		return
	end

	local center = getCenter(camera.CFrame)

	for i, data in ipairs(tracking) do
		local angle = getAngle(center, data.origin)

		spr.stop(data.indicator_image)
		spr.target(data.indicator_image, 0.8, 5, {
			Rotation = angle,
		})
	end
end)

function module.new(origin: Vector3, color: Color3)
	local self = setmetatable({
		indicator_image = pool:Get(),
		expiry_time = expiry_time,
		origin = origin,
		color = color,
	}, module)

	self:Render()

	table.insert(tracking, self)

	return self
end

function module:Render(self: DirectionIndicator)
	local center = getCenter(camera.CFrame)
	local angle = getAngle(center, self.origin)

	self.indicator_image.Parent = player_gui.DirectionIndicator

	self.indicator_image.Visible = true
	self.indicator_image.ImageTransparency = 1

	spr.target(self.indicator_image, 0.8, 5, {
		ImageTransparency = 0,
		Rotation = angle,
		Color = self.color,
	})

	task.delay(self.expiry_time, function()
		local i = table.find(tracking, self)
		if not i then
			warn("couldnt find 'self' in tracking table.")
		else
			table.remove(tracking, i)
		end

		RunService.PreRender:Wait()

		spr.stop(self.indicator_image)
		spr.target(self.indicator_image, 0.8, 3, {
			ImageTransparency = 1,
		})

		spr.completed(self.indicator_image, function()
			pool:Return(self.indicator_image)
		end)

		setmetatable(self, nil)
	end)
end

return module
