local seat = script.Parent
local carriage = seat.Parent
local dl = carriage.DL:GetChildren()
local dr = carriage.DR:GetChildren()
local engine = carriage.Engine
local engineBV = engine.BodyVelocity
local panels = carriage.Destination:GetChildren()

local lastStation = nil
local dir = seat.Throttle

function SetDirection(_Dir)
	if (_Dir == 0) then return end
	dir = _Dir
	for i,v in pairs(carriage.Lights:GetChildren()) do	
		if (v.Name == "A") then
			v.SpotLight.Color = (dir > 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.66, 0, 0)
			v.SurfaceGui.White.ImageColor3 = (dir > 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.1, 0.1, 0.1)
			v.SurfaceGui.Red.ImageColor3 = (dir < 0) and Color3.new(0.66, 0, 0) or Color3.new(0.1, 0, 0)
		else
			v.SpotLight.Color = (dir < 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.66, 0, 0)
			v.SurfaceGui.White.ImageColor3 = (dir < 0) and Color3.new(1, 0.95, 0.88) or Color3.new(0.1, 0.1, 0.1)
			v.SurfaceGui.Red.ImageColor3 = (dir > 0) and Color3.new(0.66, 0, 0) or Color3.new(0.1, 0, 0)			
		end
	end
end

seat.Touched:connect(function(child)
	if (child.Name == "StationSensor") and (child ~= lastStation) then
		lastStation = child
		engine.Brake:Play()
		--print("Train stopped")
		seat.Throttle = 0
		SetDirection(child.DepartDirection.Value)
		for i,v in pairs(panels) do
			if (child.SetName.Value ~= "") then
				v.SGUI.LineName.T.Text = child.SetName.Value
			end
			if (child.SetLine.Value ~= "") then
				v.SGUI.LineLine.T.Text = child.SetLine.Value
			end
		end
		local doors = child.DoorLeft.Value and dl or dr
		for i,v in pairs(doors) do
			v.CanCollide = false
			v.Transparency = 1
		end
		wait(10)
		for i,v in pairs(doors) do
			v.CanCollide = true
			v.Transparency = 0
		end
		seat.Throttle = dir
	end
end)

SetDirection(dir)

engine.Clattering:Play()

while wait(0.1) do
	engineBV.velocity 	= engine.CFrame.lookVector * seat.Throttle * seat.MaxSpeed
	engine.Clattering.Volume = engine.Velocity.Magnitude / seat.MaxSpeed
end