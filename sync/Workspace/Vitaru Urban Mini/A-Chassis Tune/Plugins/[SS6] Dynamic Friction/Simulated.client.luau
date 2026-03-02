  				    --//AC6 Ported Plugin [SS6]//--
				  --//SecondLogic x INSPARE 2017//--


--------------------------------------------------------------------------

local _WHEELTUNE = {
																		--[[	
			SS6 Presets
	[Eco]		
		WearSpeed = 1,
		TargetFriction = .7,
		MinFriction = .1,
	[Road]		
		WearSpeed = 2,
		TargetFriction = .7,
		MinFriction = .1,
	[Sport]		
		WearSpeed = 3,
		TargetFriction = .79,
		MinFriction = .1,											]]

	TireWearOn 		= true	,
	
	--Friction and Wear
	FWearSpeed		= .4	,
	FTargetFriction	= .7	,
	FMinFriction 	= .1	,
	
	RWearSpeed		= .4	,
	RTargetFriction	= .7	,
	RMinFriction	= .1	,
	
	--Tire Slip
	TCSOffRatio		= 1/3	,
	WheelLockRatio	= 1/2	,	--SS6 Default = 1/4
	WheelspinRatio	= 1/1.1	,	--SS6 Default = 1/1.2
	
	--Wheel Properties
	FFrictionWeight	= 1		,	--SS6 Default = 1
	RFrictionWeight	= 1		,	--SS6 Default = 1
	FLgcyFrWeight	= 10	,
	RLgcyFrWeight	= 10	,
	
	FElasticity		= .5		,	--SS6 Default = .5
	RElasticity		= .5		,	--SS6 Default = .5
	FLgcyElasticity	= 0		,
	RLgcyElasticity	= 0		,
	
	FElastWeight	= 1		,	--SS6 Default = 1
	RElastWeight	= 1		,	--SS6 Default = 1
	FLgcyElWeight	= 10	,
	RLgcyElWeight	= 10	,
	
	--Wear Regen
	RegenSpeed		= 3.6		--SS6 Default = 3.6
}

--------------------------------------------------------------------------


local car = script.Parent.Parent.Car.Value
local _Tune = require(car["A-Chassis Tune"])
local cValues = script.Parent.Parent:WaitForChild("Values")

--Wheels Array
local fDensity = _Tune.FWheelDensity
local rDensity = _Tune.RWheelDensity
local fFwght = _WHEELTUNE.FFrictionWeight
local rFwght = _WHEELTUNE.RFrictionWeight
local fElast = _WHEELTUNE.FElasticity
local rElast = _WHEELTUNE.RElasticity
local fEwght = _WHEELTUNE.FElastWeight
local rEwght = _WHEELTUNE.RElastWeight
if not workspace:PGSIsEnabled() then
	fDensity = _Tune.FWLgcyDensity
	rDensity = _Tune.RWLgcyDensity
	fFwght = _WHEELTUNE.FLgcyFrWeight
	rFwght = _WHEELTUNE.FLgcyFrWeight
	fElast = _WHEELTUNE.FLgcyElasticity
	rElast = _WHEELTUNE.RLgcyElasticity
	fEwght = _WHEELTUNE.FLgcyElWeight
	rEwght = _WHEELTUNE.RLgcyElWeight
end
local Wheels = {}
for i,v in pairs(car.Wheels:GetChildren()) do
	local w = {}
	w.wheel = v
	local ca
	w.x = 0
	if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
		ca = (12-math.abs(_Tune.FCamber))/15
		w.x = fDensity
		w.BaseHeat = _WHEELTUNE.FTargetFriction-_WHEELTUNE.FMinFriction
		w.WearSpeed = _WHEELTUNE.FWearSpeed
		w.fWeight = fFwght
		w.elast = fElast
		w.eWeight = fEwght
	else
		ca = (12-math.abs(_Tune.RCamber))/15
		w.x = rDensity
		w.BaseHeat = _WHEELTUNE.RTargetFriction-_WHEELTUNE.RMinFriction
		w.WearSpeed = _WHEELTUNE.RWearSpeed
		w.fWeight = rFwght
		w.elast = rElast
		w.eWeight = rEwght
	end
	--if car:FindFirstChild("WearData")~=nil then
	--	w.Heat = math.min(w.BaseHeat,car.WearData[v.Name].Value+(((tick()-car.WearData.STime.Value)*_WHEELTUNE.RegenSpeed*15/10000)))
	--else
		w.Heat = w.BaseHeat
	--end
	w.stress = 0
	table.insert(Wheels,w)
