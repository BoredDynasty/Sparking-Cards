--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local hydration = require(ReplicatedStorage.Utility.hydration)
local joint_physics = require(ReplicatedStorage.Modules.Physics["joint-physics"])
local observer = require(ReplicatedStorage.Utility.observer)

-- vignette-service.luau

local vignette_service = {}

type corners = {
	[string]: CFrame,
}

type sides = {
	[string]: {
		Size: Vector3,
		Corners: { string },
	},
}

type side_instances = {
	[string]: {
		Joint: Weld,
		Object: Part,
	},
}

type view_model = {
	Core: BasePart,
	_connection: { RBXScriptConnection },
	sides: sides,
	side_instances: side_instances,
}

local camera = game.Workspace.CurrentCamera

local function getHorizontalFOV(fov: number, viewport_size: Vector2)
	local aspect_ratio = viewport_size.X / viewport_size.Y

	local camera_height = math.tan(math.rad(fov) * 0.5)

	local horizontal = math.deg(math.atan(camera_height * aspect_ratio) * 2)

	return horizontal
end

local function newViewModel(effects: { ParticleEmitter }): view_model | any
	local view_model = {}

	local vertical_fov = camera.FieldOfView
	local horizontal_fov = getHorizontalFOV(vertical_fov, camera.ViewportSize)

	horizontal_fov = vertical_fov + ((horizontal_fov - vertical_fov) / 1.65)

	local corners = {
		top_left = CFrame.new()
			* CFrame.Angles(math.rad(vertical_fov / 2), math.rad(horizontal_fov / 2), 0)
			* CFrame.new(0, 0, -5),
		top_right = CFrame.new()
			* CFrame.Angles(math.rad(vertical_fov / 2), -math.rad(horizontal_fov / 2), 0)
			* CFrame.new(0, 0, -5),
		bottom_left = (
			CFrame.new() * CFrame.Angles(-math.rad(vertical_fov / 2), math.rad(horizontal_fov / 2), 0)
		) * CFrame.new(0, 0, -5),
		bottom_right = (
			CFrame.new() * CFrame.Angles(-math.rad(vertical_fov / 2), -math.rad(horizontal_fov / 2), 0)
		) * CFrame.new(0, 0, -5),
	} :: corners

	local x_size = (corners.top_left.Position - corners.top_right.Position).Magnitude
	local y_size = (corners.top_left.Position - corners.bottom_left.Position).Magnitude

	view_model.sides = {
		top = {
			Size = Vector3.new(0.2, 0.2, x_size),
			Corners = { "top_left", "top_right" },
		},
		bottom = {
			Size = Vector3.new(0.2, 0.2, x_size),
			Corners = { "bottom_left", "bottom_right" },
		},
		left = {
			Size = Vector3.new(0.2, 0.2, y_size),
			Corners = { "top_left", "bottom_left" },
		},
		right = {
			Size = Vector3.new(0.2, 0.2, y_size),
			Corners = { "top_right", "bottom_right" },
		},
	} :: sides

	view_model.side_instances = {}

	view_model.Core = Instance.new("Part")

	hydration(view_model.Core) {
		-- replace
		Name = "VignetteCore",
		Anchored = true,
		CanCollide = false,
		Transparency = 1,
		Size = Vector3.one * 0.2,
		Parent = workspace,
	}

	local function update_core()
		local camera_cframe = camera.CFrame

		view_model.Core.CFrame = camera_cframe
	end

	local conn = RunService.RenderStepped:Connect(update_core)
	view_model._connections = table.create(1e5, conn)

	for side_name, side_data in pairs(view_model.sides) do
		local side_part = Instance.new("Part")
		hydration(side_part) {
			Name = "VignetteSide_" .. side_name,
			Anchored = true,
			CanCollide = false,
			Size = side_data.Size,
			Parent = workspace,
		}

		local x = corners[side_data.Corners[1]].Position
		local y = corners[side_data.Corners[2]].Position

		local c1 = CFrame.new(x, y) * CFrame.new(0, 0, -side_data.Size.X / 2)
		local joint = joint_physics.new(side_part, view_model.Core, CFrame.new(), c1)

		view_model.side_instances[side_name] = {
			Object = side_part,
			Joint = joint,
		}

		if effects then
			for i, effect in ipairs(effects) do
				effect = effect:Clone()
				effect.Parent = side_part
			end
		else
			warn("Creating a vignette with no effects????")
		end
	end

	return view_model
