--[[

DynamicCrosshair Module created by Towphy!

Need to reach out?
 - Discord: Towphy#6174
 - Roblox: https://www.roblox.com/users/335665660/profile
 - Twitter: https://twitter.com/towphyReal

-----------------------------------

FUNCTION LIST:

DynamicCrosshair.new()
DynamicCrosshair:Enable()
DynamicCrosshair:Disable()
DynamicCrosshair:Lock()
DynamicCrosshair:Size()
DynamicCrosshair:Destroy()
DynamicCrosshair:Display()
DynamicCrosshair:Set()
DynamicCrosshair:SmoothSet()
DynamicCrosshair:Shove()
DynamicCrosshair:FollowMouse()
DynamicCrosshair:HitMarker()
DynamicCrosshair:Update() (OUTDATED)

-----------------------------------

DOCS:

DevForum Post: https://devforum.roblox.com/t/create-dynamic-crosshairs-new-module/1925891 

-----------------------------------

FEATURE REQUEST:

- Hit Markers
- Pre-made Crosshairs into DynamicCrosshair


]]

local CrosshairModule 		= {}
local Crosshairs			= {}
CrosshairModule.__index 	= CrosshairModule

local GetService			= game.GetService

local TweenService			= GetService(game, "TweenService")
local RunService			= GetService(game, "RunService")
local UserInputService		= GetService(game, "UserInputService")
local GuiService 			= GetService(game, "GuiService")
local Players				= GetService(game, "Players")

local LocalPlayer			= Players.LocalPlayer
local Camera				= workspace.CurrentCamera

local Functions				= require(script:WaitForChild("Functions"))

function CrosshairModule.New(UI, MinSpread, MaxSpread, DecreasePerSecond, IncreasePerSecond, MouseFollow) 
	local self 				= {}

	self.UI 					= UI or Instance.new('ScreenGui', LocalPlayer.PlayerGui)

	self.SizeX 					= 5
	self.SizeY 					= 1

	self.Top, self.Bottom, self.Left, self.Right, self.HitMarker, self.CenterDot, self.ImageCrosshair = Functions:CreateHairs(UI, self.SizeX, self.SizeY)

	self.Spreading = {
		Spread 					= MinSpread or 20,
		MaxSpread 				= MaxSpread or 60,
		MinSpread 				= MinSpread or 20,
		DecreasePerSecond 		= DecreasePerSecond or 40,
		IncreasePerSecond 		= IncreasePerSecond or 30
	}

	self.FollowingMouse			= ((MouseFollow and type(MouseFollow) == "boolean") and MouseFollow) or false
	self.Locked 				= false


	self.Hairs 					= {
		self.Top,
		self.Bottom,
		self.Left,
		self.Right
	}

	self.EasingStyle 			= Enum.EasingStyle.Linear
	self.EasingDirection 		= Enum.EasingDirection.InOut

	self.HitMarker = {
		hitmarker = self.HitMarker;
		size = UDim2.fromOffset(50, 50);
		default = Color3.fromRGB(255, 255, 255);
		headshot = Color3.fromRGB(255, 0, 0);
		fadeTime = 0.25;
		easingStyle = Enum.EasingStyle.Linear;
		easingDirection = Enum.EasingDirection.InOut;
		Image = {
			default = 'rbxassetid://285779644';
			headshot = nil;
		};
	}

	self.CenterDot = {
		centerdot = self.CenterDot;
		size = UDim2.fromOffset(7.5,7.5);
		enabled = false;
		transparency = 0;
		Image = 'rbxassetid://11003529439';
	}

	self.ImageCrosshair = {
		crosshair = self.ImageCrosshair;
		enabled = false;
		Image = 'rbxassetid://12550071496';
	}

	table.insert(Crosshairs, self)

	Functions:UpdateEnabled(self.Hairs, false)

	return setmetatable(self, CrosshairModule)
end

function CrosshairModule:Enable()
	self.Enabled 						= true
	UserInputService.MouseIconEnabled 	= false

	Functions:UpdateEnabled(self.Hairs, self.Enabled)
end

function CrosshairModule:Disable()
	self.Enabled 						= false
	UserInputService.MouseIconEnabled 	= true

	Functions:UpdateEnabled(self.Hairs, self.Enabled)
end

function CrosshairModule:Lock(Bool : boolean)
	self.Locked 				= Bool or true
end

function CrosshairModule:FollowMouse(Bool : boolean)
	self.FollowingMouse 		= Bool or true
end

function CrosshairModule:Hitmarker(headshot : boolean, fadeTime, easingStyle, easingDirection)
	if headshot then
		self.HitMarker.hitmarker.ImageColor3 = self.HitMarker.headshot
	else
		self.HitMarker.hitmarker.ImageColor3 = self.HitMarker.default
	end


	self.HitMarker.hitmarker.Size = self.HitMarker.size 
	self.HitMarker.hitmarker.ImageTransparency = 0

	TweenService:Create(
		self.HitMarker.hitmarker, 
		TweenInfo.new(fadeTime or self.HitMarker.fadeTime, easingStyle or self.HitMarker.easingStyle, easingDirection or self.HitMarker.easingDirection),
		{ImageTransparency = 1}
	):Play()
end

function CrosshairModule:Size(X : number, Y : number)
	self.SizeX 					= X or self.SizeX
	self.SizeY 					= Y or self.SizeY

	X = self.SizeX; Y = self.SizeY;

	self.Top	.Size 			= UDim2.fromOffset(Y, X)
	self.Bottom	.Size 			= UDim2.fromOffset(Y, X)
	self.Left	.Size 			= UDim2.fromOffset(X, Y)
	self.Right	.Size 			= UDim2.fromOffset(X, Y)
