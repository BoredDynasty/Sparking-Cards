--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local audio = require(ReplicatedStorage.Modules.audio)
local weld_utility = require(ReplicatedStorage.Environment["weld-utility"])

local events = ReplicatedStorage:WaitForChild("Events")
local departure_camera_event = events:WaitForChild("TrainDepartureCamera") :: RemoteEvent

--[=[
	@class TrainService
	Server train orchestrator that supports multiple train instances,
	multi-carriage doors, automatic switch routing, and occupancy waiting.
]=]

local DOOR_TWEEN_DURATION = 0.9
local DOOR_CLOSE_DURATION = 1
local DOOR_OPEN_DURATION = 8
local STATION_STOP_DURATION = 10
local THROTTLE_TWEEN_DURATION = 1
local CLEARANCE_RETRY_INTERVAL = 0.25

local COMFORT_ACCELERATION = 6
local COMFORT_DECELERATION = 10

local DEFAULT_FOLLOW_DISTANCE = 180
local DEFAULT_LATERAL_TOLERANCE = 22
local DEFAULT_DOOR_OFFSET_LEFT = Vector3.new(-1, 0, 6)
local DEFAULT_DOOR_OFFSET_RIGHT = Vector3.new(1, 0, 6)
local PASSENGER_SCAN_PADDING = Vector3.new(12, 8, 12)
local INACTIVE_ROUTE_TRANSPARENCY = 0.75

local LIGHT_COLOR_FORWARD = Color3.new(1, 0.95, 0.88)
local LIGHT_COLOR_REVERSE = Color3.new(0.66, 0, 0)
local LIGHT_COLOR_OFF = Color3.new(0.1, 0.1, 0.1)

type door_side = "left" | "right"

type route_map = { [string]: string }

type door_record = {
	part: BasePart,
	side: door_side,
	closed_from_engine: CFrame,
	open_offset: Vector3,
	tween: Tween?,
}

type track_switch = {
	id: string,
	model: Instance,
	routes: { [string]: { BasePart } },
}

type station_config = {
	sensor: BasePart,
	depart_direction: number,
	open_left_doors: boolean,
	line_name: string?,
	line_number: number?,
	door_open_duration: number,
	station_stop_duration: number,
	switch_routes: route_map,
	required_blocks: { string },
	release_blocks: { string },
	current_block: string?,
}

export type Train = {
	[string]: any,
}

export type TrainService = {
	[string]: any,
}

--[[
	# Train Module Documentation

The `train.luau` module is a server-side orchestrator for managing advanced, physics-based trains in Roblox. It supports multiple train instances, multi-carriage coupling, automatic station routing, and dynamic acceleration/deceleration.

## Setup Instructions

### 1. Workspace Organization
- **Station Sensors**: Create a folder named `StationSensors` in `Workspace`. All your station sensor parts should be placed here.
- **Trains**: While the service can discover trains throughout the Workspace, it's recommended to place them in a `Trains` folder for better organization.

### 2. Station Configuration
Each station is defined by a `BasePart` named `StationSensor`. Configure it using the following **Attributes**:

| Attribute | Type | Description |
| :--- | :--- | :--- |
| `NextStation` | String | The name of the next `StationSensor` in the line. |
| `DepartDirection` | Number | `1` for forward, `-1` for reverse. |
| `LeftDoors` | Boolean | `true` to open left doors, `false` for right. |
| `LineName` | String | (Optional) The name of the train line for displays. |
| `SetLine` | Number | (Optional) The line number for displays. |
| `DoorOpenDuration` | Number | Seconds the doors remain open. |
| `StationStopDuration`| Number | Total seconds the train stays at the station. |

### 3. Train Model Structure
A valid train model should have:
- An **Engine** part (BasePart).
- A **VehicleSeat**.
- (Optional) **Carriages**: Models parented under a folder named `Carriages` or marked with the `IsTrainCarriage` attribute.
- (Optional) **Doors**: Grouped in models named `LeftDoors` or `RightDoors` within carriages.
- (Optional) **Lights**: Grouped in a folder named `Lights` with parts named `A` (front) or `B` (back).

## How it Works

### Physics and Coupling
The module uses `BallSocketConstraints` to connect multiple carriages. Each carriage is internally welded using a `weld-utility` and then chained to the next, allowing the train to navigate curves realistically.

### Automatic Movement
1. **Initial Search**: Upon creation, the train looks for the nearest `StationSensor` in `Workspace.StationSensors`.
2. **Acceleration**: The train accelerates at a "comfort" rate until it reaches its `MaxSpeed`.
3. **Deceleration**: The train dynamically calculates its braking distance. When it nears the `target_station`, it gradually slows down to a complete halt exactly at the sensor.
4. **Sequencing**: After stopping at a station, the train identifies the next target using the `NextStation` attribute.

### Audio System
The module provides spatial audio parented to the train's engine:
- **Ambient**: A looping background track that scales in volume with speed.
- **Clattering**: A speed-dependent track that increases in both volume and pitch as the train moves faster.
- **Brakes/Starting**: One-shot SFX triggered during station events.

## Example Usage

The module returns a `TrainService` singleton that automatically initializes. You usually don't need to call methods manually, but you can interact with it as follows:

```lua
local TrainService = require(path.to.train)

-- The service automatically handles train registration and lifecycle.
-- You can configure your train models with attributes in the editor.
```

### Adding a New Carriage Programmatically
If you want a model to be recognized as a carriage, simply add the attribute:
```lua
model:SetAttribute("IsTrainCarriage", true)
```
The `TrainService` will detect the new model and integrate it into the nearest train's physical chain.

]]
local train_class = {}
train_class.__index = train_class

