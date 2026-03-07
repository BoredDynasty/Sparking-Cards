--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local audio = require(ReplicatedStorage.Modules.audio)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- train.luau
-- a server manager for the ingame train.
-- (we call it a bus, but it is actually a train!)
-- i am rewriting this from an old Roblox model.

-- Configuration Constants
local DOOR_OPEN_DURATION = 10
local DOOR_CLOSE_DURATION = 1
local STATION_STOP_DURATION = DOOR_OPEN_DURATION + DOOR_CLOSE_DURATION

local LIGHT_COLOR_FORWARD = Color3.new(1, 0.95, 0.88)
local LIGHT_COLOR_REVERSE = Color3.new(0.66, 0, 0)
local LIGHT_COLOR_OFF = Color3.new(0.1, 0.1, 0.1)

local carriage = workspace:WaitForChild("Train")

local seat = carriage:WaitForChild("VehicleSeat")

local left_doors = carriage.LeftDoors
local right_doors = carriage.RightDoors

local engine = carriage.Engine

local engine_velocity = engine.BodyVelocity

local panels = carriage.Destination

local depart_throttle = 0

local last_station = nil :: BasePart?

local function update_light_color(light: Instance, direction: number): ()
	local spotlight = light:FindFirstChild("SpotLight") :: SpotLight?
	local surface_gui = light:FindFirstChild("SurfaceGui") :: SurfaceGui?

	if not spotlight or not surface_gui then
		warn(`Light {light.Name} missing SpotLight or SurfaceGui`)
		return
	end

	local white_dot = surface_gui:FindFirstChild("White") :: ImageLabel?
	local red_dot = surface_gui:FindFirstChild("Red") :: ImageLabel?

	if not white_dot or not red_dot then
		warn(`Light {light.Name} missing color indicators`)

		return
	end

	local is_front = light.Name == "A"
	local is_forward = direction > 0

	-- Determine which lights should be active based on direction and position
	local should_show_white = if is_front then is_forward else not is_forward
	local should_show_red = if is_front then not is_forward else is_forward

	spotlight.Color = should_show_white and LIGHT_COLOR_FORWARD or LIGHT_COLOR_REVERSE
	white_dot.ImageColor3 = should_show_white and LIGHT_COLOR_FORWARD or LIGHT_COLOR_OFF
	red_dot.ImageColor3 = should_show_red and LIGHT_COLOR_REVERSE or LIGHT_COLOR_OFF
end

local function set_direction(direction: number): ()
	if direction == 0 then
		return
	end

	depart_throttle = direction

	for _, light in ipairs(carriage.Lights:GetChildren()) do
		update_light_color(light, direction)
	end
end

local function update_destination_display(station_sensor: BasePart): ()
	local line_name = station_sensor:GetAttribute("LineName") :: string?
	local line_number = station_sensor:GetAttribute("LineNumber") :: number?

	for _, panel in ipairs(panels:GetChildren()) do
		if line_name then
			local line_name_display = panel:FindFirstChild("LineName") :: Frame?
			if line_name_display then
				local text_label = line_name_display:FindFirstChild("TextLabel") :: TextLabel?
				if text_label then
					text_label.Text = line_name
				end
			end
		end

		if line_number then
			local line_number_display = panel:FindFirstChild("LineNumber") :: Frame?
			if line_number_display then
				local text_label = line_number_display:FindFirstChild("TextLabel") :: TextLabel?
				if text_label then
					text_label.Text = tostring(line_number)
				end
			end
		end
	end
end

local function handle_door_animation(open_left_doors: boolean): ()
	local all_doors = tablekit.MergeArrays(
		right_doors:GetChildren() :: { any },
		left_doors:GetChildren() :: { any }
	) :: { BasePart }

	for _, door in ipairs(all_doors) do
		if open_left_doors then
			if door.Parent ~= left_doors then
				continue
			end
		end

		door.CanCollide = false
		door.Transparency = 1

		task.delay(DOOR_OPEN_DURATION, function()
			door.CanCollide = true
			door.Transparency = 0
		end)
	end
end

seat.Touched:Connect(function(base_part)
	if base_part.Name ~= "StationSensor" then
		return
	end

	if base_part == last_station then
		return
	end

	last_station = base_part

	audio:PlaySFX("train_brakes", engine.Position)

	-- Stop the train
	seat.Throttle = 0

	-- Get and apply departure direction
	local depart_direction = base_part:GetAttribute("DepartDirection") :: number
	set_direction(depart_direction)

	-- Update destination display
	update_destination_display(base_part)

	-- Animate doors
	local left_doors = base_part:GetAttribute("LeftDoors") :: boolean

	handle_door_animation(left_doors)

	-- Wait for doors to close and be ready to depart
	task.wait(STATION_STOP_DURATION)

	-- Resume movement in departure direction
	seat.Throttle = depart_throttle
end)

-- Initialize direction based on initial throttle
set_direction(seat.Throttle)

-- Setup looping audio
audio:ConfigureSFX("train_clattering", {
	looped = true,
})

audio:PlaySFX("train_clattering", engine.Position)

-- Update physics and audio based on movement
RunService.Heartbeat:Connect(function()
	-- Update engine velocity based on throttle
	engine_velocity.Velocity = seat.Throttle * (engine.CFrame.LookVector.Unit * seat.MaxSpeed)

	-- Adjust train sound volume based on current speed
	local speed_ratio = engine.AssemblyLinearVelocity.Magnitude / seat.MaxSpeed
	audio:ConfigureMusic("train_clattering", {
		volume = speed_ratio,
	})
end)

return {}
