--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)

-- speed-lines.luau

local module = {}

local speed = 20
local rate = 1500
local offset = 10
local render_priority = Enum.RenderPriority.Camera.Value
local state = false
local tag = "speed-lines"

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local camera = workspace.CurrentCamera

local pool = PoolerPlus:CreatePool("SpeedlinesPool", function()
	local assets = ReplicatedStorage.Assets

	return assets.Speedlines:Clone()
end)

pool:AdaptivePreload()

function module:On()
	local lines = pool:Get()

	local function compute()
		if not character or not humanoid or humanoid.Health <= 0 then
			module:Off(lines)
		end

		local viewport_size = camera.ViewportSize
		local aspect_ratio = viewport_size.X / viewport_size.Y

		local fov = camera.FieldOfView
		local look_vector = camera.CFrame.LookVector
		local coordinate = camera.CFrame

		-- so you can see them on any other device
		if aspect_ratio > 1.5 then
			offset = 10
		else
			offset = 13
		end

		-- TODO) make the fov in compliance with user options.
		-- we should replace the 70 with the default FOV.
		-- 70 is the placeholder for now
		lines.CFrame = coordinate + look_vector * (offset / (fov / 70))
		lines.Attachment.ParticleEmitter.Rate = (humanoid.WalkSpeed / speed) * rate
	end

	lines.Parent = camera
	lines.Attachment.ParticleEmitter.Enabled = true

	if state then
		module:Off()
	end

	RunService:BindToRenderStep(tag, render_priority, compute)

	state = true
end

function module:Off()
	RunService:UnbindFromRenderStep(tag)

	pool:ReturnAll()
end

return module