local service_class = {}
service_class.__index = service_class

local function trim(value: string): string
	return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function normalize_id(value: string): string
	return string.lower(trim(value))
end

local function get_string_attribute(instance: Instance, attribute_name: string): string?
	local value = instance:GetAttribute(attribute_name)
	if typeof(value) ~= "string" then
		return nil
	end

	local cleaned = trim(value)
	if cleaned == "" then
		return nil
	end

	return cleaned
end

local function get_number_attribute(instance: Instance, attribute_name: string): number?
	local value = instance:GetAttribute(attribute_name)
	if typeof(value) ~= "number" then
		return nil
	end

	return value
end

local function get_boolean_attribute(instance: Instance, attribute_name: string): boolean?
	local value = instance:GetAttribute(attribute_name)
	if typeof(value) ~= "boolean" then
		return nil
	end

	return value
end

local function split_csv_like(value: string?): { string }
	if not value then
		return {}
	end

	local output = {}
	for token in string.gmatch(value, "[^,;|]+") do
		local cleaned = trim(token)
		if cleaned == "" then
			continue
		end

		table.insert(output, cleaned)
	end

	return output
end

local function parse_route_map(value: string?): route_map
	local output = {}
	if not value then
		return output
	end

	for _, token in ipairs(split_csv_like(value)) do
		local switch_id, route_name = string.match(token, "^([^:=]+)[:=](.+)$")
		if not switch_id or not route_name then
			continue
		end

		local normalized_switch_id = normalize_id(switch_id)
		local normalized_route_name = trim(route_name)
		if normalized_switch_id == "" or normalized_route_name == "" then
			continue
		end

		output[normalized_switch_id] = normalized_route_name
	end

	return output
end

local function merge_route_maps(base_map: route_map, override_map: route_map)
	for switch_id, route_name in pairs(override_map) do
		base_map[switch_id] = route_name
	end
end

local function parse_block_list(sensor: BasePart, attribute_name: string): { string }
	local output = {}
	for _, block_id in ipairs(split_csv_like(get_string_attribute(sensor, attribute_name))) do
		local normalized_block_id = normalize_id(block_id)
		if normalized_block_id == "" then
			continue
		end

		if table.find(output, normalized_block_id) then
			continue
		end

		table.insert(output, normalized_block_id)
	end

	return output
end

local function infer_directional_attribute_name(base_name: string, depart_direction: number): string
	if depart_direction < 0 then
		return `{base_name}Reverse`
	end

	return `{base_name}Forward`
end

local function collect_base_parts(container: Instance): { BasePart }
	local parts = {}
	if container:IsA("BasePart") then
		table.insert(parts, container)
	end

	for _, descendant in ipairs(container:GetDescendants()) do
		if not descendant:IsA("BasePart") then
			continue
		end

		table.insert(parts, descendant)
	end

	return parts
end

local function update_light_color(light: Instance, direction: number)
	local spotlight = light:FindFirstChild("SpotLight")
	local surface_gui = light:FindFirstChild("SurfaceGui")
	if not spotlight or not surface_gui then
		return
	end

	if not spotlight:IsA("SpotLight") or not surface_gui:IsA("SurfaceGui") then
		return
	end

	local white_dot = surface_gui:FindFirstChild("White")
	local red_dot = surface_gui:FindFirstChild("Red")
	if not white_dot or not red_dot then
		return
	end

	if not white_dot:IsA("ImageLabel") or not red_dot:IsA("ImageLabel") then
		return
	end

	local is_front = light.Name == "A"
	local is_forward = direction > 0
	local should_show_white = if is_front then is_forward else not is_forward
	local should_show_red = if is_front then not is_forward else is_forward

	spotlight.Color = if should_show_white then LIGHT_COLOR_FORWARD else LIGHT_COLOR_REVERSE
	white_dot.ImageColor3 = if should_show_white then LIGHT_COLOR_FORWARD else LIGHT_COLOR_OFF
	red_dot.ImageColor3 = if should_show_red then LIGHT_COLOR_REVERSE else LIGHT_COLOR_OFF
end

local function get_station_sensor(hit_part: BasePart): BasePart?
	if hit_part.Name == "StationSensor" or hit_part:GetAttribute("IsStationSensor") == true then
		return hit_part
	end

	local parent = hit_part.Parent
	if not parent then
		return nil
	end

	local sibling = parent:FindFirstChild("StationSensor")
	if sibling and sibling:IsA("BasePart") then
		return sibling
	end

	return nil
end

local function ensure_body_velocity(engine: BasePart): BodyVelocity
	local body_velocity = engine:FindFirstChildOfClass("BodyVelocity")
	if body_velocity then
		return body_velocity
	end

	local created = Instance.new("BodyVelocity")
	created.Name = "BodyVelocity"
	created.MaxForce = Vector3.one * 1e7
	created.P = 2e4
	created.Velocity = Vector3.zero
	created.Parent = engine

	return created
end

local function is_train_model(model: Model): boolean
	local engine = model:FindFirstChild("Engine", true)
	if not engine or not engine:IsA("BasePart") then
		return false
	end

	local seat = model:FindFirstChildWhichIsA("VehicleSeat", true)
	if not seat then
		return false
	end

	if model:GetAttribute("IsTrain") == true then
		return true
	end

	if model:GetAttribute("DisableTrainService") == true then
		return false
	end

	return string.find(string.lower(model.Name), "train") ~= nil
