--[[
		___      _______                _     
	   / _ |____/ ___/ /  ___ ____ ___ (_)__ 
	  / __ /___/ /__/ _ \/ _ `(_-<(_-</ (_-<
	 /_/ |_|   \___/_//_/\_,_/___/___/_/___/
 						SecondLogic @ Inspare
]]


local autoscaling	= false					--Estimates top speed

local UNITS	= {								--Click on speed to change units
											--First unit is default	
	{
		units			= "MPH"				,
		scaling			= (10/12) * (60/88)	, -- 1 stud : 10 inches | ft/s to MPH
		maxSpeed		= 230				,
		spInc			= 20				, -- Increment between labelled notches
	},
	
	{
		units			= "KM/H"			,
		scaling			= (10/12) * 1.09728	, -- 1 stud : 10 inches | ft/s to KP/H
		maxSpeed		= 370				,
		spInc			= 40				, -- Increment between labelled notches
	},
	
	{
		units			= "SPS"				,
		scaling			= 1					, -- Roblox standard
		maxSpeed		= 400				,
		spInc			= 40				, -- Increment between labelled notches
	}
}

-----------------------------------------------------------------------------------------------

script.Parent:WaitForChild("Speedo")
script.Parent:WaitForChild("Tach")
script.Parent:WaitForChild("ln")
script.Parent:WaitForChild("Gear")
script.Parent:WaitForChild("Speed")

local player=game.Players.LocalPlayer
local mouse=player:GetMouse()

local car = script.Parent.Parent.Car.Value
car.DriveSeat.HeadsUpDisplay = false

local _Tune = require(car["A-Chassis Tune"])

local _pRPM = _Tune.PeakRPM
local _lRPM = _Tune.Redline

local currentUnits = 1
local revEnd = math.ceil(_lRPM/1000)

--Automatic Gauge Scaling
if autoscaling then
	local Drive={}
	if _Tune.Config == "FWD" or _Tune.Config == "AWD" then
		if car.Wheels:FindFirstChild("FL")~= nil then
			table.insert(Drive,car.Wheels.FL)
		end
		if car.Wheels:FindFirstChild("FR")~= nil then
			table.insert(Drive,car.Wheels.FR)
		end
		if car.Wheels:FindFirstChild("F")~= nil then
			table.insert(Drive,car.Wheels.F)
		end
	end
	if _Tune.Config == "RWD" or _Tune.Config == "AWD" then
		if car.Wheels:FindFirstChild("RL")~= nil then
			table.insert(Drive,car.Wheels.RL)
		end
		if car.Wheels:FindFirstChild("RR")~= nil then
			table.insert(Drive,car.Wheels.RR)
		end
		if car.Wheels:FindFirstChild("R")~= nil then
			table.insert(Drive,car.Wheels.R)
		end
	end

	local wDia = 0
	for i,v in pairs(Drive) do
		if v.Size.x>wDia then wDia = v.Size.x end
	end
	Drive = nil
	for i,v in pairs(UNITS) do
		v.maxSpeed = math.ceil(v.scaling*wDia*math.pi*_lRPM/60/_Tune.Ratios[#_Tune.Ratios]/_Tune.FinalDrive)
		v.spInc = math.max(math.ceil(v.maxSpeed/200)*20,20)
	end
end

for i=0,revEnd*2 do
	local ln = script.Parent.ln:clone()
	ln.Parent = script.Parent.Tach
	ln.Rotation = 45 + i * 225 / (revEnd*2)
	ln.Num.Text = i/2
	ln.Num.Rotation = -ln.Rotation
	if i*500>=math.floor(_pRPM/500)*500 then
		ln.Frame.BackgroundColor3 = Color3.new(1,0,0)
		if i<revEnd*2 then
			ln2 = ln:clone()
			ln2.Parent = script.Parent.Tach
			ln2.Rotation = 45 + (i+.5) * 225 / (revEnd*2)
			ln2.Num:Destroy()
			ln2.Visible=true
		end
	end
	if i%2==0 then
		ln.Frame.Size = UDim2.new(0,3,0,10)
		ln.Frame.Position = UDim2.new(0,-1,0,100)
		ln.Num.Visible = true
	else
		ln.Num:Destroy()
	end
	ln.Visible=true
end

local lns = Instance.new("Frame",script.Parent.Speedo)
lns.Name = "lns"
lns.BackgroundTransparency = 1
lns.BorderSizePixel = 0
lns.Size = UDim2.new(0,0,0,0)
for i=1,90 do
	local ln = script.Parent.ln:clone()
	ln.Parent = lns
	ln.Rotation = 45 + 225*(i/90)
	if i%2==0 then
		ln.Frame.Size = UDim2.new(0,2,0,10)
		ln.Frame.Position = UDim2.new(0,-1,0,100)
	else
		ln.Frame.Size = UDim2.new(0,3,0,5)
	end
	ln.Num:Destroy()
	ln.Visible=true
end

for i,v in pairs(UNITS) do
	local lnn = Instance.new("Frame",script.Parent.Speedo)
	lnn.BackgroundTransparency = 1
	lnn.BorderSizePixel = 0
	lnn.Size = UDim2.new(0,0,0,0)
	lnn.Name = v.units
	if i~= 1 then lnn.Visible=false end
	
	for i=0,v.maxSpeed,v.spInc do
		local ln = script.Parent.ln:clone()
		ln.Parent = lnn
		ln.Rotation = 45 + 225*(i/v.maxSpeed)
		ln.Num.Text = i
		ln.Num.TextSize = 14
		ln.Num.Rotation = -ln.Rotation
		ln.Frame:Destroy()
		ln.Num.Visible=true
		ln.Visible=true
	end
end

if 	script.Parent.Parent.IsOn.Value then
	script.Parent:TweenPosition(UDim2.new(0, 0, 0, 0),Enum.EasingDirection.InOut,Enum.EasingStyle.Quad,1,true)
end

script.Parent.Parent.IsOn.Changed:connect(function()
	if script.Parent.Parent.IsOn.Value then
		script.Parent:TweenPosition(UDim2.new(0, 0, 0, 0),Enum.EasingDirection.InOut,Enum.EasingStyle.Quad,1,true)
	end
end)

script.Parent.Parent.Values.RPM.Changed:connect(function()
	script.Parent.Tach.Needle.Rotation = 45 + 225 * math.min(1,script.Parent.Parent.Values.RPM.Value / (revEnd*1000))
end)

script.Parent.Parent.Values.Gear.Changed:connect(function()
	local gearText = script.Parent.Parent.Values.Gear.Value
	if gearText == 0 then gearText = "N"
	elseif gearText == -1 then gearText = "R"
	end
	script.Parent.Gear.Text = gearText
end)

script.Parent.Parent.Values.TCS.Changed:connect(function()
	if _Tune.TCSEnabled then
		if script.Parent.Parent.Values.TCS.Value then
			script.Parent.TCS.TextColor3 = Color3.new(1,170/255,0)
			script.Parent.TCS.TextStrokeColor3 = Color3.new(1,170/255,0)
			if script.Parent.Parent.Values.TCSActive.Value then
				wait()
				script.Parent.TCS.Visible = not script.Parent.TCS.Visible
			else
				wait()
				script.Parent.TCS.Visible = false
			end
		else
			script.Parent.TCS.Visible = true
			script.Parent.TCS.TextColor3 = Color3.new(1,0,0)
			script.Parent.TCS.TextStrokeColor3 = Color3.new(1,0,0)
		end
	else
		script.Parent.TCS.Visible = false
	end
end)

script.Parent.Parent.Values.TCSActive.Changed:connect(function()
	if _Tune.TCSEnabled then
		if script.Parent.Parent.Values.TCSActive.Value and script.Parent.Parent.Values.TCS.Value then
			wait()
			script.Parent.TCS.Visible = not script.Parent.TCS.Visible
		elseif not script.Parent.Parent.Values.TCS.Value then
			wait()
			script.Parent.TCS.Visible = true
		else
			wait()
			script.Parent.TCS.Visible = false
		end
	else
		script.Parent.TCS.Visible = false
	end
end)

script.Parent.TCS.Changed:connect(function()
	if _Tune.TCSEnabled then
		if script.Parent.Parent.Values.TCSActive.Value and script.Parent.Parent.Values.TCS.Value then
			wait()
			script.Parent.TCS.Visible = not script.Parent.TCS.Visible
		elseif not script.Parent.Parent.Values.TCS.Value then
			wait()
			script.Parent.TCS.Visible = true
		end
	else
		if script.Parent.TCS.Visible then
			script.Parent.TCS.Visible = false
		end
	end
end)

script.Parent.Parent.Values.ABS.Changed:connect(function()
	if _Tune.ABSEnabled then
		if script.Parent.Parent.Values.ABS.Value then
			script.Parent.ABS.TextColor3 = Color3.new(1,170/255,0)
			script.Parent.ABS.TextStrokeColor3 = Color3.new(1,170/255,0)
			if script.Parent.Parent.Values.ABSActive.Value then
				wait()
				script.Parent.ABS.Visible = not script.Parent.ABS.Visible
			else
				wait()
				script.Parent.ABS.Visible = false
			end
		else
			script.Parent.ABS.Visible = true
			script.Parent.ABS.TextColor3 = Color3.new(1,0,0)
			script.Parent.ABS.TextStrokeColor3 = Color3.new(1,0,0)
		end
	else
		script.Parent.ABS.Visible = false
	end
end)

script.Parent.Parent.Values.ABSActive.Changed:connect(function()
	if _Tune.ABSEnabled then
		if script.Parent.Parent.Values.ABSActive.Value and script.Parent.Parent.Values.ABS.Value then
			wait()
			script.Parent.ABS.Visible = not script.Parent.ABS.Visible
		elseif not script.Parent.Parent.Values.ABS.Value then
			wait()
			script.Parent.ABS.Visible = true
		else
			wait()
			script.Parent.ABS.Visible = false
		end
	else
		script.Parent.ABS.Visible = false
	end
end)

script.Parent.ABS.Changed:connect(function()
	if _Tune.ABSEnabled then
		if script.Parent.Parent.Values.ABSActive.Value and script.Parent.Parent.Values.ABS.Value then
			wait()
			script.Parent.ABS.Visible = not script.Parent.ABS.Visible
		elseif not script.Parent.Parent.Values.ABS.Value then
			wait()
			script.Parent.ABS.Visible = true
		end
	else
		if script.Parent.ABS.Visible then
			script.Parent.ABS.Visible = false
		end
	end
end)


function PBrake()
	script.Parent.PBrake.Visible = script.Parent.Parent.Values.PBrake.Value
end
script.Parent.Parent.Values.PBrake.Changed:connect(PBrake)

function Gear()
	if script.Parent.Parent.Values.TransmissionMode.Value == "Auto" then
		script.Parent.TMode.Text = "A/T"
		script.Parent.TMode.BackgroundColor3 = Color3.new(1,170/255,0)
	elseif script.Parent.Parent.Values.TransmissionMode.Value == "Semi" then
		script.Parent.TMode.Text = "S/T"
		script.Parent.TMode.BackgroundColor3 = Color3.new(0, 170/255, 127/255) 
	else
		script.Parent.TMode.Text = "M/T"
		script.Parent.TMode.BackgroundColor3 = Color3.new(1,85/255,.5)
	end
end
script.Parent.Parent.Values.TransmissionMode.Changed:connect(Gear)

script.Parent.Parent.Values.Velocity.Changed:connect(function(property)
	script.Parent.Speedo.Needle.Rotation =45 + 225 * math.min(1,UNITS[currentUnits].scaling*script.Parent.Parent.Values.Velocity.Value.Magnitude/UNITS[currentUnits].maxSpeed)
	script.Parent.Speed.Text = math.floor(UNITS[currentUnits].scaling*script.Parent.Parent.Values.Velocity.Value.Magnitude) .. " "..UNITS[currentUnits].units
end)

script.Parent.Speed.MouseButton1Click:connect(function()
	if currentUnits==#UNITS then
		currentUnits = 1
	else
		currentUnits = currentUnits+1
	end
	for i,v in pairs(script.Parent.Speedo:GetChildren()) do
		v.Visible=v.Name==UNITS[currentUnits].units or v.Name=="Needle" or v.Name=="lns"
	end
	script.Parent.Speed.Text = math.floor(UNITS[currentUnits].scaling*script.Parent.Parent.Values.Velocity.Value.Magnitude) .. " "..UNITS[currentUnits].units
end)

wait(.1)
Gear()
PBrake()
