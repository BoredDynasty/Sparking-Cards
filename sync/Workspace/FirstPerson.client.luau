---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 
								-- StarterGui -- 					
--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--
--	Place this into StarterGui or StarterPack							--
--	CREDIT																--
--	EvelienSterk; for the initial script								--
--	SawyerDGamer; some stuff ripped from his panner script					--
--  iytgggggg; shoving it all into this script and then some :)			--
--	UPDATE: turned it into r15, made it so you can swim right in water	--
--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--


---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 


repeat wait() until game:GetService("Players").LocalPlayer.Character ~= nil
local runService = game:GetService("RunService")
local input = game:GetService("UserInputService")
local players = game:GetService("Players")

CanToggleMouse = {allowed = true; activationkey = Enum.KeyCode.F;} -- lets you move your mouse around in firstperson
CanViewBody = true 		-- whether you see your body
Sensitivity = 0.2		-- anything higher would make looking up and down harder; recommend anything between 0~1
Smoothness = 0.05		-- recommend anything between 0~1
FieldOfView = 90		-- fov

local cam = game.Workspace.CurrentCamera
local player = players.LocalPlayer
local m = player:GetMouse()
m.Icon = "http://www.roblox.com/asset/?id=569021388" -- replaces mouse icon
local character = player.Character or player.CharacterAdded:wait()
local humanoidpart = character.HumanoidRootPart

local head = character:WaitForChild("Head")
local CamPos,TargetCamPos = cam.CoordinateFrame.p,cam.CoordinateFrame.p 
local AngleX,TargetAngleX = 0,0
local AngleY,TargetAngleY = 0,0

local running = true
local freemouse = false

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

function updatechar()
	
	for _, v in pairs(character:GetChildren())do
		if CanViewBody then
			if v.Name == 'Head' then
				v.LocalTransparencyModifier = 1
				v.CanCollide = false
			end
		else
			if v:IsA'Part' or v:IsA'UnionOperation' or v:IsA'MeshPart' then
				v.LocalTransparencyModifier = 1
				v.CanCollide = false
			end
		end
		if v:IsA'Accessory' then
			v:FindFirstChild('Handle').LocalTransparencyModifier = 1
			v:FindFirstChild('Handle').CanCollide = false
		end
		if v:IsA'Hat' then
			v:FindFirstChild('Handle').LocalTransparencyModifier = 1
			v:FindFirstChild('Handle').CanCollide = false
		end

	end
	
end

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

input.InputChanged:connect(function(inputObject)
	
	if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = Vector2.new(inputObject.Delta.x/Sensitivity,inputObject.Delta.y/Sensitivity) * Smoothness

		local X = TargetAngleX - delta.y 
		TargetAngleX = (X >= 80 and 80) or (X <= -80 and -80) or X 
		TargetAngleY = (TargetAngleY - delta.x) %360 
	end	
	
end)

input.InputBegan:connect(function(inputObject)
	
	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		if inputObject.KeyCode == CanToggleMouse.activationkey then
			if CanToggleMouse.allowed and freemouse == false then
				freemouse = true
			else
				freemouse = false
			end
		end
	end
	
end)

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

runService.RenderStepped:connect(function()
	 
	if running then
		updatechar()
		
		CamPos = CamPos + (TargetCamPos - CamPos) *0.28 
		AngleX = AngleX + (TargetAngleX - AngleX) *0.35 
		local dist = TargetAngleY - AngleY 
		dist = math.abs(dist) > 180 and dist - (dist / math.abs(dist)) * 360 or dist 
		AngleY = (AngleY + dist *0.35) %360
		cam.CameraType = Enum.CameraType.Scriptable
		
		cam.CoordinateFrame = CFrame.new(head.Position) 
		* CFrame.Angles(0,math.rad(AngleY),0) 
		* CFrame.Angles(math.rad(AngleX),0,0)
		* CFrame.new(0,0.8,0) -- offset
		
		humanoidpart.CFrame=CFrame.new(humanoidpart.Position)*CFrame.Angles(0,math.rad(AngleY),0)
		character.Humanoid.AutoRotate = false
		else game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default; character.Humanoid.AutoRotate = true
	end

	if (cam.Focus.p-cam.CoordinateFrame.p).magnitude < 1 then
		running = false
	else
		running = true
		if freemouse == true then
			game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
		else
			game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end
	
	if not CanToggleMouse.allowed then
		freemouse = false
	end
	
	cam.FieldOfView = FieldOfView

end)

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 