end

function service_class.new(): TrainService
	local self = setmetatable({
		trains = {},
		trains_by_model = {},
		switches = {},
		track_blocks = {},
		connections = {},
		next_train_serial = 0,
		destroyed = false,
	}, service_class)

	game:BindToClose(function()
		for i, conn in ipairs(self.connections) do
			conn:Disconnect()
			conn = nil
		end

		table.clear(self.connections)
	end)

	self:_index_switches()
	self:_bootstrap_trains()
	self:_watch_workspace()
	self:_start_heartbeat()

	return self
end

function service_class:_index_single_switch(switch_container: Instance)
	-- Expected switch model structure:
	-- TrainSwitches/<SwitchModel>/<RouteFolderOrModel>/<BasePart...>
	-- or descendants with RouteName attributes.
	local switch_id = get_string_attribute(switch_container, "SwitchId") or switch_container.Name
	local normalized_switch_id = normalize_id(switch_id)
	if normalized_switch_id == "" then
		return
	end

	local routes: { [string]: { BasePart } } = {}

	for _, child in ipairs(switch_container:GetChildren()) do
		local route_name = get_string_attribute(child, "RouteName")
		if not route_name then
			local is_container = child:IsA("Model") or child:IsA("Folder")
			if is_container then
				route_name = child.Name
			end
		end

		if not route_name then
			continue
		end

		local normalized_route_name = string.lower(route_name)
		if
			normalized_route_name == "state"
			or normalized_route_name == "show"
			or normalized_route_name == "click"
		then
			continue
		end

		routes[route_name] = collect_base_parts(child)
	end

	if next(routes) == nil then
		for _, descendant in ipairs(switch_container:GetDescendants()) do
			if not descendant:IsA("BasePart") then
				continue
			end

			local route_name = get_string_attribute(descendant, "RouteName")
			if not route_name then
				continue
			end

			if not routes[route_name] then
				routes[route_name] = {}
			end

			table.insert(routes[route_name], descendant)
		end
	end

	local populated_routes = 0
	for _, parts in pairs(routes) do
		if #parts == 0 then
			continue
		end

		populated_routes += 1
	end

	if populated_routes < 2 then
		return
	end

	self.switches[normalized_switch_id] = {
		id = normalized_switch_id,
		model = switch_container,
		routes = routes,
	}
end

function service_class:_index_switches()
	table.clear(self.switches)

	local switch_container = Workspace:FindFirstChild("TrainSwitches")
	if switch_container then
		for _, child in ipairs(switch_container:GetChildren()) do
			self:_index_single_switch(child)
		end
	end

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:GetAttribute("SwitchId") == nil then
			continue
		end

		if not descendant:IsA("Model") and not descendant:IsA("Folder") then
			continue
		end

		self:_index_single_switch(descendant)
	end
end

function service_class:apply_switch_routes(routes: route_map)
	for switch_id, route_name in pairs(routes) do
		local switch_data = self.switches[normalize_id(switch_id)]
		if not switch_data then
			continue
		end

		local target_route = string.lower(trim(route_name))
		if target_route == "" then
			continue
		end

		for current_route, parts in pairs(switch_data.routes) do
			local active = string.lower(current_route) == target_route
			for _, part in ipairs(parts) do
				if not part:IsDescendantOf(Workspace) then
					continue
				end

				if part:GetAttribute("PreserveCanCollide") ~= true then
					part.CanCollide = active
				end

				if part:GetAttribute("PreserveTransparency") ~= true then
					part.Transparency = if active then 0 else INACTIVE_ROUTE_TRANSPARENCY
				end
			end
		end

		local state_value = switch_data.model:FindFirstChild("State")
		if state_value and state_value:IsA("StringValue") then
			state_value.Value = route_name
		end
	end
end

function service_class:try_claim_blocks(train: Train, block_ids: { string }): (boolean, string?)
	if #block_ids == 0 then
		return true, nil
	end

	local unique = {}
	for _, block_id in ipairs(block_ids) do
		local normalized_block_id = normalize_id(block_id)
		if normalized_block_id == "" then
			continue
		end

		if unique[normalized_block_id] then
			continue
		end

		unique[normalized_block_id] = true

		local owner = self.track_blocks[normalized_block_id]
		if owner and owner ~= train then
			return false, normalized_block_id
		end
	end

	for block_id in pairs(unique) do
		self.track_blocks[block_id] = train
		train.owned_blocks[block_id] = true
	end

	return true, nil
end

function service_class:release_blocks(train: Train, block_ids: { string }?)
	if block_ids then
		for _, block_id in ipairs(block_ids) do
			local normalized_block_id = normalize_id(block_id)
			if self.track_blocks[normalized_block_id] ~= train then
				continue
			end

			self.track_blocks[normalized_block_id] = nil
			train.owned_blocks[normalized_block_id] = nil
		end

		return
	end

	for block_id, owner in pairs(self.track_blocks) do
		if owner ~= train then
			continue
		end

		self.track_blocks[block_id] = nil
	end

	table.clear(train.owned_blocks)
end

function service_class:find_blocking_train(
	train: Train,
	depart_direction: number,
	safe_distance: number,
	lateral_tolerance: number
): Train?
	local forward = train.engine.CFrame.LookVector.Unit * depart_direction
	local origin = train.engine.Position

	for _, other_train in ipairs(self.trains) do
		if other_train == train then
			continue
		end

		if other_train.destroyed then
			continue
		end

		local delta = other_train.engine.Position - origin
		local along = delta:Dot(forward)
		if along <= 0 then
			continue
		end

		if along > safe_distance then
			continue
		end

		local lateral = (delta - (forward * along)).Magnitude
		if lateral > lateral_tolerance then
			continue
		end

		return other_train
	end

	return nil
