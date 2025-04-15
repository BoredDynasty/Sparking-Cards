--!nonstrict

local CLASS = {}

--// SERVICES //--

local PLAYERS_SERVICE = game:GetService("Players")
local RUN_SERVICE = game:GetService("RunService")
local USER_INPUT_SERVICE = game:GetService("UserInputService")

--// CONSTANTS //--

local LOCAL_PLAYER = PLAYERS_SERVICE.LocalPlayer
-- selene: allow(unused_variable)
-- local MOUSE = LOCAL_PLAYER:GetMouse()

local UPDATE_UNIQUE_KEY = "OTS_CAMERA_SYSTEM_UPDATE"

--// VARIABLES //--

--// CONSTRUCTOR //--

function CLASS.new()
	--// Events //--
	local activeCameraSettingsChangedEvent = Instance.new("BindableEvent")
	local characterAlignmentChangedEvent = Instance.new("BindableEvent")
	local mouseStepChangedEvent = Instance.new("BindableEvent")
	local shoulderDirectionChangedEvent = Instance.new("BindableEvent")
	local enabledEvent = Instance.new("BindableEvent")
	local disabledEvent = Instance.new("BindableEvent")
	----

	local dataTable = setmetatable({

		--// Properties //--
		SavedCameraSettings = nil,
		SavedMouseBehavior = nil,
		ActiveCameraSettings = nil,
		HorizontalAngle = 0,
		VerticalAngle = 0,
		ShoulderDirection = 1,
		----

		--// Flags //--
		IsCharacterAligned = false,
		IsMouseSteppedIn = false,
		IsEnabled = false,
		----

		--// Events //--
		ActiveCameraSettingsChangedEvent = activeCameraSettingsChangedEvent,
		ActiveCameraSettingsChanged = activeCameraSettingsChangedEvent.Event,
		CharacterAlignmentChangedEvent = characterAlignmentChangedEvent,
		CharacterAlignmentChanged = characterAlignmentChangedEvent.Event,
		MouseStepChangedEvent = mouseStepChangedEvent,
		MouseStepChanged = mouseStepChangedEvent.Event,
		ShoulderDirectionChangedEvent = shoulderDirectionChangedEvent,
		ShoulderDirectionChanged = shoulderDirectionChangedEvent.Event,
		EnabledEvent = enabledEvent,
		Enabled = enabledEvent.Event,
		DisabledEvent = disabledEvent,
		Disabled = disabledEvent.Event,
		----

		--// Configurations //--
		VerticalAngleLimits = NumberRange.new(-45, 45),
		----

		--// Camera Settings //--
		CameraSettings = {

			DefaultShoulder = {
				FieldOfView = 70,
				Offset = Vector3.new(2.5, 2.5, 8),
				Sensitivity = 3,
				LerpSpeed = 0.5,
			},

			ZoomedShoulder = {
				FieldOfView = 40,
				Offset = Vector3.new(1.5, 1.5, 6),
				Sensitivity = 1.5,
				LerpSpeed = 0.5,
			},
		},
		----
	}, CLASS)
	-- selene: allow(unused_variable)
	local proxyTable = setmetatable({}, {
		__index = function(self, index)
			return dataTable[index]
		end,
		__newindex = function(self, index, newValue)
			dataTable[index] = newValue
		end,
	})

	return proxyTable
end

--// FUNCTIONS //--

local function Lerp(x: number, y: number, a: number)
	return x + (y - x) * a
end

--// METHODS //--

--// //--
function CLASS:SetActiveCameraSettings(cameraSettings: {
	DefaultShoulder: {
		FieldOfVie: number,
		Offset: Vector3,
		Sensitivi: number,
		LerpSpeed: number,
	},
	ZoomedShoulder: {
		FieldOfVie: number,
		Offset: Vector3,
		Sensitivity: number,
		LerpSpeed: number,
	},
})
	self.ActiveCameraSettings = cameraSettings
	self.ActiveCameraSettingsChangedEvent:Fire(cameraSettings)
