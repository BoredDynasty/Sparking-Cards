local car = script.Parent.Car.Value
script.Parent.Values.SteerC.Changed:connect(function()
	local ex = 1
	if script.Parent.Values.SteerC.Value<0 then ex=-1 end
	car.Misc.SW.SS.Motor.DesiredAngle = script.Parent.Values.SteerC.Value^2*math.rad(-90)*ex
end)