end

function service_class:_is_descendant_of_registered_train(model: Model): boolean
	local ancestor = model.Parent
	while ancestor do
		if ancestor:IsA("Model") and self.trains_by_model[ancestor] then
			return true
		end

		ancestor = ancestor.Parent
	end

	return false
end

function service_class:register_train_model(train_model: Model): Train?
	if self.trains_by_model[train_model] then
		return self.trains_by_model[train_model]
	end

	if not is_train_model(train_model) then
		return nil
	end

	if self:_is_descendant_of_registered_train(train_model) then
		return nil
	end

	self.next_train_serial += 1
	local train_id = `{train_model.Name}_{self.next_train_serial}`
	local train_instance = train_class.new(self, train_id, train_model)
	if not train_instance then
		return nil
	end

	table.insert(self.trains, train_instance)
	self.trains_by_model[train_model] = train_instance

	return train_instance
end

function service_class:_remove_train(train_instance: Train)
	for index, existing in ipairs(self.trains) do
		if existing ~= train_instance then
			continue
		end

		table.remove(self.trains, index)
		break
	end

	if self.trains_by_model[train_instance.model] == train_instance then
		self.trains_by_model[train_instance.model] = nil
	end

	self:release_blocks(train_instance)
	train_instance:Destroy()
end

function service_class:_bootstrap_trains()
	local preferred_container = Workspace:FindFirstChild("Trains")
	if preferred_container then
		for _, child in ipairs(preferred_container:GetChildren()) do
			if not child:IsA("Model") then
				continue
			end

			self:register_train_model(child)
		end
	end

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if not descendant:IsA("Model") then
			continue
		end

		self:register_train_model(descendant)
	end

	if #self.trains > 0 then
		return
	end

	for _, fallback_name in ipairs({ "Train", "MetroTrain" }) do
		local fallback_model = Workspace:FindFirstChild(fallback_name)
		if not fallback_model then
			continue
		end

		if not fallback_model:IsA("Model") then
			continue
		end

		self:register_train_model(fallback_model)
	end
end

function service_class:_watch_workspace()
	table.insert(
		self.connections,
		Workspace.DescendantAdded:Connect(function(instance)
			if not instance:IsA("Model") then
				return
			end

			task.defer(function()
				if self.destroyed then
					return
				end

				if not instance:IsDescendantOf(Workspace) then
					return
				end

				self:register_train_model(instance)
			end)
		end)
	)

	table.insert(
		self.connections,
		Workspace.DescendantRemoving:Connect(function(instance)
			if not instance:IsA("Model") then
				return
			end

			local tracked_train = self.trains_by_model[instance]
			if not tracked_train then
				return
			end

			self:_remove_train(tracked_train)
		end)
	)
end

function service_class:_start_heartbeat()
	table.insert(
		self.connections,
		RunService.Heartbeat:Connect(function(dt: number)
			for _, train_instance in ipairs(self.trains) do
				train_instance:_step(dt)
			end
		end)
	)
end

function service_class:destroy()
	if self.destroyed then
		return
	end

	self.destroyed = true

	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)

	for _, train_instance in ipairs(self.trains) do
		train_instance:Destroy()
	end
	table.clear(self.trains)
	table.clear(self.trains_by_model)
	table.clear(self.track_blocks)
end

function train_class.new(service: TrainService, train_id: string, train_model: Model): Train?
	local engine = train_model:FindFirstChild("Engine", true)
	if not engine or not engine:IsA("BasePart") then
		warn(`Train '{train_id}' skipped: missing engine`)
		return nil
	end

	local seat = train_model:FindFirstChildWhichIsA("VehicleSeat", true)
	if not seat then
		warn(`Train '{train_id}' skipped: missing VehicleSeat`)
		return nil
	end

	local throttle_value = Instance.new("NumberValue")
	throttle_value.Name = "ThrottleValue"
	throttle_value.Value = seat.Throttle

	local self = setmetatable({
		_service = service,
		id = train_id,
		model = train_model,
		engine = engine,
		seat = seat,
		engine_velocity = ensure_body_velocity(engine),
		carriages = {},
		doors = {},
		destination_panels = {},
		passenger_seats = {},
		connections = {},
		throttle_value = throttle_value,
		depart_throttle = if seat.Throttle == 0 then 1 else seat.Throttle,
		last_station = nil,
		last_station_tick = 0,
		station_processing = false,
		destroyed = false,
		owned_blocks = {},
		current_block_id = nil,
		safe_follow_distance = get_number_attribute(train_model, "SafeFollowDistance")
			or DEFAULT_FOLLOW_DISTANCE,
		lateral_tolerance = get_number_attribute(train_model, "LateralTolerance")
			or DEFAULT_LATERAL_TOLERANCE,
		ambient_speed_ratio = 0,
		target_station = nil,
		ambient_sound = nil,
		clattering_sound = nil,
	}, train_class)

	self:_discover_carriages()
	self:_setup_physics()
	self:_setup_sounds()
	self:_discover_doors()
	self:_discover_destinations()
	self:_discover_passenger_seats()
	self:_set_direction(self.depart_throttle)
	self:_connect()
	self:_init_movement()

	return self