end

function CLASS:SetCharacterAlignment(aligned: boolean)
	self.IsCharacterAligned = aligned
	self.CharacterAlignmentChangedEvent:Fire(aligned)
end

function CLASS:SetMouseStep(steppedIn: boolean)
	self.IsMouseSteppedIn = steppedIn
	self.MouseStepChangedEvent:Fire(steppedIn)
	if steppedIn == true then
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
	end
end

function CLASS:SetShoulderDirection(shoulderDirection: number)
	self.ShoulderDirection = shoulderDirection
	self.ShoulderDirectionChangedEvent:Fire(shoulderDirection)
end
----

--// //--
function CLASS:SaveCameraSettings()
	local currentCamera = workspace.CurrentCamera
	self.SavedCameraSettings = {
		FieldOfView = currentCamera.FieldOfView,
		CameraSubject = currentCamera.CameraSubject,
		CameraType = currentCamera.CameraType,
	}
end

function CLASS:LoadCameraSettings()
	local currentCamera = workspace.CurrentCamera
	type cameraSetting = "FieldOfView" | "CameraSubject" | "CameraType"
	task.spawn(function()
		for setting: cameraSetting, value: any in pairs(self.SavedCameraSettings) do
			if setting == "FieldOfView" or setting == "CameraSubject" or setting == "CameraType" then
				currentCamera[setting] = value
			end
		end
	end)
end
----