end

local function adjustViewModel(view_model: view_model, distance)
	local vertical_fov = camera.FieldOfView
	local horizontal_fov = getHorizontalFOV(vertical_fov, camera.ViewportSize)

	horizontal_fov = vertical_fov + ((horizontal_fov - vertical_fov) / 1.65)

	local corners = {
		top_left = CFrame.new()
			* CFrame.Angles(math.rad(vertical_fov / 2), math.rad(horizontal_fov / 2), 0)
			* CFrame.new(0, 0, -5),
		top_right = CFrame.new()
			* CFrame.Angles(math.rad(vertical_fov / 2), -math.rad(horizontal_fov / 2), 0)
			* CFrame.new(0, 0, -5),
		bottom_left = (
			CFrame.new() * CFrame.Angles(-math.rad(vertical_fov / 2), math.rad(horizontal_fov / 2), 0)
		) * CFrame.new(0, 0, -5),
		bottom_right = (
			CFrame.new() * CFrame.Angles(-math.rad(vertical_fov / 2), -math.rad(horizontal_fov / 2), 0)
		) * CFrame.new(0, 0, -5),
	} :: corners

	local x_size = (corners.top_left.Position - corners.top_right.Position).Magnitude
	local y_size = (corners.top_left.Position - corners.bottom_left.Position).Magnitude

	view_model.sides.Top.Size = Vector3.new(0.2, 0.2, x_size)
	view_model.sides.Bottom.Size = Vector3.new(0.2, 0.2, x_size)

	view_model.sides.Left.Size = Vector3.new(0.2, 0.2, y_size)
	view_model.sides.Right.Size = Vector3.new(0.2, 0.2, y_size)

	for side_name, side_data in pairs(view_model.sides) do
		local c1 = CFrame.new(corners[side_data.Corners[1]].Position, corners[side_data.Corners[2]].Position)
			* CFrame.new(0, 0, -side_data.Size.X / 2)

		view_model.side_instances[side_name].Joint.C1 = c1
		view_model.side_instances[side_name].Object.Size = side_data.Size

		print("yay!")
	end
end

function vignette_service.new(effects: { ParticleEmitter })
	local self = setmetatable({
		view_model = newViewModel(effects),
		effects = {},
		enabled = observer.new(true),
		distance = observer.new(5),
		updating = observer.new(false),

		_connections = {
			viewport = observer.new(nil),
			fov = observer.new(nil),
		},
	}, { __index = vignette_service })

	for side_name, instance in pairs(self.view_model.side_instances) do
		for i, effect in ipairs(instance.Object:GetChildren()) do
			print("added effect...!")

			table.insert(self.effects, effect)
		end
	end

	return self
end

function vignette_service:Enable()
	self.enabled:Set(true)

	for i, effect in ipairs(self.effects :: { ParticleEmitter }) do
		effect.Enabled = self.enabled:Get()
	end
end

function vignette_service:SetDistance(distance: number)
	adjustViewModel(self.view_model, distance)

	self.distance:Set(distance)
end

function vignette_service:ToggleUpdate(bool: boolean)
	self.updating:Set(bool)

	local changed_signals = {
		fov = camera:GetPropertyChangedSignal("FieldOfView"),
		viewport = camera:GetPropertyChangedSignal("Viewport"),
	}

	if self.updating:Get() then
		self._connections.viewport = changed_signals.viewport:Connect(function()
			adjustViewModel(self.view_model, self.distance:Get())
		end)
		self._connections.fov = changed_signals.fov:Connect(function()
			adjustViewModel(self.view_model, self.distance:Get())
		end)
	else
		for i, conn in pairs(self._connections :: { [string]: RBXScriptConnection }) do
			conn:Disconnect()
		end
	end

	table.clear(changed_signals) -- i think potentially memory leak
end

function vignette_service:Destroy()
	for side_name, instance in pairs(self.view_model.side_instances :: side_instances) do
		instance.Object:Destroy()
	end

	self:ToggleUpdate(false)

	for i, conn in ipairs(self.view_model._connections :: { RBXScriptConnection }) do
		conn:Disconnect()
	end

	self.view_model.Core:Destroy()

	table.clear(self)

	setmetatable(self, nil)
end