end

function train_class:_discover_carriages()
	local seen = {}

	local function register_carriage(candidate: Instance)
		if not candidate:IsA("Model") then
			return
		end

		if seen[candidate] then
			return
		end

		seen[candidate] = true
		table.insert(self.carriages, candidate)
	end

	register_carriage(self.model)

	local carriage_container = self.model:FindFirstChild("Carriages")
	if carriage_container then
		for _, child in ipairs(carriage_container:GetChildren()) do
			register_carriage(child)
		end
	end

	for _, descendant in ipairs(self.model:GetDescendants()) do
		if not descendant:IsA("Model") then
			continue
		end

		if descendant:GetAttribute("IsTrainCarriage") == true then
			register_carriage(descendant)
			continue
		end

		local has_doors = descendant:FindFirstChild("LeftDoors") ~= nil
			or descendant:FindFirstChild("RightDoors") ~= nil
		if has_doors then
			register_carriage(descendant)
		end
	end

	-- Sort carriages by their position relative to the engine's LookVector
	-- We want them ordered from front to back
	local engine_cf = self.engine.CFrame
	table.sort(self.carriages, function(a, b)
		local a_pos = a:GetBoundingBox()
		local b_pos = b:GetBoundingBox()
		local rel_a = engine_cf:PointToObjectSpace(a_pos.Position).Z
		local rel_b = engine_cf:PointToObjectSpace(b_pos.Position).Z
		return rel_a < rel_b -- Smaller Z is further forward (-Z is forward)
	end)
end

function train_class:_setup_physics()
	-- First, weld each carriage internally and unanchor it
	for _, carriage_model in ipairs(self.carriages) do
		local main_part = if carriage_model == self.model
			then self.engine
			else (
				carriage_model.PrimaryPart
				or carriage_model:FindFirstChild("Engine")
				or carriage_model:FindFirstChildWhichIsA("BasePart")
			)

		if main_part then
			weld_utility:Weld(carriage_model, main_part)
			main_part.Anchored = false
		end
	end

	-- Now chain the carriages together using BallSocketConstraints
	local previous_main_part = self.engine
	local previous_cframe, previous_size = self.model:GetBoundingBox()

	for i = 1, #self.carriages do
		local carriage_model = self.carriages[i]
		if carriage_model == self.model then
			continue
		end

		local current_main_part = carriage_model.PrimaryPart
			or carriage_model:FindFirstChild("Engine")
			or carriage_model:FindFirstChildWhichIsA("BasePart")
		if not current_main_part then
			continue
		end

		local current_cframe, current_size = carriage_model:GetBoundingBox()

		-- Create attachments for the coupling
		local attachment0 = Instance.new("Attachment")
		attachment0.Name = "CouplingBack"
		-- Position at back of previous
		attachment0.Position = previous_main_part.CFrame:PointToObjectSpace(
			previous_cframe.Position - (previous_cframe.LookVector * (previous_size.Z / 2))
		)
		attachment0.Parent = previous_main_part

		local attachment1 = Instance.new("Attachment")
		attachment1.Name = "CouplingFront"
		-- Position at front of current
		attachment1.Position = current_main_part.CFrame:PointToObjectSpace(
			current_cframe.Position + (current_cframe.LookVector * (current_size.Z / 2))
		)
		attachment1.Parent = current_main_part

		local constraint = Instance.new("BallSocketConstraint")
		constraint.Name = "CarriageCoupling"
		constraint.Attachment0 = attachment0
		constraint.Attachment1 = attachment1
		constraint.LimitsEnabled = true
		constraint.UpperAngle = 15
		constraint.Parent = current_main_part

		local no_collision = Instance.new("NoCollisionConstraint")
		no_collision.Part0 = previous_main_part
		no_collision.Part1 = current_main_part
		no_collision.Parent = current_main_part

		previous_main_part = current_main_part
		previous_cframe = current_cframe
		previous_size = current_size
	end
end

--[=[
	@within Train
	Finds the next station sensor based on the current station's "NextStation" attribute.
	@param sensor BasePart -- The current station sensor.
	@return BasePart? -- The next station sensor if found.
]=]
function train_class:_find_next_station(sensor: BasePart): BasePart?
	local next_station_name = get_string_attribute(sensor, "NextStation")
	if not next_station_name then
		return nil
	end

	local station_folder = Workspace:FindFirstChild("StationSensors")
	if not station_folder then
		return nil
	end

	local next_station = station_folder:FindFirstChild(next_station_name)
	if next_station and next_station:IsA("BasePart") then
		return next_station
	end

	return nil
end

--[=[
	@within Train
	Initializes the train's movement by finding the nearest station in the Workspace.
]=]
function train_class:_init_movement()
	local station_folder = Workspace:FindFirstChild("StationSensors")
	if not station_folder then
		warn(`Train '{self.id}': StationSensors folder not found in Workspace`)
		-- Fallback: move forward until hit something
		self:_set_throttle(1, 0)
		return
	end

	local nearest = nil
	local min_dist = math.huge
	for _, child in ipairs(station_folder:GetChildren()) do
		if not child:IsA("BasePart") then
			continue
		end

		local dist = (child.Position - self.engine.Position).Magnitude
		if dist < min_dist then
			min_dist = dist
			nearest = child
		end
	end

	if nearest then
		self.target_station = nearest
		self:_set_throttle(1, 0)
	else
		warn(`Train '{self.id}': No stations found in StationSensors folder`)
		self:_set_throttle(1, 0)
	end