--// //--
function CLASS:Update()
	local currentCamera = workspace.CurrentCamera
	local activeCameraSettings = self.CameraSettings[self.ActiveCameraSettings]

	--// Address mouse behavior and camera type //--
	if self.IsMouseSteppedIn == true then
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		USER_INPUT_SERVICE.MouseBehavior = Enum.MouseBehavior.Default
	end
	currentCamera.CameraType = Enum.CameraType.Scriptable
	---

	--// Address mouse input //--
	local mouseDelta = USER_INPUT_SERVICE:GetMouseDelta() * activeCameraSettings.Sensitivity
	self.HorizontalAngle -= mouseDelta.X / currentCamera.ViewportSize.X
	self.VerticalAngle -= mouseDelta.Y / currentCamera.ViewportSize.Y
	self.VerticalAngle = math.rad(
		math.clamp(math.deg(self.VerticalAngle), self.VerticalAngleLimits.Min, self.VerticalAngleLimits.Max)
	)
	----

	local character = LOCAL_PLAYER.Character :: Model | Instance
	local humanoidRootPart = character and (character:FindFirstChild("HumanoidRootPart")) :: BasePart
	if humanoidRootPart then
		--// Lerp field of view //--
		currentCamera.FieldOfView =
			Lerp(currentCamera.FieldOfView, activeCameraSettings.FieldOfView, activeCameraSettings.LerpSpeed)
		----

		--// Address shoulder direction //--
		local offset = activeCameraSettings.Offset :: Vector3
		offset = Vector3.new(offset.X * self.ShoulderDirection, offset.Y, offset.Z)
		----

		--// Calculate new camera cframe //--
		local newCameraCFrame = CFrame.new(humanoidRootPart.Position)
			* CFrame.Angles(0, self.HorizontalAngle, 0)
			* CFrame.Angles(self.VerticalAngle, 0, 0)
			* CFrame.new(offset)

		newCameraCFrame = currentCamera.CFrame:Lerp(newCameraCFrame, activeCameraSettings.LerpSpeed)
		----

		--// Raycast for obstructions //--
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { character }
		-- selene: allow(deprecated)
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local raycastResult = workspace:Raycast(
			humanoidRootPart.Position,
			newCameraCFrame.Position - humanoidRootPart.Position,
			raycastParams
		)
		----

		--// Address obstructions if any //--
		if raycastResult ~= nil then
			local obstructionDisplacement = (raycastResult.Position - humanoidRootPart.Position)
			local obstructionPosition = humanoidRootPart.Position
				+ (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
			-- selene: allow(unused_variable)
			local _x, _y, _z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = newCameraCFrame:GetComponents()
			newCameraCFrame = CFrame.new(
				obstructionPosition.X,
				obstructionPosition.Y,
				obstructionPosition.Z,
				r00,
				r01,
				r02,
				r10,
				r11,
				r12,
				r20,
				r21,
				r22
			)
		end
		----

		--// Address character alignment //--
		if self.IsCharacterAligned == true then
			local newHumanoidRootPartCFrame = CFrame.new(humanoidRootPart.Position)
				* CFrame.Angles(0, self.HorizontalAngle, 0)
			humanoidRootPart.CFrame =
				humanoidRootPart.CFrame:Lerp(newHumanoidRootPartCFrame, activeCameraSettings.LerpSpeed / 2)
		end
		----

		currentCamera.CFrame = newCameraCFrame
	else
		self:Disable()
	end
end

function CLASS:ConfigureStateForEnabled()
	self:SaveCameraSettings()
	self.SavedMouseBehavior = USER_INPUT_SERVICE.MouseBehavior
	self:SetActiveCameraSettings("DefaultShoulder")
	self:SetCharacterAlignment(false)
	self:SetMouseStep(true)
	self:SetShoulderDirection(1)

	--// Calculate angles //--
	local cameraCFrame = workspace.CurrentCamera.CFrame
	-- selene: allow(unused_variable)
	local x, y = cameraCFrame:ToOrientation()
	local horizontalAngle = y
	local verticalAngle = x
	----

	self.HorizontalAngle = horizontalAngle
	self.VerticalAngle = verticalAngle
end

function CLASS:ConfigureStateForDisabled()
	self:LoadCameraSettings()
	USER_INPUT_SERVICE.MouseBehavior = self.SavedMouseBehavior
	self:SetActiveCameraSettings("DefaultShoulder")
	self:SetCharacterAlignment(false)
	self:SetMouseStep(false)
	self:SetShoulderDirection(1)
	self.HorizontalAngle = 0
	self.VerticalAngle = 0
end

function CLASS:Enable()
	self.IsEnabled = true
	self.EnabledEvent:Fire()
	self:ConfigureStateForEnabled()

	RUN_SERVICE:BindToRenderStep(UPDATE_UNIQUE_KEY, Enum.RenderPriority.Camera.Value - 10, function()
		if self.IsEnabled then
			self:Update()
		end
	end)
end

function CLASS:Disable()
	self:ConfigureStateForDisabled()
	self.IsEnabled = false
	self.DisabledEvent:Fire()

	RUN_SERVICE:UnbindFromRenderStep(UPDATE_UNIQUE_KEY)
end
----

--[[
CLASS.__index = CLASS

local singleton = CLASS.new()

USER_INPUT_SERVICE.InputBegan:Connect(function(inputObject, gameProcessedEvent)
	if (gameProcessedEvent == false) and (singleton.IsEnabled == true) then
		if inputObject.KeyCode == Enum.KeyCode.Q then
			singleton:SetShoulderDirection(-1)
		elseif inputObject.KeyCode == Enum.KeyCode.E then
			singleton:SetShoulderDirection(1)
		end
		if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
			singleton:SetActiveCameraSettings("ZoomedShoulder")
		end

		if inputObject.KeyCode == Enum.KeyCode.LeftControl then
			if singleton.IsEnabled == true then
				singleton:SetMouseStep(not singleton.IsMouseSteppedIn)
			end
		end
	end
end)

USER_INPUT_SERVICE.InputEnded:Connect(function(inputObject, gameProcessedEvent)
	if (gameProcessedEvent == false) and (singleton.IsEnabled == true) then
		if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
			singleton:SetActiveCameraSettings("DefaultShoulder")
		end
	end
end)
--]]

return CLASS
