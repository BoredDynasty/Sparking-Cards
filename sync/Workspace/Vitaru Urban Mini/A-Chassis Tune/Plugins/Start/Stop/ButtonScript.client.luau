--[[ 
Button created by SprinterBZR. I will help you how to make a startup script. Or simply, you can just copy-paste into another car.
Touching some of the scripts can break the car. I advise you not touch these scripts.
--]]
wait(0.2) -- Removing this wait could break the script. Please do not touch this.
-- Variables (best not to touch these!)
local button = script.Parent 
local car = script.Parent.Parent.Car.Value
local sound = script.Parent.Start
local sound1 = script.Parent.Start1
local sound2 = script.Parent.Start2
sound.Parent = car.DriveSeat -- What brick the start sound is playing from.
button.MouseButton1Click:connect(function() -- Event when the button is clicked
	if script.Parent.Text == "Engine: Off" then -- If the text says it's off then..
		sound:Play()
		sound2:Play() -- Startup sound plays..
		wait(0.6)
		sound1:Play()
		wait(0.05) -- For realism. Okay?
		script.Parent.Parent.IsOn.Value = true -- The car is is on, or in other words, start up the car.
		button.Text = "Engine: On"-- You don't really need this, but I would keep it.
	else -- If it's on then when you click the button,
		script.Parent.Parent.IsOn.Value = false -- The car is turned off.
		button.Text = "Engine: Off"
		sound1:Play()
	end -- Don't touch this.
end) -- And don't touch this either.
