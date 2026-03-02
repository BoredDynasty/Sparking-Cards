--[[
		___      _______                _     
	   / _ |____/ ___/ /  ___ ____ ___ (_)__ 
	  / __ /___/ /__/ _ \/ _ `(_-<(_-</ (_-<
	 /_/ |_|   \___/_//_/\_,_/___/___/_/___/
 						SecondLogic @ Inspare
]]

--[[START]]

	_BuildVersion = require(script.Parent.README)

--[[Weld functions]]

	local JS = game:GetService("JointsService")
	local PGS_ON = workspace:PGSIsEnabled()
	
	function MakeWeld(x,y,type,s) 
		if type==nil then type="Weld" end
		local W=Instance.new(type,JS) 
		W.Part0=x W.Part1=y 
		W.C0=x.CFrame:inverse()*x.CFrame 
		W.C1=y.CFrame:inverse()*x.CFrame 
		if type=="Motor" and s~=nil then 
			W.MaxVelocity=s 
		end 
		return W	
	end
	
	function ModelWeld(a,b) 
		if a:IsA("BasePart") then 
			MakeWeld(b,a,"Weld") 
		elseif a:IsA("Model") then 
			for i,v in pairs(a:GetChildren()) do 
				ModelWeld(v,b) 
			end 
		end 
	end
	
	function UnAnchor(a) 
		if a:IsA("BasePart") then a.Anchored=false  end for i,v in pairs(a:GetChildren()) do UnAnchor(v) end 
	end


	
--[[Initialize]]

	script.Parent:WaitForChild("A-Chassis Interface")
	script.Parent:WaitForChild("Plugins")
	script.Parent:WaitForChild("README")
	
	local car=script.Parent.Parent
	local _Tune=require(script.Parent)
	
	wait(_Tune.LoadDelay)
	
	--Weight Scaling
	local weightScaling = _Tune.WeightScaling
	if not workspace:PGSIsEnabled() then
		weightScaling = _Tune.LegacyScaling
	end

	local Drive=car.Wheels:GetChildren()
	
	--Remove Existing Mass
	function DReduce(p)
		for i,v in pairs(p:GetChildren())do
			if v:IsA("BasePart") then
				if v.CustomPhysicalProperties == nil then v.CustomPhysicalProperties = PhysicalProperties.new(v.Material) end
				v.CustomPhysicalProperties = PhysicalProperties.new(
					0,
					v.CustomPhysicalProperties.Friction,
					v.CustomPhysicalProperties.Elasticity,
					v.CustomPhysicalProperties.FrictionWeight,
					v.CustomPhysicalProperties.ElasticityWeight
				)
			end
			DReduce(v)
		end
	end
	DReduce(car)



--[[Wheel Configuration]]	
	
	--Store Reference Orientation Function
	function getParts(model,t,a)
		for i,v in pairs(model:GetChildren()) do
			if v:IsA("BasePart") then table.insert(t,{v,a.CFrame:toObjectSpace(v.CFrame)})
			elseif v:IsA("Model") then getParts(v,t,a)
			end
		end
	end
	
	--PGS/Legacy
	local fDensity = _Tune.FWheelDensity
	local rDensity = _Tune.RWheelDensity
	if not PGS_ON then
		fDensity = _Tune.FWLgcyDensity
		rDensity = _Tune.RWLgcyDensity
	end
	
	local fDistX=_Tune.FWsBoneLen*math.cos(math.rad(_Tune.FWsBoneAngle))
	local fDistY=_Tune.FWsBoneLen*math.sin(math.rad(_Tune.FWsBoneAngle))
	local rDistX=_Tune.RWsBoneLen*math.cos(math.rad(_Tune.RWsBoneAngle))
	local rDistY=_Tune.RWsBoneLen*math.sin(math.rad(_Tune.RWsBoneAngle))
	
	local fSLX=_Tune.FSusLength*math.cos(math.rad(_Tune.FSusAngle))
	local fSLY=_Tune.FSusLength*math.sin(math.rad(_Tune.FSusAngle))
	local rSLX=_Tune.RSusLength*math.cos(math.rad(_Tune.RSusAngle))
	local rSLY=_Tune.RSusLength*math.sin(math.rad(_Tune.RSusAngle))
	
	for _,v in pairs(Drive) do
		--Apply Wheel Density
		if v.Name=="FL" or v.Name=="FR" or v.Name=="F" then
			if v:IsA("BasePart") then
				if v.CustomPhysicalProperties == nil then v.CustomPhysicalProperties = PhysicalProperties.new(v.Material) end
				v.CustomPhysicalProperties = PhysicalProperties.new(
					fDensity,
					v.CustomPhysicalProperties.Friction,
					v.CustomPhysicalProperties.Elasticity,
					v.CustomPhysicalProperties.FrictionWeight,
					v.CustomPhysicalProperties.ElasticityWeight
				)
			end
		else
			if v:IsA("BasePart") then
				if v.CustomPhysicalProperties == nil then v.CustomPhysicalProperties = PhysicalProperties.new(v.Material) end
				v.CustomPhysicalProperties = PhysicalProperties.new(
					rDensity,
					v.CustomPhysicalProperties.Friction,
					v.CustomPhysicalProperties.Elasticity,
					v.CustomPhysicalProperties.FrictionWeight,
					v.CustomPhysicalProperties.ElasticityWeight
				)
			end		
		end
		
		--Resurface Wheels
		for _,a in pairs({"Top","Bottom","Left","Right","Front","Back"}) do
			v[a.."Surface"]=Enum.SurfaceType.SmoothNoOutlines
		end
		
		--Store Axle-Anchored/Suspension-Anchored Part Orientation
		local WParts = {}
		
		local tPos = v.Position-car.DriveSeat.Position
		if v.Name=="FL" or v.Name=="RL" then
			v.CFrame = car.DriveSeat.CFrame*CFrame.Angles(math.rad(90),0,math.rad(90))
		else
			v.CFrame = car.DriveSeat.CFrame*CFrame.Angles(math.rad(90),0,math.rad(-90))
		end
		v.CFrame = v.CFrame+tPos
		
		if v:FindFirstChild("Parts")~=nil then
			getParts(v.Parts,WParts,v)
		end
		if v:FindFirstChild("Fixed")~=nil then
			getParts(v.Fixed,WParts,v)
		end
		
		--Align Wheels
		if v.Name=="FL" or v.Name=="FR" then
			v.CFrame = v.CFrame*CFrame.Angles(math.rad(_Tune.FCamber),0,0)
			if v.Name=="FL" then
				v.CFrame = v.CFrame*CFrame.Angles(0,0,math.rad(_Tune.FToe))
			else
				v.CFrame = v.CFrame*CFrame.Angles(0,0,math.rad(-_Tune.FToe))
			end
		elseif v.Name=="RL" or v.Name=="RR" then
			v.CFrame = v.CFrame*CFrame.Angles(math.rad(_Tune.RCamber),0,0)
			if v.Name=="RL" then
				v.CFrame = v.CFrame*CFrame.Angles(0,0,math.rad(_Tune.RToe))
			else
				v.CFrame = v.CFrame*CFrame.Angles(0,0,math.rad(-_Tune.RToe))
			end
		end
		
		--Re-orient Axle-Anchored/Suspension-Anchored Parts
		for _,a in pairs(WParts) do
			a[1].CFrame=v.CFrame:toWorldSpace(a[2])
		end



--[[Chassis Assembly]]
		--Create Steering Axle
		local arm=Instance.new("Part",v)
		arm.Name="Arm"
		arm.Anchored=true
		arm.CanCollide=false
		arm.FormFactor=Enum.FormFactor.Custom
		arm.Size=Vector3.new(_Tune.AxleSize,_Tune.AxleSize,_Tune.AxleSize)
		arm.CFrame=(v.CFrame*CFrame.new(0,_Tune.StAxisOffset,0))*CFrame.Angles(-math.pi/2,-math.pi/2,0)
		arm.CustomPhysicalProperties = PhysicalProperties.new(_Tune.AxleDensity,0,0,100,100)
		arm.TopSurface=Enum.SurfaceType.Smooth
		arm.BottomSurface=Enum.SurfaceType.Smooth
		arm.Transparency=1
			
		--Create Wheel Spindle
		local base=arm:Clone()
		base.Parent=v
		base.Name="Base"
		base.CFrame=base.CFrame*CFrame.new(0,_Tune.AxleSize,0)
		base.BottomSurface=Enum.SurfaceType.Hinge
		
		--Create Steering Anchor
		local axle=arm:Clone()
		axle.Parent=v
		axle.Name="Axle"
		axle.CFrame=CFrame.new(v.Position-((v.CFrame*CFrame.Angles(math.pi/2,0,0)).lookVector*((v.Size.x/2)+(axle.Size.x/2))),v.Position)*CFrame.Angles(0,math.pi,0)
		axle.BackSurface=Enum.SurfaceType.Hinge
		
		if v.Name=="F" or v.Name=="R" then
			local axle2=arm:Clone()
			axle2.Parent=v
			axle2.Name="Axle"
			axle2.CFrame=CFrame.new(v.Position+((v.CFrame*CFrame.Angles(math.pi/2,0,0)).lookVector*((v.Size.x/2)+(axle2.Size.x/2))),v.Position)*CFrame.Angles(0,math.pi,0)
			axle2.BackSurface=Enum.SurfaceType.Hinge
			MakeWeld(arm,axle2)
		end
		
		--Create Suspension
		if PGS_ON and _Tune.SusEnabled then			
			local sa=arm:Clone()
			sa.Parent=v
			sa.Name="#SA"
			if v.Name == "FL" or v.Name=="FR" or v.Name =="F" then
				local aOff = _Tune.FAnchorOffset
				sa.CFrame=v.CFrame*CFrame.new(_Tune.AxleSize/2,-fDistX,-fDistY)*CFrame.new(aOff[3],aOff[1],-aOff[2])*CFrame.Angles(-math.pi/2,-math.pi/2,0)
			else
				local aOff = _Tune.RAnchorOffset
				sa.CFrame=v.CFrame*CFrame.new(_Tune.AxleSize/2,-rDistX,-rDistY)*CFrame.new(aOff[3],aOff[1],-aOff[2])*CFrame.Angles(-math.pi/2,-math.pi/2,0)
			end
			
			local sb=sa:Clone()
			sb.Parent=v
			sb.Name="#SB"
			sb.CFrame=sa.CFrame*CFrame.new(0,0,_Tune.AxleSize)
			
			sb.FrontSurface=Enum.SurfaceType.Hinge	
			
			local g = Instance.new("BodyGyro",sb)
			g.Name = "Stabilizer"
			g.MaxTorque = Vector3.new(0,0,1)
			g.P = 0
			
			local sf1 = Instance.new("Attachment",sa)
			sf1.Name = "SAtt"
			
			local sf2 = sf1:Clone()
			sf2.Parent = sb
			
			
			if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
				sf1.Position = Vector3.new(fDistX-fSLX,-fDistY+fSLY,_Tune.AxleSize/2)
				sf2.Position = Vector3.new(fDistX,-fDistY,-_Tune.AxleSize/2)
			elseif v.Name == "RL" or v.Name=="RR" or v.Name == "R" then
				sf1.Position = Vector3.new(rDistX-rSLX,-rDistY+rSLY,_Tune.AxleSize/2)
				sf2.Position = Vector3.new(rDistX,-rDistY,-_Tune.AxleSize/2)
			end
			
			sb:MakeJoints()
			
			local sp = Instance.new("SpringConstraint",v)
			sp.Name = "Spring"
			sp.Attachment0 = sf1
			sp.Attachment1 = sf2
			sp.LimitsEnabled = true
			
			sp.Visible=_Tune.SusVisible
			sp.Radius=_Tune.SusRadius
			sp.Thickness=_Tune.SusThickness
			sp.Color=BrickColor.new(_Tune.SusColor)
			sp.Coils=_Tune.SusCoilCount
			
			if v.Name == "FL" or v.Name=="FR" or v.Name =="F" then
				g.D = _Tune.FAntiRoll
				sp.Damping = _Tune.FSusDamping
				sp.Stiffness = _Tune.FSusStiffness
				sp.FreeLength = _Tune.FSusLength+_Tune.FPreCompress
				sp.MaxLength = _Tune.FSusLength+_Tune.FExtensionLim
				sp.MinLength = _Tune.FSusLength-_Tune.FCompressLim
			else
				g.D = _Tune.RAntiRoll
				sp.Damping = _Tune.RSusDamping
				sp.Stiffness = _Tune.RSusStiffness
				sp.FreeLength = _Tune.RSusLength+_Tune.RPreCompress
				sp.MaxLength = _Tune.RSusLength+_Tune.RExtensionLim
				sp.MinLength = _Tune.RSusLength-_Tune.RCompressLim
			end
			
			MakeWeld(car.DriveSeat,sa)
			MakeWeld(sb,base)
		else
			MakeWeld(car.DriveSeat,base)
		end
		
		--Lock Rear Steering Axle
		if v.Name == "RL" or v.Name == "RR" or v.Name=="R" then
			MakeWeld(base,axle)
		end
		
		--Weld Assembly
		if v.Parent.Name == "RL" or v.Parent.Name == "RR" or v.Name=="R" then
			MakeWeld(car.DriveSeat,arm)
		end
		
		MakeWeld(arm,axle)
		
		arm:MakeJoints()
		axle:MakeJoints()
	
		--Weld Miscelaneous Parts
		if v:FindFirstChild("SuspensionFixed")~=nil then
			ModelWeld(v.SuspensionFixed,car.DriveSeat)
		end
		if v:FindFirstChild("WheelFixed")~=nil then
			ModelWeld(v.WheelFixed,axle)
		end
		if v:FindFirstChild("Fixed")~=nil then
			ModelWeld(v.Fixed,arm)
		end
		
		--Weld Wheel Parts
		if v:FindFirstChild("Parts")~=nil then
			ModelWeld(v.Parts,v)
		end
		
		--Add Steering Gyro
		if v:FindFirstChild("Steer") then
			v:FindFirstChild("Steer"):Destroy()
		end
		
		if v.Name=="FL" or v.Name=="FR" or v.Name=="F" then
			local steer=Instance.new("BodyGyro",arm)
			steer.Name="Steer"
			steer.P=_Tune.SteerP
			steer.D=_Tune.SteerD
			steer.MaxTorque=Vector3.new(0,_Tune.SteerMaxTorque,0)
			steer.cframe=v.CFrame*CFrame.Angles(0,-math.pi/2,0)
		end
		
		--Add Stabilization Gyro
		local gyro=Instance.new("BodyGyro",v)
		gyro.Name="Stabilizer"
		gyro.MaxTorque=Vector3.new(1,0,1)
		gyro.P=0
		if v.Name=="FL" or v.Name=="FR"  or v.Name=="F" then
			gyro.D=_Tune.FGyroDamp
		else
			gyro.D=_Tune.RGyroDamp
		end
		
		--Add Rotational BodyMover
		local AV=Instance.new("BodyAngularVelocity",v)
		AV.Name="#AV"
		AV.angularvelocity=Vector3.new(0,0,0)
		AV.maxTorque=Vector3.new(_Tune.PBrakeForce,0,_Tune.PBrakeForce)
		AV.P=1e9
	end



--[[Vehicle Weight]]	
	--Determine Current Mass
	local mass=0
	
	function getMass(p)
		for i,v in pairs(p:GetChildren())do
			if v:IsA("BasePart") then
				mass=mass+v:GetMass()
			end
			getMass(v)
		end	
	end
	getMass(car)
	
	--Apply Vehicle Weight
	if mass<_Tune.Weight*weightScaling then
		--Calculate Weight Distribution
		local centerF = Vector3.new()
		local centerR = Vector3.new()
		local countF = 0
		local countR = 0
		
		for i,v in pairs(Drive) do
			if v.Name=="FL" or v.Name=="FR" or v.Name=="F" then
				centerF = centerF+v.CFrame.p
				countF = countF+1
			else
				centerR = centerR+v.CFrame.p
				countR = countR+1
			end
		end
		centerF = centerF/countF
		centerR = centerR/countR
		local center = centerR:Lerp(centerF, _Tune.WeightDist/100)  
		
		--Create Weight Brick
		local weightB = Instance.new("Part",car.Body)
		weightB.Name = "#Weight"
		weightB.Anchored = true
		weightB.CanCollide = false
		weightB.BrickColor = BrickColor.new("Really black")
		weightB.TopSurface = Enum.SurfaceType.Smooth
		weightB.BottomSurface = Enum.SurfaceType.Smooth
		if _Tune.WBVisible then
			weightB.Transparency = .75			
		else
			weightB.Transparency = 1			
		end
		weightB.Size = Vector3.new(_Tune.WeightBSize[1],_Tune.WeightBSize[2],_Tune.WeightBSize[3])
		weightB.CustomPhysicalProperties = PhysicalProperties.new(((_Tune.Weight*weightScaling)-mass)/(weightB.Size.x*weightB.Size.y*weightB.Size.z),0,0,0,0)
		weightB.CFrame=(car.DriveSeat.CFrame-car.DriveSeat.Position+center)*CFrame.new(0,_Tune.CGHeight,0)
	else
		--Existing Weight Is Too Massive
		warn( "\n\t [AC".._BuildVersion.."]: Mass too high for specified weight."
			.."\n\t    Target Mass:\t"..(math.ceil(_Tune.Weight*weightScaling*100)/100)
			.."\n\t    Current Mass:\t"..(math.ceil(mass*100)/100)
			.."\n\t Reduce part size or axle density to achieve desired weight.")
	end
	
	local flipG = Instance.new("BodyGyro",car.DriveSeat)
	flipG.Name = "Flip"
	flipG.D = 0
	flipG.MaxTorque = Vector3.new(0,0,0)
	flipG.P = 0


	
--[[Finalize Chassis]]	
	--Misc Weld
	wait()
	for i,v in pairs(script:GetChildren()) do
		if v:IsA("ModuleScript") then
			require(v)
		end
	end
	
	--Weld Body
	wait()
	ModelWeld(car.Body,car.DriveSeat)
	
	--Unanchor
	wait()	
	UnAnchor(car)

--[[Manage Plugins]]
	
	script.Parent["A-Chassis Interface"].Car.Value=car
	for i,v in pairs(script.Parent.Plugins:GetChildren()) do
		for _,a in pairs(v:GetChildren()) do
			if a:IsA("RemoteEvent") or a:IsA("RemoteFunction") then 
				a.Parent=car
				for _,b in pairs(a:GetChildren()) do
					if b:IsA("Script") then b.Disabled=false end
				end	
			end
		end
		v.Parent = script.Parent["A-Chassis Interface"]
	end
	script.Parent.Plugins:Destroy()



--[[Remove Character Weight]]
	--Get Seats
	local Seats = {}
	function getSeats(p)
		for i,v in pairs(p:GetChildren()) do
			if v:IsA("VehicleSeat") or v:IsA("Seat") then
				local seat = {}
				seat.Seat = v
				seat.Parts = {}
				table.insert(Seats,seat)
			end
			getSeats(v)
		end	
	end
	getSeats(car)
	
	--Store Physical Properties/Remove Mass Function
	function getPProperties(mod,t)
		for i,v in pairs(mod:GetChildren()) do
			if v:IsA("BasePart") then
				if v.CustomPhysicalProperties == nil then v.CustomPhysicalProperties = PhysicalProperties.new(v.Material) end
				table.insert(t,{v,v.CustomPhysicalProperties})
				v.CustomPhysicalProperties = PhysicalProperties.new(
					0,
					v.CustomPhysicalProperties.Friction,
					v.CustomPhysicalProperties.Elasticity,
					v.CustomPhysicalProperties.FrictionWeight,
					v.CustomPhysicalProperties.ElasticityWeight
				)
			end
			getPProperties(v,t)
		end			
	end
	
	--Apply Seat Handler
	for i,v in pairs(Seats) do
		--Sit Handler
		v.Seat.ChildAdded:connect(function(child)
			if child.Name=="SeatWeld" and child:IsA("Weld") and child.Part1~=nil and child.Part1.Parent ~= workspace and not child.Part1.Parent:IsDescendantOf(car) then
				v.Parts = {}
				getPProperties(child.Part1.Parent,v.Parts)
			end
		end)
		
		--Leave Handler
		v.Seat.ChildRemoved:connect(function(child)
			if child.Name=="SeatWeld" and child:IsA("Weld") then
				for i,v in pairs(v.Parts) do
					if v[1]~=nil and v[2]~=nil and v[1]:IsDescendantOf(workspace) then
						v[1].CustomPhysicalProperties = v[2]
					end
				end
				v.Parts = {}
			end
		end)
	end



--[[Driver Handling]]

	--Driver Sit	
	car.DriveSeat.ChildAdded:connect(function(child)
		if child.Name=="SeatWeld" and child:IsA("Weld") and game.Players:GetPlayerFromCharacter(child.Part1.Parent)~=nil then
			--Distribute Client Interface
			local p=game.Players:GetPlayerFromCharacter(child.Part1.Parent)
			car.DriveSeat:SetNetworkOwner(p)
			local g=script.Parent["A-Chassis Interface"]:Clone()
			g.Parent=p.PlayerGui
		end
	end)
	
	--Driver Leave
	car.DriveSeat.ChildRemoved:connect(function(child)
		if child.Name=="SeatWeld" and child:IsA("Weld") then
			--Remove Flip Force
			if car.DriveSeat:FindFirstChild("Flip")~=nil then
				car.DriveSeat.Flip.MaxTorque = Vector3.new()
			end
			
			--Remove Wheel Force
			for i,v in pairs(car.Wheels:GetChildren()) do
				if v:FindFirstChild("#AV")~=nil then
					if v["#AV"]:IsA("BodyAngularVelocity") then
						if v["#AV"].AngularVelocity.Magnitude>0 then
							v["#AV"].AngularVelocity = Vector3.new()
							v["#AV"].MaxTorque = Vector3.new()
						end
					else
						if v["#AV"].AngularVelocity>0 then
							v["#AV"].AngularVelocity = 0
							v["#AV"].MotorMaxTorque = 0
						end
					end
				end
			end
		end
	end)
	
--[END]]