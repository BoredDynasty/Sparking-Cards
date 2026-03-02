Visible = script.Parent
DoorB = Visible.Parent
while true do
	if Visible.Value == false then
		DoorB.Glass.Transparency = 0.65
		DoorB.Door.Transparency = 0
		DoorB.Handle.Transparency = 0
		DoorB.L1.Transparency = 0.8
		DoorB.L2.Transparency = 0.8
		DoorB.L3.Transparency = 0.8
		DoorB.L4.Transparency = 0.8
		DoorB.Glass.CanCollide = true
		DoorB.Door.CanCollide = true
		DoorB.Handle.CanCollide = true
		
	elseif Visible.Value == true then
		DoorB.Glass.Transparency = 1
		DoorB.Door.Transparency = 1
		DoorB.Handle.Transparency = 1
		DoorB.L1.Transparency = 0
		DoorB.L2.Transparency = 0
		DoorB.L3.Transparency = 0
		DoorB.L4.Transparency = 0
		DoorB.Glass.CanCollide = false
		DoorB.Door.CanCollide = false
		DoorB.Handle.CanCollide = false
		
	end
wait()
end



