--!strict

-- gamecamera.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Emphasis = require(ReplicatedStorage.Utility.Emphasis)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local random = require(ReplicatedStorage.Utility.random)

local GameCamera = {}
GameCamera.__index = GameCamera

local function lerp(a: number, b: number, t: number)
	return a + (b - a) * math.clamp(t, 0, 1)
end

local player = playerMarshaller.get()
local character = player.Character
local humanoid = character.Humanoid
local mouse = player:GetMouse()

local camera = workspace.CurrentCamera

local swayTurn = 0
local offset = Vector3.new(2, 2, 6) -- Right, Up, Back
local smoothness = 0.15
local connections = {} :: { [string]: RBXScriptConnection? }
local collisionPadding = 0.5
local priority = Enum.RenderPriority.Camera.Value
local previousMousePosition = CFrame.new()
local maxTilt = 8

function GameCamera:sway()
	task.spawn(function()
		local mouseDelta = Vector2.new(0, 0)
		local lastMousePosition = Vector2.new(mouse.X, mouse.Y)
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local currentMousePosition = Vector2.new(mouse.X, mouse.Y)

				-- Calculate the delta
				mouseDelta = currentMousePosition - lastMousePosition
			end
		end)
		RunService:BindToRenderStep("sway", priority + 1, function(delta: number)
			debug.profilebegin("sway")
			local mouseDelta: Vector2 = mouseDelta -- UserInputService:GetMouseDelta()
			swayTurn = lerp(swayTurn, math.clamp(mouseDelta.X, -6, 6), (10 * delta))
			camera.CFrame *= CFrame.Angles(0, 0, math.rad(swayTurn))
			debug.profileend()
		end)
	end)
end

function GameCamera:follow()
	local connection = nil
	if connections["follow"] then
		return
	end
	connection = RunService.RenderStepped:Connect(function()
		-- very sigma effect chat
		local currentMousePosition = mouse.Hit

		if previousMousePosition ~= currentMousePosition then
			local newPosition = CFrame.Angles(
				math.rad(((mouse.Y - mouse.ViewSizeY / 2) / mouse.ViewSizeY) * -maxTilt),
				math.rad(((mouse.X - mouse.ViewSizeX / 2) / mouse.ViewSizeX) * -maxTilt),
				0
			)
			camera.CFrame *= newPosition
		end
	end)
	if connection ~= nil then
		connections["follow"] = connection
	end
end

function GameCamera:trail()
	local offset = Vector3.new(0, 5, -10) -- Desired offset from the player
	local smoothSpeed = 0.1 -- Lower = more lag/delay
	local currentCameraPosition = humanoid.RootPart.Position + offset

	-- Rotation values
	local yaw = 0
	local pitch = -10
	local sensitivity = Vector2.new(0.3, 0.2)

	-- Clamp for vertical look
	local MIN_PITCH = -60
	local MAX_PITCH = 70

	-- Camera lag settings
	local cameraHeight = 4

	-- Raycast settings
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.IgnoreWater = true

	-- Zoom settings
	local zoomDistance = 10
	local targetZoom = zoomDistance
	local minZoom = 5
	local maxZoom = 20
	local zoomStep = 1

	-- Enable mouse look
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	UserInputService.InputChanged:Connect(function(input)
		task.spawn(function()
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				yaw -= input.Delta.X * sensitivity.X
				pitch = math.clamp(pitch - input.Delta.Y * sensitivity.Y, MIN_PITCH, MAX_PITCH)
			elseif input.UserInputType == Enum.UserInputType.MouseWheel then
				targetZoom = math.clamp(targetZoom - input.Position.Z * zoomStep, minZoom, maxZoom)
			end
		end)
	end)

	local connection = nil
	if connections["camera_trail"] then
		return
	end
	connection = RunService.RenderStepped:Connect(function()
		debug.profilebegin("camera_trail")

		-- Smooth zoom transition
		zoomDistance = zoomDistance + (targetZoom - zoomDistance) * 0.15

		local rootPosition = humanoid.RootPart.Position + Vector3.new(0, cameraHeight, 0)
		local rotation = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)

		local desiredCameraPosition = rootPosition + (rotation.LookVector * -zoomDistance)

		-- Raycast from root toward desired camera position to avoid clipping
		local direction = desiredCameraPosition - rootPosition
		local result = workspace:Raycast(rootPosition, direction, raycastParams)

		if result then
			-- Hit something: move camera closer
			desiredCameraPosition = result.Position + result.Normal * 0.5
		end

		-- Smooth camera movement (lag effect)
		currentCameraPosition = currentCameraPosition:Lerp(desiredCameraPosition, smoothSpeed)

		-- Set final camera frame
		camera.CFrame = CFrame.new(currentCameraPosition, rootPosition)
		debug.profileend()
	end)
	if connection ~= nil then
		connections["camera_trail"] = connection
	end
end

function GameCamera:changeFOV(change: number)
	-- Usually 60 or 70.
	TweenPlus(
		camera,
		{ FieldOfView = change },
		{ Time = Emphasis.emphasized, EasingDirection = "Out", EasingStyle = "Circular" }
	):Start()
end

function GameCamera:disconnect(scriptConnection: string)
	if connections[scriptConnection:lower()] then
		local connection = connections[scriptConnection:lower()]
		if connection then
			connection:Disconnect()
		end
	end
end

function GameCamera:remove()
	if not connections then
		return
	end
	for name, _ in connections do
		if _ then
			_:Disconnect()
			_ = nil
		end
	end
	RunService:UnbindFromRenderStep("sway")
	print("removed gamecamera")
end

return GameCamera