end

function train_class:_setup_sounds()
	-- Ambient sound
	local ambient = Instance.new("Sound")
	ambient.Name = "TrainAmbient"
	ambient.SoundId = "rbxassetid://133261320841417"
	ambient.Looped = true
	ambient.Volume = 0
	ambient.RollOffMaxDistance = 500
	ambient.RollOffMinDistance = 10
	ambient.Parent = self.engine
	ambient:Play()
	self.ambient_sound = ambient

	-- Clattering sound
	local clattering = Instance.new("Sound")
	clattering.Name = "TrainClattering"
	clattering.SoundId = "rbxassetid://149026377"
	clattering.Looped = true
	clattering.Volume = 0
	clattering.RollOffMaxDistance = 400
	clattering.RollOffMinDistance = 5
	clattering.Parent = self.engine
	clattering:Play()
	self.clattering_sound = clattering
end

function train_class:_resolve_door_offset(door_part: BasePart, door_group: Instance, side: door_side): Vector3
	local door_offset = door_part:GetAttribute("OpenOffset")
	if typeof(door_offset) == "Vector3" then
		return door_offset
	end

	local group_offset = door_group:GetAttribute("OpenOffset")
	if typeof(group_offset) == "Vector3" then
		return group_offset
	end

	if side == "left" then
		return DEFAULT_DOOR_OFFSET_LEFT
	end

	return DEFAULT_DOOR_OFFSET_RIGHT
end

function train_class:_append_doors(door_group: Instance, side: door_side)
	for _, child in ipairs(door_group:GetChildren()) do
		if not child:IsA("BasePart") then
			continue
		end

		table.insert(self.doors, {
			part = child,
			side = side,
			closed_from_engine = self.engine.CFrame:ToObjectSpace(child.CFrame),
			open_offset = self:_resolve_door_offset(child, door_group, side),
			tween = nil,
		})
	end
end

function train_class:_discover_doors()
	for _, carriage_model in ipairs(self.carriages) do
		local left_group = carriage_model:FindFirstChild("LeftDoors")
		if left_group then
			self:_append_doors(left_group, "left")
		end

		local right_group = carriage_model:FindFirstChild("RightDoors")
		if right_group then
			self:_append_doors(right_group, "right")
		end
	end
end

function train_class:_discover_destinations()
	for _, carriage_model in ipairs(self.carriages) do
		local destination = carriage_model:FindFirstChild("Destination")
		if not destination then
			continue
		end

		table.insert(self.destination_panels, destination)
	end
end

function train_class:_discover_passenger_seats()
	for _, descendant in ipairs(self.model:GetDescendants()) do
		if not descendant:IsA("Seat") and not descendant:IsA("VehicleSeat") then
			continue
		end

		table.insert(self.passenger_seats, descendant)
	end
end

function train_class:_set_direction(direction: number)
	if direction == 0 then
		return
	end

	self.depart_throttle = if direction > 0 then 1 else -1

	for _, carriage_model in ipairs(self.carriages) do
		local lights = carriage_model:FindFirstChild("Lights")
		if not lights then
			continue
		end

		for _, light in ipairs(lights:GetChildren()) do
			update_light_color(light, direction)
		end
	end
end

