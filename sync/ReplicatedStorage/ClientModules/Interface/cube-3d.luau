--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local random = require(ReplicatedStorage.Utility.random)

-- cube-3d.luau

local module = {}

local random_object = random.create()

local fov_hidden = 1
local fov_visible = 70
local fov_zoom_time = 0.6

local shine_image = "rbxassetid://132155326"
local cube_count = 6
local screen_width = 45
local bob_range = 10
local column_spacing = screen_width / (cube_count - 1)

local face_normals = {
	Enum.NormalId.Front,
	Enum.NormalId.Back,
	Enum.NormalId.Left,
	Enum.NormalId.Right,
	Enum.NormalId.Top,
	Enum.NormalId.Bottom,
}

local opposite_faces = {
	{ Enum.NormalId.Left, Enum.NormalId.Right },
	{ Enum.NormalId.Top, Enum.NormalId.Bottom },
}

type PairState = {
	Alpha: number,
	Direction: number,
}

type CubeEntry = {
	Part: Part,
	FaceDecals: { [Enum.NormalId]: Decal },
	ColX: number,
	BobPhase: number,
	BobSpeed: number,
	CurrentSize: number,
	TargetSize: number,
	SizeTimer: number,
	SizeInterval: number,
	RotX: number,
	RotY: number,
	RotZ: number,
	RotSpeedX: number,
	RotSpeedY: number,
	RotSpeedZ: number,
	RotTimer: number,
	RotInterval: number,
	TargetRotSpeedX: number,
	TargetRotSpeedY: number,
	TargetRotSpeedZ: number,
	PairStates: { PairState },
}

type ModuleState = {
	Running: boolean,
	Viewport: ViewportFrame?,
	Camera: Camera?,
	WorldModel: WorldModel?,
	CubeData: { CubeEntry },
	RenderConnection: RBXScriptConnection?,
	CurrentFov: number,
	TargetFov: number,
}

local state: ModuleState = {
	Running = false,
	Viewport = nil,
	Camera = nil,
	WorldModel = nil,
	CubeData = {},
	RenderConnection = nil,
	CurrentFov = fov_hidden,
	TargetFov = fov_hidden,
}

local function buildCubeFaces(part: Part)
	local face_decals = {}

	for i, face in ipairs(face_normals) do
		local decal = Instance.new("Decal")
		decal.Face = face
		decal.Texture = shine_image
		decal.Transparency = 1
		decal.Color3 = Color3.fromRGB(255, 255, 255)
		decal.Parent = part

		face_decals[face] = decal
	end

	return face_decals
end

local function updateShine(cube: CubeEntry, dt: number)
	local angular_speed = math.sqrt(cube.RotSpeedX ^ 2 + cube.RotSpeedY ^ 2 + cube.RotSpeedZ ^ 2)
	local speed_influence = math.clamp(angular_speed / 200, 0, 1)
	local fade_speed = 0.5 + (speed_influence * 0.8)

	for index, pair in ipairs(opposite_faces) do
		local pair_state: PairState = cube.PairStates[index]
		pair_state.Alpha += pair_state.Direction * fade_speed * dt

		if pair_state.Alpha >= 1 then
			pair_state.Alpha = 1
			pair_state.Direction = -1
		elseif pair_state.Alpha <= 0 then
			pair_state.Alpha = 0
			pair_state.Direction = 1
		end

		local face_a = cube.FaceDecals[pair[1]]
		local face_b = cube.FaceDecals[pair[2]]
		if face_a then
			face_a.Transparency = pair_state.Alpha
		end
		if face_b then
			face_b.Transparency = 1 - pair_state.Alpha
		end
	end
end

local function SpawnCubes(worldModel: WorldModel): { CubeEntry }
	local cube_data: { CubeEntry } = {}

	for i = 1, cube_count do
		local part = Instance.new("Part")
		part.Size = Vector3.one * 3
		part.Anchored = true
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.fromRGB(210, 220, 230)
		part.Transparency = 0.95
		part.Parent = worldModel

		local ColX = -screen_width / 2 + (i - 1) * column_spacing

		cube_data[i] = {
			Part = part,
			FaceDecals = buildCubeFaces(part),
			ColX = ColX,
			BobPhase = random_object:integer(0, math.pi * 2),
			BobSpeed = 0.4 + random_object:integer(0, 0.4),
			CurrentSize = 3.0,
			TargetSize = 3.0 + random_object:integer(0, 2.0),
			SizeTimer = 0,
			SizeInterval = 2.0 + random_object:integer(0, 2.0),
			RotX = 0,
			RotY = 0,
			RotZ = 0,
			RotSpeedX = random_object:integer(-40, 40),
			RotSpeedY = random_object:integer(-50, 50),
			RotSpeedZ = random_object:integer(-20, 20),
			RotTimer = 0,
			RotInterval = 1.5 + random_object:integer(0, 2.5),
			TargetRotSpeedX = random_object:integer(-40, 40),
			TargetRotSpeedY = random_object:integer(-50, 50),
			TargetRotSpeedZ = random_object:integer(-20, 20),
			PairStates = {
				{ Alpha = random_object:integer(0, 1), Direction = 1 },
				{ Alpha = random_object:integer(0, 1), Direction = 1 },
			},
		}
	end

	return cube_data
