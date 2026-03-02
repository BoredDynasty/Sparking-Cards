--[[
		___      _______                _     
	   / _ |____/ ___/ /  ___ ____ ___ (_)__ 
	  / __ /___/ /__/ _ \/ _ `(_-<(_-</ (_-<
	 /_/ |_|   \___/_//_/\_,_/___/___/_/___/
 						SecondLogic @ Inspare
]]

local car = script.Parent.Car.Value
local cam = workspace.CurrentCamera
local RS = game:GetService("RunService")

car.DriveSeat.ChildRemoved:connect(function(child)
	if child.Name=="SeatWeld" then
		RS:UnbindFromRenderStep("MCam")
		cam.CameraType = Enum.CameraType.Custom
	end
end)

script.Parent.Values.MouseSteerOn.Changed:connect(function(property)
	if script.Parent.Values.MouseSteerOn.Value then
		RS:BindToRenderStep("MCam",Enum.RenderPriority.Camera.Value,function()	
			cam.CameraType = Enum.CameraType.Scriptable
			local pspeed = math.min(1,car.DriveSeat.Velocity.Magnitude/500)
			local cc = car.DriveSeat.Position+Vector3.new(0,8+(pspeed*2),0)-(car.DriveSeat.CFrame.lookVector*17)+(car.DriveSeat.Velocity.Unit*-7*pspeed)
			cam.CoordinateFrame = CFrame.new(cc,car.DriveSeat.Position)
		end)
	else
		RS:UnbindFromRenderStep("MCam")
		cam.CameraType = Enum.CameraType.Custom
	end
end)