function train_class:_set_throttle(target_throttle: number, tween_duration: number)
	tween_duration = math.max(tween_duration, 0)

	if tween_duration == 0 then
		self.throttle_value.Value = target_throttle
		self.seat.Throttle = math.sign(target_throttle)
		return
	end

	local tween = TweenService:Create(
		self.throttle_value,
		TweenInfo.new(tween_duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Value = target_throttle,
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		if self.destroyed then
			return
		end

		self.seat.Throttle = math.sign(self.throttle_value.Value)
	end)
end

function train_class:_set_destination_display(line_name: string?, line_number: number?)
	for _, destination in ipairs(self.destination_panels) do
		for _, panel in ipairs(destination:GetDescendants()) do
			if not panel:IsA("Frame") then
				continue
			end

			local text_label = panel:FindFirstChild("TextLabel")
			if not text_label or not text_label:IsA("TextLabel") then
				continue
			end

			if panel.Name == "LineName" and line_name then
				text_label.Text = line_name
			end

			if panel.Name == "LineNumber" and line_number then
				text_label.Text = tostring(line_number)
			end
		end
	end
end

function train_class:_door_target_cframe(door: door_record, is_open: boolean): CFrame
	local closed_target = self.engine.CFrame * door.closed_from_engine
	if not is_open then
		return closed_target
	end

	return closed_target * CFrame.new(door.open_offset)
end

function train_class:_tween_door(door: door_record, is_open: boolean)
	if door.tween then
		door.tween:Cancel()
		door.tween = nil
	end

	local tween = TweenService:Create(
		door.part,
		TweenInfo.new(DOOR_TWEEN_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			CFrame = self:_door_target_cframe(door, is_open),
		}
	)
	door.tween = tween

	tween.Completed:Connect(function()
		if door.tween ~= tween then
			return
		end

		door.tween = nil
	end)

	tween:Play()
end

function train_class:_set_doors_open_state(open_left_doors: boolean, is_open: boolean)
	local target_side: door_side = if open_left_doors then "left" else "right"

	for _, door in ipairs(self.doors) do
		if door.side ~= target_side then
			continue
		end

		self:_tween_door(door, is_open)
	end
end

-- StationSensor attributes supported by this parser:
-- DepartDirection, LeftDoors, DoorOpenDuration, StationStopDuration, LineName, SetLine
-- SwitchRoutes, SwitchRoutesForward/Reverse, SwitchId, SwitchRoute, SwitchIdForward/Reverse, SwitchRouteForward/Reverse
-- RequiredBlocks, RequiredBlocksForward/Reverse, ReleaseBlocks, ReleaseBlocksForward/Reverse, NextBlock, CurrentBlock, StationBlock
function train_class:_build_station_config(sensor: BasePart): station_config
	local depart_direction = get_number_attribute(sensor, "DepartDirection")
	if not depart_direction or depart_direction == 0 then
		depart_direction = self.depart_throttle
	end
	if depart_direction == 0 then
		depart_direction = 1
	end

	local open_left_doors = get_boolean_attribute(sensor, "LeftDoors")
	if open_left_doors == nil then
		open_left_doors = true
	end

	local switch_routes = parse_route_map(get_string_attribute(sensor, "SwitchRoutes"))
	local directional_routes = parse_route_map(
		get_string_attribute(sensor, infer_directional_attribute_name("SwitchRoutes", depart_direction))
	)
	merge_route_maps(switch_routes, directional_routes)

	local direct_switch_id = get_string_attribute(sensor, "SwitchId")
	local direct_switch_route = get_string_attribute(sensor, "SwitchRoute")
	if direct_switch_id and direct_switch_route then
		switch_routes[normalize_id(direct_switch_id)] = direct_switch_route
	end

	local directional_switch_id =
		get_string_attribute(sensor, infer_directional_attribute_name("SwitchId", depart_direction))
	local directional_switch_route =
		get_string_attribute(sensor, infer_directional_attribute_name("SwitchRoute", depart_direction))
	if directional_switch_id and directional_switch_route then
		switch_routes[normalize_id(directional_switch_id)] = directional_switch_route
	end

	local required_blocks = parse_block_list(sensor, "RequiredBlocks")
	for _, block_id in
		ipairs(parse_block_list(sensor, infer_directional_attribute_name("RequiredBlocks", depart_direction)))
	do
		if table.find(required_blocks, block_id) then
			continue
		end

		table.insert(required_blocks, block_id)
	end

	local next_block = get_string_attribute(sensor, "NextBlock")
	if next_block then
		local normalized_next_block = normalize_id(next_block)
		if not table.find(required_blocks, normalized_next_block) then
			table.insert(required_blocks, normalized_next_block)
		end
	end

	local release_blocks = parse_block_list(sensor, "ReleaseBlocks")
	for _, block_id in
		ipairs(parse_block_list(sensor, infer_directional_attribute_name("ReleaseBlocks", depart_direction)))
	do
		if table.find(release_blocks, block_id) then
			continue
		end

		table.insert(release_blocks, block_id)
	end

	local current_block = get_string_attribute(sensor, "CurrentBlock")
		or get_string_attribute(sensor, "StationBlock")
	if current_block then
		current_block = normalize_id(current_block)
	end

	local door_open_duration = get_number_attribute(sensor, "DoorOpenDuration") or DOOR_OPEN_DURATION
	local station_stop_duration = get_number_attribute(sensor, "StationStopDuration") or STATION_STOP_DURATION
	door_open_duration = math.max(door_open_duration, 0)
	station_stop_duration = math.max(station_stop_duration, door_open_duration + DOOR_CLOSE_DURATION)

	return {
		sensor = sensor,
		depart_direction = if depart_direction > 0 then 1 else -1,
		open_left_doors = open_left_doors,
		line_name = get_string_attribute(sensor, "LineName"),
		line_number = get_number_attribute(sensor, "SetLine"),
		door_open_duration = door_open_duration,
		station_stop_duration = station_stop_duration,
		switch_routes = switch_routes,
		required_blocks = required_blocks,
		release_blocks = release_blocks,
		current_block = current_block,
	}
end

function train_class:_collect_passengers(): { Player }
	local passengers = {}
	local seen = {}

	local function register_player(player: Player)
		if seen[player] then
			return
		end

		seen[player] = true
		table.insert(passengers, player)
	end

	for _, seat in ipairs(self.passenger_seats) do
		local occupant = seat.Occupant
		if not occupant then
			continue
		end

		local character = occupant.Parent
		if not character or not character:IsA("Model") then
			continue
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			continue
		end

		register_player(player)
	end

	local bound_cframe, bound_size = self.model:GetBoundingBox()
	local overlap_params = OverlapParams.new()
	overlap_params.FilterType = Enum.RaycastFilterType.Exclude
	overlap_params.FilterDescendantsInstances = {}
	overlap_params.MaxParts = 128

	local parts =
		Workspace:GetPartBoundsInBox(bound_cframe, bound_size + PASSENGER_SCAN_PADDING, overlap_params)
	for _, part in ipairs(parts) do
		local character = part:FindFirstAncestorOfClass("Model")
		if not character then
			continue
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			continue
		end

		register_player(player)
	end

	return passengers
end

function train_class:_send_departure_camera_event()
	for _, passenger in ipairs(self:_collect_passengers()) do
		departure_camera_event:FireClient(passenger, {
			engine = self.engine,
			train_model = self.model,
			train_id = self.id,
			duration = 4,
		})
	end
end

function train_class:_wait_for_clearance(config: station_config)
	while not self.destroyed do
		local got_blocks = true
		if #config.required_blocks > 0 then
			got_blocks = self._service:try_claim_blocks(self, config.required_blocks)
		end

		local blocking_train = self._service:find_blocking_train(
			self,
			config.depart_direction,
			self.safe_follow_distance,
			self.lateral_tolerance
		)

		if got_blocks and not blocking_train then
			return
		end

		if got_blocks and #config.required_blocks > 0 then
			self._service:release_blocks(self, config.required_blocks)
		end

		self:_set_throttle(0, 0)
		task.wait(CLEARANCE_RETRY_INTERVAL)
	end
end

function train_class:_handle_station(sensor: BasePart)
	if self.destroyed then
		return
	end

	local now = os.clock()
	if self.last_station == sensor and (now - self.last_station_tick) < 5 then
		return
	end

	self.last_station = sensor
	self.last_station_tick = now
	self.target_station = self:_find_next_station(sensor)

	local config = self:_build_station_config(sensor)
	local previous_block = self.current_block_id
	if config.current_block then
		self._service:try_claim_blocks(self, { config.current_block })
		self.current_block_id = config.current_block
	else
		self.current_block_id = nil
	end

	if previous_block and previous_block ~= self.current_block_id then
		if not table.find(config.release_blocks, previous_block) then
			table.insert(config.release_blocks, previous_block)
		end
	end

	audio:PlaySFX("train_brakes", self.engine.Position)
	self:_set_throttle(0, THROTTLE_TWEEN_DURATION)

	self:_set_direction(config.depart_direction)
	self:_set_destination_display(config.line_name, config.line_number)
	self._service:apply_switch_routes(config.switch_routes)

	self:_set_doors_open_state(config.open_left_doors, true)
	audio:PlaySFX("train_door_open", self.engine.Position)
	task.wait(config.door_open_duration)

	self:_set_doors_open_state(config.open_left_doors, false)
	audio:PlaySFX("train_door_close", self.engine.Position)
	task.wait(DOOR_CLOSE_DURATION)

	local elapsed_stop = config.door_open_duration + DOOR_CLOSE_DURATION
	local remaining_stop = config.station_stop_duration - elapsed_stop
	if remaining_stop > 0 then
		task.wait(remaining_stop)
	end

	self:_wait_for_clearance(config)

	self:_set_throttle(config.depart_direction, THROTTLE_TWEEN_DURATION)
	audio:PlaySFX("train_starting", self.engine.Position)
	self:_send_departure_camera_event()

	if #config.release_blocks > 0 then
		task.delay(2, function()
			if self.destroyed then
				return
			end

			self._service:release_blocks(self, config.release_blocks)
		end)
	end
end

function train_class:_connect()
	table.insert(
		self.connections,
		self.seat.Touched:Connect(function(hit_part)
			if not hit_part:IsA("BasePart") then
				return
			end

			local station_sensor = get_station_sensor(hit_part)
			if not station_sensor then
				return
			end

			if self.station_processing then
				return
			end

			self.station_processing = true
			task.spawn(function()
				local ok, err = pcall(function()
					self:_handle_station(station_sensor)
				end)

				if not ok then
					warn(`Train '{self.id}' station handling failed: {err}`)
				end

				if self.destroyed then
					return
				end

				self.station_processing = false
			end)
		end)
	)
end

function train_class:_step(dt: number)
	if self.destroyed then
		return
	end

	local current_speed = self.engine.AssemblyLinearVelocity.Magnitude
	local max_speed = math.max(self.seat.MaxSpeed, 0.01)

	if self.target_station and not self.station_processing then
		local delta = self.target_station.Position - self.engine.Position
		local distance = delta.Magnitude

		-- v^2 = 2as => s = v^2 / 2a
		local braking_distance = (current_speed * current_speed) / (2 * COMFORT_DECELERATION)

		if distance <= braking_distance + 2 then
			-- Gradual deceleration
			local target_speed = math.sqrt(2 * COMFORT_DECELERATION * math.max(0, distance - 2))
			local target_throttle = math.clamp(target_speed / max_speed, 0, 1)

			local diff = target_throttle - self.throttle_value.Value
			local step = (COMFORT_DECELERATION / max_speed) * dt
			if math.abs(diff) < step then
				self.throttle_value.Value = target_throttle
			else
				self.throttle_value.Value += math.sign(diff) * step
			end
		else
			-- Acceleration
			local target_throttle = 1
			local diff = target_throttle - self.throttle_value.Value
			local step = (COMFORT_ACCELERATION / max_speed) * dt
			if math.abs(diff) < step then
				self.throttle_value.Value = target_throttle
			else
				self.throttle_value.Value += math.sign(diff) * step
			end
		end
	end

	local target_velocity = self.engine.CFrame.LookVector.Unit
		* (self.throttle_value.Value * self.depart_throttle * max_speed)
	self.engine_velocity.Velocity = target_velocity

	local speed_ratio = current_speed / max_speed
	self.ambient_speed_ratio = math.clamp(speed_ratio, 0, 1)

	-- Update sounds
	if self.ambient_sound then
		self.ambient_sound.Volume = self.ambient_speed_ratio
	end

	if self.clattering_sound then
		self.clattering_sound.Volume = self.ambient_speed_ratio
		self.clattering_sound.PlaybackSpeed = 0.5 + (self.ambient_speed_ratio * 1.5)
	end
end

function train_class:Destroy()
	if self.destroyed then
		return
	end

	self.destroyed = true

	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)

	for _, door in ipairs(self.doors) do
		if not door.tween then
			continue
		end

		door.tween:Cancel()
		door.tween = nil
	end

	self.throttle_value:Destroy()
end

local service = service_class.new()

return service
