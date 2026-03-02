--BASE SCRIPT BY ADDISONSHIU
local total = 6 --Enter the last number here

function check(String,Num,Dest,Via)
	if script.Parent.Value.Value == String then 
	for i,v in pairs(script.Parent:GetChildren())do
			if v.Name == "Num" then
				v.SurfaceGui.TextLabel.Text = Num
			elseif v.Name == "Dest" then
				v.SurfaceGui.TextLabel.Text = Dest
			end
		end
	end
end
function reset()
	if script.Parent.Value.Value < 0 or script.Parent.Value.Value > total then
		script.Parent.Value.Value = 0
	end
end

while true do
wait()
--check(Sign_ID (0,1,2,3...) , "Route No", "Destination")
check(0,"1:","Urban Mini")
check(1,"2:","Chartered")
check(2,"3:","Not In SVC")

reset()
end

