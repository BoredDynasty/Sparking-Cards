-- Train.server.lua

local CollectionService = game:GetService("CollectionService")

for _, seat: VehicleSeat in CollectionService:GetTagged("TrainVehicleSeat") do
	local carriage = seat.Parent :: Instance
	local DlObject = carriage:WaitForChild("DL")
	local DRObject = carriage:WaitForChild("DR")
	local _DestinationObject = carriage:WaitForChild("Destination")
	local dl = DlObject:GetChildren()
	local dr = DRObject:GetChildren()
	local engine = carriage:WaitForChild("Engine")
	local engineBV = engine:WaitForChild("BodyVelocity")
	local panels = carriage.Destination:GetChildren()

	local lastStation = nil
	local dir = seat.Throttle
	function SetDirection(_Dir)
		if _Dir == 0 then
			return
		end
		dir = _Dir
		for _, lights in pairs(carriage.Lights:GetChildren()) do
			if lights.Name == "A" then
				lights.SpotLight.Color = (dir > 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.66, 0, 0)
				lights.SurfaceGui.White.ImageColor3 = (dir > 0) and Color3.new(1, 0.95, 0.88)
					or Color3.new(0.1, 0.1, 0.1)
				lights.SurfaceGui.Red.ImageColor3 = (dir < 0) and Color3.new(0.66, 0, 0)
					or Color3.new(0.1, 0, 0)
			else
				lights.SpotLight.Color = (dir < 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.66, 0, 0)
				lights.SurfaceGui.White.ImageColor3 = (dir < 0) and Color3.new(1, 0.95, 0.88)
					or Color3.new(0.1, 0.1, 0.1)
				lights.SurfaceGui.Red.ImageColor3 = (dir > 0) and Color3.new(0.66, 0, 0)
					or Color3.new(0.1, 0, 0)
			end
		end
	end

	seat.Touched:Connect(function(child)
		if (child.Name == "StationSensor") and (child ~= lastStation) then
			lastStation = child
			engine.Brake:Play()
			print("Train stopped")
			seat.Throttle = 0
			SetDirection(child.DepartDirection.Value)
			for _, panel in pairs(panels) do
				if child.SetName.Value ~= "" then
					panel.SGUI.LineName.T.Text = child.SetName.Value
				end
				if child.SetLine.Value ~= "" then
					panel.SGUI.LineLine.T.Text = child.SetLine.Value
				end
			end
			local doors = child.DoorLeft.Value and dl or dr
			for _, door in pairs(doors) do
				door.CanCollide = false
				door.Transparency = 1
			end
			task.wait(10)
			for _, door in pairs(doors) do
				door.CanCollide = true
				door.Transparency = 0
			end
			seat.Throttle = dir
		end
	end)

	SetDirection(dir)

	engine.Clattering:Play()

	while task.wait(0.1) do
		engineBV.velocity = engine.CFrame.lookVector * seat.Throttle * seat.MaxSpeed
		engine.Clattering.Volume = engine.Velocity.Magnitude / seat.MaxSpeed
	end
end
