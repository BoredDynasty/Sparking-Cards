--!nonstrict

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
		RunService:BindToRenderStep("sway", priority + 1, function(delta: number)
			debug.profilebegin("sway")
			local mouseDelta: Vector2 = UserInputService:GetMouseDelta()
			swayTurn = lerp(swayTurn, math.clamp(mouseDelta.X, -6, 6), (10 * delta))
			camera.CFrame *= CFrame.Angles(0, 0, math.rad(swayTurn))
			debug.profileend()
		end)
	end)
end

function GameCamera:bobble()
	local connection: RBXScriptConnection? = nil
	if connections["bobble"] then
		return
	end
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		debug.profilebegin("bobble")
		deltaTime = deltaTime * 60
		local rootVelocity = humanoid.RootPart.AssemblyLinearVelocity
		local rootMagnitude = Vector3.new(rootVelocity.X, 0, rootVelocity.Z).Magnitude
		rootMagnitude = math.min(rootMagnitude, 50)

		local func1, func2, func3, func4 = 0, 0, 0, 0
		local val, val2 = 0, 0
		local int, int2 = 10, 10

		if deltaTime > 3 then
			func1, func2 = 0, 0
		else
			local currentTime = tick() / 2
			local dividend = 200
			local t = 0.05 * deltaTime
			func1 = lerp(
				func1,
				math.cos(currentTime * random.integer(10, 15))
					* (random.integer(5, 20) / dividend)
					* deltaTime,
				t
			)
			func2 = lerp(
				func2,
				math.cos(currentTime * random.integer(5, 10)) * (random.integer(2, 10) / dividend) * deltaTime,
				t
			)
		end
		local coordinate = (
			CFrame.Angles(0, 0, math.rad(func3))
			* CFrame.Angles(math.rad(func4 * deltaTime), math.rad(val * deltaTime), val2)
			* CFrame.Angles(0, 0, math.rad(func4 * deltaTime * (rootMagnitude / 5)))
			* CFrame.Angles(math.rad(func1), math.rad(func2), math.rad(func2 * 10))
		)
		camera.CFrame *= coordinate
		val2 = math.clamp(
			lerp(
				val2,
				-camera.CFrame:VectorToObjectSpace(
						(humanoid.RootPart and rootVelocity or Vector3.new())
							/ math.max(humanoid.WalkSpeed, 0.01)
					).X * 0.08,
				0.1 * deltaTime
			),
			-0.35,
			0.2
		)

		local t = 0.25 * deltaTime
		func3 = lerp(func3, math.clamp(UserInputService:GetMouseDelta().X, -5, 5), t)
		func4 = lerp(func4, math.sin(tick() * int) / 5 * math.min(1, int2 / 10), t)
		if rootMagnitude > 1 then
			val = lerp(val, math.cos(tick() * 0.5 * math.floor(int)) * (int / 200), t)
		else
			val = lerp(val, 0, 0.05 * deltaTime)
		end
		if rootMagnitude > 12 then
			int = 20
			int2 = 18
		elseif rootMagnitude > 0.1 then
			int = 12
			int2 = 14
		else
			int2 = 0
		end
		debug.profileend()
	end)
	if connection ~= nil then
		connections["bobble"] = connection
	end
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
		_:Disconnect()
		_ = nil
	end
	RunService:UnbindFromRenderStep("sway")
	print("removed gamecamera")
end

return GameCamera
