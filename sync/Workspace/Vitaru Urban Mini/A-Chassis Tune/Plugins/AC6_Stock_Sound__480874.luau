--[[
		___      _______                _     
	   / _ |____/ ___/ /  ___ ____ ___ (_)__ 
	  / __ /___/ /__/ _ \/ _ `(_-<(_-</ (_-<
	 /_/ |_|   \___/_//_/\_,_/___/___/_/___/
 						SecondLogic @ Inspare
]]
local FE = workspace.FilteringEnabled
local car = script.Parent.Car.Value
local _Tune = require(car["A-Chassis Tune"])
local on = 0

script:WaitForChild("Engine2")

if not FE then
	for i,v in pairs(car.DriveSeat:GetChildren()) do
		for _,a in pairs(script:GetChildren()) do
			if v.Name==a.Name then v:Stop() wait() v:Destroy() end
		end
	end
	for i,v in pairs(script:GetChildren()) do
		v.Parent=car.DriveSeat
	end
	
	car.DriveSeat.Engine2:Play()
	
	while wait() do
		local _RPM = script.Parent.Values.RPM.Value
		
		if not script.Parent.IsOn.Value then on=math.max(on-.015,0) else on=1 end
		car.DriveSeat.Engine2.Pitch = (car.DriveSeat.Engine2.SetPitch.Value + car.DriveSeat.Engine2.SetRev.Value*_RPM/_Tune.Redline)*on^2
	end
else
	local handler = car.AC6_FE_Sounds
	handler:FireServer("newSound","Engine2",car.DriveSeat,script.Engine2.SoundId,0,script.Engine2.Volume,true)
	handler:FireServer("playSound","Engine2")
	local pitch=0
	while wait() do
		local _RPM = script.Parent.Values.RPM.Value
		
		if not script.Parent.IsOn.Value then on=math.max(on-.015,0) else on=1 end
		pitch = (script.Engine2.SetPitch.Value + script.Engine2.SetRev.Value*_RPM/_Tune.Redline)*on^2
		handler:FireServer("updateSound","Engine2",script.Engine2.SoundId,pitch,script.Engine2.Volume)
	end
end