end

function CrosshairModule:Destroy()
	for Index, Value in pairs(self.Hairs) do
		Value:Destroy()
	end
	self.CenterDot.centerdot:Destroy()
	self.ImageCrosshair.crosshair:Destroy()
	table.remove(Crosshairs, table.find(Crosshairs, self))
	table.clear(self)
end

function CrosshairModule:Display(SettingsTable)
	local function ApplyAll(Setting, Value)
		for i, Hair in pairs(self.Hairs) do
			Hair[Setting] = Value
		end
	end

	for Setting, Value in pairs(SettingsTable) do
		local Success = pcall(function() local Check = self.Top[Setting] end)

		if Success then
			ApplyAll(Setting, Value)
		end
	end
end

function CrosshairModule:Set(Radius)
	self.Spreading.Spread 		= tonumber(Radius)
end

function CrosshairModule:SmoothSet(Spread : number, Seconds : number, UpdateMin : boolean)
	local StartTick 	= tick()
	local StartSpread 	= self.Spreading.Spread

	while ( tick() - StartTick ) < Seconds do

		local Alpha 	= (tick() - StartTick) / Seconds

		Alpha = TweenService:GetValue(
			Alpha,
			self.EasingStyle or Enum.EasingStyle.Linear,
			self.EasingDirection or Enum.EasingDirection.InOut
		)

		self.Spreading.Spread = StartSpread + (Spread - StartSpread) * Alpha 

		RunService.Heartbeat:Wait()
	end

	if UpdateMin then self.Spreading.MinSpread = self.Spreading.Spread end

	self.Spreading.Spread = Spread
end

function CrosshairModule:Shove()
	self.Spreading.Spread += self.Spreading.IncreasePerSecond
end

function CrosshairModule:Update(DeltaTime)
	if not self.Enabled then return end
	if not self.Locked then
		self.Spreading.Spread -= self.Spreading.DecreasePerSecond * DeltaTime
	end

	self.Spreading.Spread = math.clamp(self.Spreading.Spread, self.Spreading.MinSpread, self.Spreading.MaxSpread)

	local originX, originY

	if self.FollowingMouse then
		local mousePos = UserInputService:GetMouseLocation()
		originX = mousePos.X
		originY = mousePos.Y

		if self.UI:IsA("ScreenGui") and not self.UI.IgnoreGuiInset then
			local guiInset = GuiService:GetGuiInset()
			originY -= guiInset.Y
		end
	else
		if self.UI:IsA("ScreenGui") then
			local camera = workspace.CurrentCamera
			local size = camera.ViewportSize

			originX = size.X / 2
			originY = size.Y / 2

			if not self.UI.IgnoreGuiInset then
				local guiInset = GuiService:GetGuiInset()
				originY -= guiInset.Y
			end
		else
			local absPos = self.UI.AbsolutePosition
			local absSize = self.UI.AbsoluteSize

			originX = absPos.X + absSize.X / 2
			originY = absPos.Y + absSize.Y / 2
		end
	end

	local offsetX = originX
	local offsetY = originY

	if not self.UI:IsA("ScreenGui") then
		local uiAbsPos = self.UI.AbsolutePosition
		offsetX -= uiAbsPos.X
		offsetY -= uiAbsPos.Y
	end

	local Origin = UDim2.fromOffset(offsetX, offsetY)
	local VerticalOffset = UDim2.fromOffset(0, self.Spreading.Spread)
	local HorizontalOffset = UDim2.fromOffset(self.Spreading.Spread, 0)

	self.Top.Position 		= Origin - VerticalOffset
	self.Bottom.Position 	= Origin + VerticalOffset
	self.Right.Position 	= Origin - HorizontalOffset
	self.Left.Position 		= Origin + HorizontalOffset
	self.HitMarker.hitmarker.Position = Origin

	if self.CenterDot.enabled then
		local cd = self.CenterDot.centerdot
		cd.Visible = true
		cd.Image = self.CenterDot.Image
		cd.Size = self.CenterDot.size
		cd.ImageTransparency = self.CenterDot.transparency
		cd.Position = Origin
	else
		self.CenterDot.centerdot.Visible = false
	end

	if self.ImageCrosshair.enabled then
		local ic = self.ImageCrosshair.crosshair
		ic.Visible = true
		ic.Image = self.ImageCrosshair.Image
		ic.Size = UDim2.fromOffset(
			(self.SizeX * 2) + self.Spreading.Spread,
			(self.SizeX * 2) + self.Spreading.Spread
		)
		ic.Position = Origin
		Functions:UpdateEnabled(self.Hairs, false)
	else
		self.ImageCrosshair.crosshair.Visible = false
		Functions:UpdateEnabled(self.Hairs, true)
	end
end

function CrosshairModule:Raycast()
	local X, Y = Functions:RandomPointsInsideCrosshair(self.Spreading.Spread - (self.SizeX * 4))
	local Camera = workspace.CurrentCamera
	local ViewportSize = Camera.ViewportSize
	local mousePos = UserInputService:GetMouseLocation()

	local screenX, screenY

	if self.FollowingMouse then
		screenX = mousePos.X
		screenY = mousePos.Y
	else
		screenX = ViewportSize.X / 2
		screenY = ViewportSize.Y / 2
	end

	local raycastX = screenX + X
	local raycastY = screenY + Y

	local unitRay = Camera:ViewportPointToRay(raycastX, raycastY)
	return unitRay.Origin, unitRay.Direction
end


RunService.RenderStepped:Connect(function(Delta)
	for i, v in pairs(Crosshairs) do
		v:Update(Delta)
	end
end)

return CrosshairModule