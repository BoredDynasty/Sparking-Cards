--[[
		___      _______                _     
	   / _ |____/ ___/ /  ___ ____ ___ (_)__ 
	  / __ /___/ /__/ _ \/ _ `(_-<(_-</ (_-<
	 /_/ |_|   \___/_//_/\_,_/___/___/_/___/
 						SecondLogic @ Inspare
]]

local Tune = {}

--[[Misc]]
	Tune.LoadDelay		= .1		-- Delay before initializing chassis (in seconds)
	Tune.AutoStart		= false		-- Set to false if using manual ignition plugin
	Tune.AutoFlip		= true		-- Set to false if using manual flip plugin
	
--[[Wheel Alignment]]
	--[Don't physically apply alignment to wheels]
	--[Values are in degrees]
	Tune.FCamber		= 0
	Tune.RCamber		= 0
	Tune.FToe			= 0
	Tune.RToe			= 0
	
--[[Weight and CG]]
	Tune.Weight			= 3000		-- Total weight (in pounds)
	Tune.WeightBSize	= {			-- Size of weight brick (dimmensions in studs ; larger = more stable)
	 --[[Width]]		6		,
	 --[[Height]]		3.5		,
	 --[[Length]]		14		}
	Tune.WeightDist		= 50		-- Weight distribution (0 - on rear wheels, 100 - on front wheels, can be <0 or >100)
	Tune.CGHeight		= .8		-- Center of gravity height (studs relative to median of all wheels)
	Tune.WBVisible		= false		-- Makes the weight brick visible
	
	--Unsprung Weight
	Tune.FWheelDensity	= .1		-- Front Wheel Density
	Tune.RWheelDensity	= .1		-- Rear Wheel Density
	Tune.FWLgcyDensity	= 1			-- Front Wheel Density [PGS OFF]
	Tune.RWLgcyDensity	= 1			-- Rear Wheel Density [PGS OFF]
	
	Tune.AxleSize		= 2			-- Size of structural members (larger = more stable/carry more weight)
	Tune.AxleDensity	= .1		-- Density of structural members
	
--[[Susupension]]
	Tune.SusEnabled		= true		-- works only in with PGSPhysicsSolverEnabled, defaults to false when PGS is disabled
	
	--Front Suspension
	Tune.FSusDamping	= 500		-- Spring Dampening
	Tune.FSusStiffness	= 9000		-- Spring Force
	Tune.FAntiRoll 		= 50		-- Anti-Roll (Gyro Dampening)
	
	Tune.FSusLength		= 2			-- Suspension length (in studs)
	Tune.FPreCompress	= .3		-- Pre-compression adds resting length force
	Tune.FExtensionLim	= .3		-- Max Extension Travel (in studs)
	Tune.FCompressLim	= .1		-- Max Compression Travel (in studs)
	Tune.FSusAngle		= 80		-- Suspension Angle (degrees from horizontal)
		
	Tune.FWsBoneLen		= 5			-- Wishbone Length
	Tune.FWsBoneAngle	= 0			-- Wishbone angle (degrees from horizontal)
	Tune.FAnchorOffset	= {			-- Suspension anchor point offset (relative to center of wheel)
	 --[[Lateral]]		-.4		,	-- positive = outward
	 --[[Vertical]]		-.5		,	-- positive = upward
	 --[[Forward]]		0		}	-- positive = forward
	
	--Rear Suspension
	Tune.RSusDamping	= 500		-- Spring Dampening
	Tune.RSusStiffness	= 9000		-- Spring Force
	Tune.FAntiRoll 		= 50		-- Anti-Roll (Gyro Dampening)

	Tune.RSusLength		= 2			-- Suspension length (in studs)
	Tune.RPreCompress	= .3		-- Pre-compression adds resting length force
	Tune.RExtensionLim	= .3		-- Max Extension Travel (in studs)
	Tune.RCompressLim	= .1		-- Max Compression Travel (in studs)
	Tune.RSusAngle		= 80		-- Suspension Angle (degrees from horizontal)
		
	Tune.RWsBoneLen		= 5			-- Wishbone Length
	Tune.RWsBoneAngle	= 0			-- Wishbone angle (degrees from horizontal)
	Tune.RAnchorOffset	= {			-- Suspension anchor point offset (relative to center of wheel)
	 --[[Lateral]]		-.4		,	-- positive = outward
	 --[[Vertical]]		-.5		,	-- positive = upward
	 --[[Forward]]		0		}	-- positive = forward

	--Aesthetics	
	Tune.SusVisible		= false			-- Spring Visible
	Tune.WsBVisible		= true			-- Wishbone Visible
	Tune.SusRadius		= .2			-- Suspension Coil Radius
	Tune.SusThickness	= .1			-- Suspension Coil Thickness
	Tune.SusColor		= "Bright red"	-- Suspension Color [BrickColor]
	Tune.SusCoilCount	= 6				-- Suspension Coil Count
	Tune.WsColor		= "Black"		-- Wishbone Color [BrickColor]
	Tune.WsThickness	= .1			-- Wishbone Rod Thickness
	
--[[Wheel Stabilizer Gyro]]
	Tune.FGyroDamp		= 100		-- Front Wheel Non-Axial Dampening
	Tune.RGyroDamp		= 100		-- Rear Wheel Non-Axial Dampening
	
--[[Steering]]
	Tune.SteerInner		= 48		-- Inner wheel steering angle (in degrees)
	Tune.SteerOuter		= 49		-- Outer wheel steering angle (in degrees)
	Tune.SteerSpeed		= .02		-- Steering increment per tick (in degrees)
	Tune.ReturnSpeed	= .04		-- Steering increment per tick (in degrees)
	Tune.SteerDecay		= 320		-- Speed of gradient cutoff (in SPS)
	Tune.MinSteer		= 10		-- Minimum steering at max steer decay (in percent)
	Tune.MSteerExp		= 1			-- Mouse steering exponential degree
	
	--Steer Gyro Tuning
	Tune.SteerD			= 1000		-- Steering Dampening
	Tune.SteerMaxTorque	= 50000		-- Steering Force
	Tune.SteerP			= 100000	-- Steering Aggressiveness
	
--[[Engine]]
	--Torque Curve
	Tune.Horsepower		= 145		--	[TORQUE CURVE VISUAL]
	Tune.IdleRPM		= 500		--		https://www.desmos.com/calculator/2uo3hqwdhf
	Tune.PeakRPM		= 4300		--		Use sliders to manipulate values
	Tune.Redline		= 4500		--		Copy and paste slider values into the respective tune values
	Tune.EqPoint		= 4500
	Tune.PeakSharpness	= 7.5
	Tune.CurveMult		= 0.16
	
	--Incline Compensation
	Tune.InclineComp	= 1.6			-- Torque compensation multiplier for inclines (applies gradient from 0-90 degrees)
	
	--Misc
	Tune.RevAccel		= 80		-- RPM acceleration when clutch is off
	Tune.RevDecay		= 70		-- RPM decay when clutch is off
	Tune.RevBounce		= 10		-- RPM kickback from redline
	Tune.IdleThrottle	= 1			-- Percent throttle at idle
	Tune.ClutchTol		= 500		-- Clutch engagement threshold (higher = faster response)
	
--[[Drivetrain]]	
	Tune.Config			= "RWD"		--"FWD" , "RWD" , "AWD"
	
	--Differential Settings	
	Tune.FDiffSlipThres	= 50		-- 1 - 100%				(Max threshold of applying full lock determined by deviation from avg speed)
	Tune.FDiffLockThres	= 50		-- 0 - 100%				(0 - Bias toward slower wheel, 100 - Bias toward faster wheel)
	Tune.RDiffSlipThres	= 50		-- 1 - 100%
	Tune.RDiffLockThres	= 50		-- 0 - 100%
	Tune.CDiffSlipThres	= 50		-- 1 - 100%				[AWD Only]
	Tune.CDiffLockThres	= 50		-- 0 - 100%				[AWD Only]
	
	--Traction Control Settings
	Tune.TCSEnabled		= true		-- Implements TCS
	Tune.TCSThreshold	= 20		-- Slip speed allowed before TCS starts working (in SPS)
	Tune.TCSGradient	= 20		-- Slip speed gradient between 0 to max reduction (in SPS)
	Tune.TCSLimit		= 10		-- Minimum amount of torque at max reduction (in percent)
	
--[[Transmission]]
	Tune.TransModes		= {"Auto","Semi"}								--[[
	[Modes]
		"Auto"		: Automatic shifting
		"Semi"		: Clutchless manual shifting, dual clutch transmission
		"Manual"	: Manual shifting with clutch
		
		>Include within brackets
			eg: {"Semi"} or {"Auto", "Manual"}								
		>First mode is default mode													]]
	
	--Automatic Settings
	Tune.AutoShiftMode	= "RPM"												--[[
	[Modes]
		"Speed"		: Shifts based on wheel speed
		"RPM"		: Shifts based on RPM											]]	
	Tune.AutoUpThresh	= -200		--Automatic upshift point 	(relative to peak RPM, positive = Over-rev)
	Tune.AutoDownThresh = 1400		--Automatic downshift point (relative to peak RPM, positive = Under-rev)
	
	--Gear Ratios
	Tune.FinalDrive		= 13.5			-- Gearing determines top speed and wheel torque
	Tune.Ratios			= {				-- Higher ratio = more torque, Lower ratio = higher top speed
		--[[Reverse]]	1.5		,	-- Copy and paste a ratio to add a gear
		--[[Neutral]]	0			,	-- Ratios can also be deleted
		--[[ 1 ]]		1.89		,	-- Reverse, Neutral, and 1st gear are required
		--[[ 2 ]]		0.76		,
		--[[ 3 ]]		0.49        ,
		--[[ 4 ]]       0.33        ,
		--[[ 5 ]]       0.26
	}
	Tune.FDMult			= 1.5			-- Ratio multiplier (Change this value instead of FinalDrive if car is struggling with torque ; Default = 1)
	
--[[Brakes]]
	Tune.ABSEnabled		= true		-- Implements ABS
	Tune.ABSThreshold	= 20		-- Slip speed allowed before ABS starts working (in SPS) 

	Tune.FBrakeForce	= 1000		-- Front brake force
	Tune.RBrakeForce	= 500		-- Rear brake force
	Tune.PBrakeForce	= 5000		-- Handbrake force
	
	Tune.FLgcyBForce	= 15000		-- Front brake force [PGS OFF]
	Tune.RLgcyBForce	= 10000		-- Rear brake force [PGS OFF]
	Tune.LgcyPBForce	= 25000		-- Handbrake force [PGS OFF]
	
--[[[Default Controls]]
	--Peripheral Deadzones
	Tune.Peripherals = {
		MSteerWidth				= 67		,	-- Mouse steering control width	(0 - 100% of screen width)
		MSteerDZone				= 10		,	-- Mouse steering deadzone (0 - 100%)
		
		ControlLDZone			= 5			,	-- Controller steering L-deadzone (0 - 100%)
		ControlRDZone			= 5			,	-- Controller steering R-deadzone (0 - 100%)
	}
	
	--Control Mapping
	Tune.Controls = {
		
	--Keyboard Controls
		--Mode Toggles
		ToggleTCS				= Enum.KeyCode.T					,
		ToggleABS				= Enum.KeyCode.Y					,
		ToggleTransMode			= Enum.KeyCode.M					,
		ToggleMouseDrive		= Enum.KeyCode.R					,
		
		--Primary Controls
		Throttle				= Enum.KeyCode.Up					,
		Brake					= Enum.KeyCode.Down					,
		SteerLeft				= Enum.KeyCode.Left					,
		SteerRight				= Enum.KeyCode.Right				,
		
		--Secondary Controls
		Throttle2				= Enum.KeyCode.W					,
		Brake2					= Enum.KeyCode.S					,
		SteerLeft2				= Enum.KeyCode.A					,
		SteerRight2				= Enum.KeyCode.D					,
		
		--Manual Transmission
		ShiftUp					= Enum.KeyCode.E					,
		ShiftDown				= Enum.KeyCode.Q					,
		Clutch					= Enum.KeyCode.LeftShift			,
		
		--Handbrake
		PBrake					= Enum.KeyCode.P					,
		
	--Mouse Controls
		MouseThrottle			= Enum.UserInputType.MouseButton1	,
		MouseBrake				= Enum.UserInputType.MouseButton2	,
		MouseClutch				= Enum.KeyCode.W					,
		MouseShiftUp			= Enum.KeyCode.E					,
		MouseShiftDown			= Enum.KeyCode.Q					,
		MousePBrake				= Enum.KeyCode.LeftShift			,
		
	--Controller Mapping
		ContlrThrottle			= Enum.KeyCode.ButtonR2				,
		ContlrBrake				= Enum.KeyCode.ButtonL2				,
		ContlrSteer				= Enum.KeyCode.Thumbstick1			,
		ContlrShiftUp			= Enum.KeyCode.ButtonY				,
		ContlrShiftDown			= Enum.KeyCode.ButtonX				,
		ContlrClutch			= Enum.KeyCode.ButtonR1				,
		ContlrPBrake			= Enum.KeyCode.ButtonL1				,
		ContlrToggleTMode		= Enum.KeyCode.DPadUp				,
		ContlrToggleTCS			= Enum.KeyCode.DPadDown				,
		ContlrToggleABS			= Enum.KeyCode.DPadRight			,
	}
	
--[[Weight Scaling]]
	--[Cubic stud : pounds ratio]
	--[STANDARDIZED: Don't touch unless needed]
	Tune.WeightScaling = 1/50	--Default = 1/50 (1 cubic stud = 50 lbs)
	Tune.LegacyScaling = 1/10	--Default = 1/10 (1 cubic stud = 10 lbs) [PGS OFF]
	
return Tune
