
--[[
   ______                     __          _      _____                 _         
  / ____/________  __________/ /_  ____ _(_)____/ ___/___  ______   __(_)_______ 
 / /   / ___/ __ \/ ___/ ___/ __ \/ __ `/ / ___/\__ \/ _ \/ ___/ | / / / ___/ _ \
/ /___/ /  / /_/ (__  |__  ) / / / /_/ / / /   ___/ /  __/ /   | |/ / / /__/  __/
\____/_/   \____/____/____/_/ /_/\__,_/_/_/   /____/\___/_/    |___/_/\___/\___/ 
                                                                                 
----- Date Created: 9/19/2022
---- Description: A Module To Make Dynamic Crosshair's Easily
--- Devforum Post:

--- API ---
CrosshairService.new(MainFrame : Frame, Radius : number, EasingStyle : Enum.EasingStyle, EasingDirection : Enum.EasingDirection, Lerp : number) -- This function is for creating a new crosshair object

CrosshairService:Set(Radius : number, Can_Animate : boolean, EasingStyle : Enum.EasingStyle, EasingDirection : Enum.EasingDirection, Lerp : number) -- This function is for setting the radius of the crosshair
CrosshairService:Shove(Radius : number, EasingStyle : Enum.EasingStyle, EasingDirection : Enum.EasingDirection, Lerp : number) -- this function is for shoving the crosshair to a specific radius

CrosshairService:Freeze() -- This function is for freezing the crosshair's position
CrosshairService:UnFreeze() -- This function is for unfreezing the crosshair's position

CrosshairService:Enable() -- This function is for enabling the crosshair object
CrosshairService:Disable() -- This function is for disabling the crosshair object
CrosshairService:Destroy() -- This function is for destroying the crosshair object

--]]

local CrosshairService = {}
CrosshairService.__index = CrosshairService

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

---------- Local Functions ----------
local function Update(Crosshair, DeltaTime : number)
	if Crosshair.Frozen then return end
	local Mouse_Location = UserInputService:GetMouseLocation()
	Crosshair.MainFrame.Position = UDim2.new(0,Mouse_Location.X,0,Mouse_Location.Y)
end

local function PosTable_Func(Radius : number)
	return {
		Top = UDim2.new(0, 0, 0, -Radius - 7),
		Left = UDim2.new(0, -Radius - 7, 0, 0),
		Right = UDim2.new(0, Radius, 0, 0),
		Bottom = UDim2.new(0, 0, 0, Radius)
	}
end

---------- Objected Oriented Functions ----------
function CrosshairService.new(MainFrame : Frame, Radius : number, EasingStyle : Enum.EasingStyle, EasingDirection : Enum.EasingDirection, Lerp : number)
	local NewCrosshair = {}
	setmetatable(NewCrosshair, CrosshairService)
	
	NewCrosshair.MainFrame = MainFrame
	NewCrosshair.Enabled = nil
	NewCrosshair.EasingStyle = EasingStyle or Enum.EasingStyle.Quint
	NewCrosshair.EasingDirection = EasingDirection or Enum.EasingDirection.Out
	NewCrosshair.Lerp = Lerp or 1
	NewCrosshair.Radius = Radius or 50
	NewCrosshair.Frozen = false
	
	NewCrosshair:Disable()
	NewCrosshair:Set(NewCrosshair.Radius)
	
	return NewCrosshair
end

function CrosshairService:Set(Radius : number, Can_Animate : boolean, EasingStyle : Enum.EasingStyle, EasingDirection : Enum.EasingDirection, Lerp : number)
	if typeof(Radius) ~= "number" then warn("Argument #1 is not a valid radius") return end
	if typeof(Can_Animate) ~= "boolean" then Can_Animate = false end
	self.Radius = Radius
	
	local PosTable = PosTable_Func(self.Radius)
	for i,Position in pairs(PosTable) do
		if Can_Animate then
			local Tween = TweenService:Create(self.MainFrame[i], TweenInfo.new(Lerp or self.Lerp, EasingStyle or self.EasingStyle, EasingDirection or self.EasingDirection), {Position = Position})
			Tween:Play()
		else
			self.MainFrame[i].Position = Position
		end
	end
end

function CrosshairService:Shove(Radius : number, EasingStyle : Enum.EasingStyle, EasingDirection : Enum.EasingDirection, Lerp : number)
	if typeof(Radius) ~= "number" then warn("Argument #1 is not a valid radius") return end
	self.MainFrame.Top.Position = UDim2.new(0, 0, 0, -self.Radius - 7 - Radius)
	self.MainFrame.Left.Position = UDim2.new(0, -self.Radius - 7 - Radius, 0, 0)
	self.MainFrame.Right.Position = UDim2.new(0, self.Radius + Radius, 0, 0)
	self.MainFrame.Bottom.Position = UDim2.new(0, 0, 0, self.Radius + Radius)
	
	local PosTable = PosTable_Func(self.Radius)
	for i,Position in pairs(PosTable) do
		local Tween = TweenService:Create(self.MainFrame[i], TweenInfo.new(Lerp or self.Lerp, EasingStyle or self.EasingStyle, EasingDirection or self.EasingDirection), {Position = Position})
		Tween:Play()
	end
end

function CrosshairService:Freeze()
	if self.Frozen == true then warn("Attempt to freeze already frozen crosshair") return end
	self.Frozen = true
end

function CrosshairService:UnFreeze()
	if self.Frozen == false then warn("Attempt to unfreeze already unfrozen crosshair") return end
	self.Frozen = false
end

function CrosshairService:Enable()	
	if self.Enabled == true then warn("Attempt to enable already enabled crosshair") return end
	self.Enabled = true
	self.MainFrame.Visible = true
	UserInputService.MouseIconEnabled = false
	
	RunService:BindToRenderStep("CrosshairService_Update", Enum.RenderPriority.Camera.Value, function(DeltaTime : number)
		Update(self, DeltaTime)
	end)
end

function CrosshairService:Disable()
	if self.Enabled == false then warn("Attempt to disable already disabled crosshair") return end
	self.Enabled = false
	self.MainFrame.Visible = false
	UserInputService.MouseIconEnabled = true
	
	RunService:UnbindFromRenderStep("CrosshairService_Update")
end

function CrosshairService:Destroy()
	RunService:UnbindFromRenderStep("CrosshairService_Update")
	self.MainFrame:Destroy()
	table.clear(self)
	UserInputService.MouseIconEnabled = true
end

return CrosshairService
