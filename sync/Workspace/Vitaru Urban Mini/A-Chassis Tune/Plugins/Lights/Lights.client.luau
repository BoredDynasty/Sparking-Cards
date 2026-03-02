local car = script.Parent.Parent.Car.Value
local GBrake = script.Parent.Parent.Values.Brake
local light=0

function Light(on)
	for i,v in pairs(car.Body.Lights:GetChildren()) do
		if v:FindFirstChild("Light")~=nil then
			v.Light.Enabled=on
		end
		if on and v.BrickColor~=BrickColor.new("Really black") then
			v.Material=Enum.Material.Neon
		else
			v.Material=Enum.Material.SmoothPlastic
		end
		if v.Name=="FF" then
			if on then
				v.Transparency=.4
				v.BrickColor=BrickColor.new("Pearl")
				v.D.Transparency=.5
			else
				v.Transparency=.7
				v.BrickColor=BrickColor.new("Dark stone grey")
				v.D.Transparency=1
			end
		end
	end
end

function AutoLight()
	if light==0 then
		if (game.Lighting:GetMinutesAfterMidnight()<390 or game.Lighting:GetMinutesAfterMidnight()>1050) then
			Light(true)
		else
			Light(false)
		end
	end
end

script.Parent.MouseButton1Click:connect(function()
	if light==1 then
		light=-1
	else
		light=light+1
	end
	if light==0 then
		script.Parent.Text="Lights: Auto"
		if game.Lighting:GetMinutesAfterMidnight()<390 or game.Lighting:GetMinutesAfterMidnight()>1050 then
			Light(true)
		else
			Light(false)
		end
	elseif light==1 then
		script.Parent.Text="Lights: On"
		Light(true)
	else
		script.Parent.Text="Lights: Off"
		Light(false)
	end
end)

script.Parent.Parent.Values.Brake.Changed:connect(function()
	for i,v in pairs(car.Body.Lights:GetChildren()) do
		if v.Name=="R" then
			if v.Light.Enabled then
				if GBrake.Value>0 then
					v.Light.Brightness=12
					v.Light.Range=15
				else
					v.Light.Brightness=8
					v.Light.Range=10
				end
				
				if GBrake.Value>0 then
					v.Material=Enum.Material.Neon
				else
					v.Material=Enum.Material.SmoothPlastic
				end
			end
		elseif v.Name=="RR" then
			if GBrake.Value>0 then
				v.Material=Enum.Material.Neon
				if v.Light.Enabled then
					v.Transparency=.4
				else
					v.Transparency=.7
				end
			else
				v.Transparency=.7
				if v.Light.Enabled then
					v.Material=Enum.Material.Neon
				else
					v.Material=Enum.Material.SmoothPlastic
				end
			end
		end
	end
end)

game.Lighting.Changed:connect(AutoLight)
AutoLight()
