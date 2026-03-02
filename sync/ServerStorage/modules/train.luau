--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local audio = require(ReplicatedStorage.Modules.audio)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- train.luau
-- a server manager for the ingame bus.
-- (we call it a bus, but it is actually a train!)
-- i am rewriting this from an old Roblox model.

local carriage = workspace:WaitForChild("Train")

local seat = carriage:WaitForChild("VehicleSeat")

local left_doors = carriage.LeftDoors
local right_doors = carriage.RightDoors

local engine = carriage.Engine

local engine_velocity = engine.BodyVelocity

local panels = carriage.Destination

local throttle_direction = seat.Throttle

local last_station = nil :: BasePart?

local function setDirection(direction)
	if direction == 0 then
		return
	end

	throttle_direction = direction

	for i, light in ipairs(carriage.Lights:GetChildren()) do
		local spotlight = light:FindFirstChild("SpotLight") :: SpotLight
		local surface_gui = light:FindFirstChild("SurfaceGui") :: SurfaceGui

		local white_dot = surface_gui:FindFirstChild("White") :: ImageLabel
		local red_dot = surface_gui:FindFirstChild("Red") :: ImageLabel

		if light.Name == "A" then
			spotlight.Color = (direction > 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.66, 0, 0)
			white_dot.ImageColor3 = (direction > 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.1, 0.1, 0.1)
			red_dot.ImageColor3 = (direction < 0) and Color3.new(0.66, 0, 0) or Color3.new(0.1, 0, 0)
		else
			spotlight.Color = (direction < 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.66, 0, 0)
			white_dot.ImageColor3 = (direction < 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.1, 0.1, 0.1)
			red_dot.ImageColor3 = (direction > 0) and Color3.new(0.66, 0, 0) or Color3.new(0.1, 0, 0)
		end
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
	print("train stopped")

	seat.Throttle = 0

	local depart_direction = base_part:GetAttribute("DepartDirection") :: number

	setDirection(depart_direction)

	for i, panel in ipairs(panels:GetChildren()) do
		local line_name = base_part:GetAttribute("LineName") :: string?
		local line_number = base_part:GetAttribute("LineNumber") :: number?

		local line_name_display = panel:FindFirstChild("LineName") :: Frame
		local line_number_display = panel:FindFirstChild("LineNumber") :: Frame

		if line_name_display and line_name then
			line_name_display.TextLabel.Text = line_name
		end
		if line_number_display and line_number then
			line_number_display.TextLabel.Text = tostring(line_number)
		end
	end

	for i, door in
		ipairs(
			tablekit.MergeArrays(right_doors:GetChildren() :: { any }, left_doors:GetChildren() :: { any }) :: { BasePart }
		)
	do
		door.CanCollide = false
		door.Transparency = 1

		task.delay(10, function()
			door.CanCollide = true
			door.Transparency = 0
		end)
	end

	task.wait(11)

	seat.Throttle = throttle_direction
end)

setDirection(seat.Throttle)

audio:ConfigureSFX("train_clattering", {
	looped = true,
})

audio:PlaySFX("train_clattering", engine.Position)

RunService.Heartbeat:Connect(function()
	engine_velocity.Velocity = engine.CFrame.LookVector * seat.Throttle * seat.MaxSpeed
	audio:ConfigureMusic("train_clattering", {
		volume = engine.AssemblyLinearVelocity.Magnitude / seat.MaxSpeed,
	})
end)