end

--Close/Store Wear Data
car.DriveSeat.ChildRemoved:connect(function(child)
	if child.Name=="SeatWeld" then
		local wD=car:FindFirstChild("WearData")
		if car:FindFirstChild("WearData")==nil then
			wD = script.Parent.WearData:Clone()
			wD.Parent=car
		end
		for i,v in pairs(Wheels) do
			wD[v.wheel.Name].Value = v.Heat
		end
		wD.STime.Value=tick()
	end
end)

--Runtime Loop
while wait() do
	for i,v in pairs(Wheels) do
		--Vars
		local speed = car.DriveSeat.Velocity.Magnitude
		local wheel = v.wheel.RotVelocity.Magnitude
		local z = 0		
		local deg = 0.000126
		
		--Tire Wear
		local cspeed = (speed/1.298)*(2.6/v.wheel.Size.Y) 
		local wdif = math.abs(wheel-cspeed)
		if _WHEELTUNE.TireWearOn then
			if speed < 4 then
				--Wear Regen
				v.Heat = math.min(v.Heat + _WHEELTUNE.RegenSpeed/10000,v.BaseHeat)
			else
				--Tire Wear
				if wdif > 1 then
					v.Heat = v.Heat - wdif*deg*v.WearSpeed/28
				elseif v.Heat >= v.BaseHeat then
					v.Heat = v.BaseHeat
				end
			end
		end
		
		--Apply Friction
		if v.wheel.Name == "FL" or v.wheel.Name == "FR" or v.wheel.Name == "F" then
			z = _WHEELTUNE.FMinFriction+v.Heat
			deg = ((deg - 0.0001188*cValues.Brake.Value)*(1-math.abs(cValues.SteerC.Value))) + 0.00000126*math.abs(cValues.SteerC.Value)
		else
			z = _WHEELTUNE.RMinFriction+v.Heat
		end
		
		--Tire Slip
		if math.ceil((wheel/0.774/speed)*100) < 8 then
			--Lock Slip
			v.wheel.CustomPhysicalProperties = PhysicalProperties.new(v.x,z*_WHEELTUNE.WheelLockRatio,v.elast,v.fWeight,v.eWeight)
			v.Heat = math.max(v.Heat,0)
		elseif (_Tune.TCSEnabled and cValues.TCS.Value == false and math.ceil((wheel/0.774/speed)*100) > 80) then
			--TCS Off
			v.wheel.CustomPhysicalProperties = PhysicalProperties.new(v.x,z*_WHEELTUNE.TCSOffRatio,v.elast,v.fWeight,v.eWeight)
			v.Heat = math.max(v.Heat,0)
		elseif math.ceil((wheel/0.774/speed)*100) > 130 then
			--Wheelspin
			v.wheel.CustomPhysicalProperties = PhysicalProperties.new(v.x,z*_WHEELTUNE.WheelspinRatio,v.elast,v.fWeight,v.eWeight)		
			v.Heat = math.max(v.Heat,0)
		else
			--No Slip
			v.wheel.CustomPhysicalProperties = PhysicalProperties.new(v.x,z,v.elast,v.fWeight,v.eWeight)
			v.Heat = math.min(v.Heat,v.BaseHeat)
		end 
		
		--Update UI
		local vstress = math.abs(((((wdif+cspeed)/0.774)*0.774)-cspeed)/15)
		if vstress > 0.05 and vstress > v.stress then 
			v.stress = math.min(v.stress + 0.03,1)
		else
			v.stress = math.max(v.stress - 0.03,vstress)	
		end
		local UI = script.Parent.Tires[v.wheel.Name]
		UI.First.Second.Image.ImageColor3 = Color3.new(math.min((v.stress*2),1), 1-v.stress, 0)
		UI.First.Position = UDim2.new(0,0,1-v.Heat/v.BaseHeat,0)
		UI.First.Second.Position = UDim2.new(0,0,v.Heat/v.BaseHeat,0)
	end
end