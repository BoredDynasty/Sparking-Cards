--!nonstrict

-- GameCamera.lua

local Players = game:GetService("Players")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GameCamera = {}
GameCamera.__index = GameCamera

local function lerp(a: number, b: number, t: number)
	return a + (b - a) * math.clamp(t, 0, 1)
end

type self = {
	player: Player,
	humanoid: Humanoid,
	mouse: Mouse,
	camera: Camera,
	swayTurn: number,
	offset: Vector3,
	smoothness: number,
	connections: { [string]: RBXScriptConnection? },
	collisionPadding: number,
	priority: number,
	previousMousePosition: CFrame,
	maxTilt: number,
	-- functions
	sway: (self: self) -> (),
	bobble: (self: self) -> (),
	follow: (self: self) -> (),
	trail: (self: self) -> (),
	disconnect: (self: self, scriptConnection: string) -> nil,
	remove: () -> nil,
}?

export type GameCamera = { typeof(setmetatable({} :: self, GameCamera)) }

function GameCamera.new(character: Model): GameCamera
	local self = setmetatable({
		player = Players.LocalPlayer,
		humanoid = character:WaitForChild("Humanoid"),
		mouse = Players.LocalPlayer:GetMouse(),
		camera = workspace.CurrentCamera,
		swayTurn = 0,
		offset = Vector3.new(2, 2, 6), -- Right, Up, Back
		smoothness = 0.15,
		connections = {} :: { [string]: RBXScriptConnection? },
		collisionPadding = 0.5,
		priority = Enum.RenderPriority.Camera.Value,
		previousMousePosition = CFrame.new(),
		maxTilt = 8,
	}, GameCamera)
	return self
end

function GameCamera:sway(self: self)
	assert(self, "Did you forget to create a new GameCamera object?")
	task.spawn(function()
		RunService:BindToRenderStep("sway", self.priority + 1, function(delta: number)
			debug.profilebegin("sway")
			local mouseDelta: Vector2 = UserInputService:GetMouseDelta()
			self.swayTurn = lerp(self.swayTurn, math.clamp(mouseDelta.X, -6, 6), (10 * delta))
			self.camera.CFrame *= CFrame.Angles(0, 0, math.rad(self.swayTurn))
			debug.profileend()
		end)
	end)
end

function GameCamera:bobble(self: self)
	assert(self, "Did you forget to create a new GameCamera object?")
	local connection = nil
	if self.connections["bobble"] then
		return
	end
	task.spawn(function()
		local breathe = 0.25
		local speed = 5

		connection = RunService.RenderStepped:Connect(function()
			debug.profilebegin("bobble")
			if self.humanoid.MoveDirection.Magnitude > 0 then
				local currentTime = tick() or os.clock()

				local x = math.cos(currentTime * speed) * breathe
				local y = math.abs(math.sin(currentTime * 5)) * 0.25
				local bobble = Vector3.new(x, y, 0)

				local interpolation = self.humanoid.CameraOffset:Lerp(bobble, breathe)
				self.humanoid.CameraOffset = interpolation
			else
				local alteredOffset = self.humanoid.CameraOffset * (breathe + 0.5)
				self.humanoid.CameraOffset = alteredOffset
			end
			debug.profileend()
		end)
	end)
	if connection ~= nil then
		self.connections["bobble"] = connection
	end
end

function GameCamera:follow(self: self)
	assert(self, "Did you forget to create a new GameCamera object?")
	local connection = nil
	if self.connections["follow"] then
		return
	end
	connection = RunService.RenderStepped:Connect(function()
		-- very sigma effect chat
		local currentMousePosition = self.mouse.Hit

		if self.previousMousePosition ~= currentMousePosition then
			local newPosition = CFrame.Angles(
				math.rad(((self.mouse.Y - self.mouse.ViewSizeY / 2) / self.mouse.ViewSizeY) * -self.maxTilt),
				math.rad(((self.mouse.X - self.mouse.ViewSizeX / 2) / self.mouse.ViewSizeX) * -self.maxTilt),
				0
			)
			self.camera.CFrame *= newPosition
		end
	end)
	if connection ~= nil then
		self.connections["follow"] = connection
	end
end

function GameCamera:trail(self: self)
	assert(self, "Did you forget to create a new GameCamera object?")
	local offset = Vector3.new(0, 5, -10) -- Desired offset from the player
	local smoothSpeed = 0.1 -- Lower = more lag/delay
	local currentCameraPosition = self.humanoid.RootPart.Position + offset

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
	raycastParams.FilterDescendantsInstances = { self.player.Character }
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
	if self.connections["camera_trail"] then
		return
	end
	connection = RunService.RenderStepped:Connect(function()
		debug.profilebegin("camera_trail")

		-- Smooth zoom transition
		zoomDistance = zoomDistance + (targetZoom - zoomDistance) * 0.15

		local rootPosition = self.humanoid.RootPart.Position + Vector3.new(0, cameraHeight, 0)
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
		self.camera.CFrame = CFrame.new(currentCameraPosition, rootPosition)
		debug.profileend()
	end)
	if connection ~= nil then
		self.connections["camera_trail"] = connection
	end
end

function GameCamera:disconnect(self: self, scriptConnection: string)
	assert(self, "Did you forget to create a new GameCamera object?")
	if self.connections[scriptConnection:lower()] then
		local connection = self.connections[scriptConnection:lower()]
		if connection then
			connection:Disconnect()
		end
	end
end

function GameCamera:remove(self: self)
	assert(self, "Did you forget to create a new GameCamera object?")
	if not self.connections then
		return
	end
	for name, _ in self.connections do
		self:disconnect(name)
	end
	self = nil
	RunService:UnbindFromRenderStep("sway")
	print("removed game camera")
end

return GameCamera