end

local function destroyCubes(cube_data: { CubeEntry })
	for _, cube in ipairs(cube_data) do
		cube.Part:Destroy()
	end
end

local function stepFov(dt: number)
	if math.abs(state.CurrentFov - state.TargetFov) < 0.05 then
		state.CurrentFov = state.TargetFov
	else
		state.CurrentFov = state.CurrentFov
			+ (state.TargetFov - state.CurrentFov) * math.min(dt / fov_zoom_time * 4, 1)
	end

	if state.Camera then
		state.Camera.FieldOfView = state.CurrentFov
	end

	if state.Viewport then
		state.Viewport.BackgroundTransparency = 1 - (state.CurrentFov / fov_visible) * 0.4
	end
end

function module.start(viewport: ViewportFrame)
	module.stop()

	if state.Running then
		warn("this is already running.")

		return
	end

	state.Viewport = viewport
	state.Running = true

	viewport.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	viewport.BackgroundTransparency = 1

	local camera = Instance.new("Camera")
	camera.FieldOfView = fov_hidden
	camera.CFrame = CFrame.new(Vector3.new(0, 0, 28), Vector3.zero)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	state.Camera = camera

	state.CurrentFov = fov_hidden
	state.TargetFov = fov_visible

	local world_model = Instance.new("WorldModel")
	world_model.Parent = viewport
	state.WorldModel = world_model
	state.CubeData = SpawnCubes(world_model)

	state.RenderConnection = RunService.PreRender:Connect(function(dt: number)
		stepFov(dt)

		for _, cube: CubeEntry in ipairs(state.CubeData) do
			local bob_offset_y = math.sin(os.clock() * cube.BobSpeed + cube.BobPhase) * bob_range

			cube.SizeTimer += dt

			if cube.SizeTimer >= cube.SizeInterval then
				cube.SizeTimer = 0
				cube.SizeInterval = 2.0 + random_object:integer(0, 2.0)
				cube.TargetSize = 2 + random_object:integer(0, 3.5)
			end

			cube.CurrentSize += (cube.TargetSize - cube.CurrentSize) * math.min(dt * 1.5, 1)

			local size = cube.CurrentSize
			cube.Part.Size = Vector3.one * size

			cube.RotTimer += dt

			if cube.RotTimer >= cube.RotInterval then
				cube.RotTimer = 0
				cube.RotInterval = 1.5 + random_object:integer(0, 2.5)
				cube.TargetRotSpeedX = random_object:integer(-40, 40)
				cube.TargetRotSpeedY = random_object:integer(-50, 50)
				cube.TargetRotSpeedZ = random_object:integer(-20, 20)
			end

			local lerp_alpha = math.min(dt * 2, 1)

			cube.RotSpeedX += (cube.TargetRotSpeedX - cube.RotSpeedX) * lerp_alpha
			cube.RotSpeedY += (cube.TargetRotSpeedY - cube.RotSpeedY) * lerp_alpha
			cube.RotSpeedZ += (cube.TargetRotSpeedZ - cube.RotSpeedZ) * lerp_alpha

			cube.RotX += math.rad(cube.RotSpeedX) * dt
			cube.RotY += math.rad(cube.RotSpeedY) * dt
			cube.RotZ += math.rad(cube.RotSpeedZ) * dt

			cube.Part.CFrame = CFrame.new(cube.ColX, bob_offset_y, 0)
				* CFrame.Angles(cube.RotX, cube.RotY, cube.RotZ)

			updateShine(cube, dt)
		end
	end)
end

function module.stop()
	if not state.Running then
		return
	end

	state.Running = false
	state.TargetFov = fov_hidden

	if state.RenderConnection then
		state.RenderConnection:Disconnect()
		state.RenderConnection = nil
	end

	destroyCubes(state.CubeData)
	state.CubeData = {}

	task.delay(fov_zoom_time + 0.15, function()
		if state.WorldModel then
			state.WorldModel:Destroy()
			state.WorldModel = nil
		end

		if state.Camera then
			state.Camera:Destroy()
			state.Camera = nil
		end

		if state.Viewport then
			state.Viewport.CurrentCamera:Destroy()
			state.Viewport = nil
		end
	end)
end
