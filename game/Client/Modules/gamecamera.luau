--!strict

-- gamecamera.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Emphasis = require(ReplicatedStorage.Utility.Emphasis)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local random = require(ReplicatedStorage.Utility.random)

local GameCamera = {}
GameCamera.__index = GameCamera

local function lerp(a: number, b: number, t: number)
	return a + (b - a) * math.clamp(t, 0, 1)
end

local player = playerMarshaller.get()
local character = player.Character
local humanoid = character.Humanoid
local mouse = player:GetMouse()

local camera = workspace.CurrentCamera

local swayTurn = 0
local offset = Vector3.new(2, 2, 6) -- Right, Up, Back
local smoothness = 0.15
local connections = {} :: { [string]: RBXScriptConnection? }
local collisionPadding = 0.5
local priority = Enum.RenderPriority.Camera.Value
local previousMousePosition = CFrame.new()
local maxTilt = 8

function GameCamera:sway()
	RunService:BindToRenderStep("sway", priority + 1, function(delta: number)
		debug.profilebegin("sway")
		local mouseDelta: Vector2 = UserInputService:GetMouseDelta()
		swayTurn = lerp(swayTurn, math.clamp(mouseDelta.X, -6, 6), (10 * delta))
		camera.CFrame *= CFrame.Angles(0, 0, math.rad(swayTurn))
		debug.profileend()
	end)
end

function GameCamera:follow()
	local connection = nil
	if connections["follow"] then
		return
	end
	connection = RunService.RenderStepped:Connect(function()
		-- very sigma effect chat
		local currentMousePosition = mouse.Hit

		if previousMousePosition ~= currentMousePosition then
			local newPosition = CFrame.Angles(
				math.rad(((mouse.Y - mouse.ViewSizeY / 2) / mouse.ViewSizeY) * -maxTilt),
				math.rad(((mouse.X - mouse.ViewSizeX / 2) / mouse.ViewSizeX) * -maxTilt),
				0
			)
			camera.CFrame *= newPosition
		end
	end)
	if connection ~= nil then
		connections["follow"] = connection
	end
end

function GameCamera:trail()
	local offset = Vector3.new(0, 0, -10) -- Backwards
	local trailAlpha = 0.1
	local connection = nil
	local rootPart = humanoid.RootPart :: BasePart
	if connections["trail"] then
		return
	end
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		debug.profilebegin("trail")
		local velocity = rootPart.AssemblyLinearVelocity
		local speed = humanoid.WalkSpeed
		offset = Vector3.new(0, velocity.Y, -10)
		local newOffset = offset * velocity.Magnitude / (speed * 2)
		local cameraOffset = humanoid.CameraOffset:Lerp(newOffset, trailAlpha)
		humanoid.CameraOffset = cameraOffset
		debug.profileend()
	end)
	if connection ~= nil then
		connections["trail"] = connection
	end
end

function GameCamera:changeFOV(change: number)
	-- Usually 60 or 70.
	TweenPlus(
		camera,
		{ FieldOfView = change },
		{ Time = Emphasis.emphasized, EasingDirection = "Out", EasingStyle = "Circular" }
	):Start()
end

function GameCamera:disconnect(scriptConnection: string)
	if connections[scriptConnection:lower()] then
		local connection = connections[scriptConnection:lower()]
		if connection then
			connection:Disconnect()
		end
	end
end

function GameCamera:remove()
	if not connections then
		return
	end
	for name, _ in connections do
		if _ then
			_:Disconnect()
			_ = nil
		end
	end
	RunService:UnbindFromRenderStep("sway")
	print("removed gamecamera")
end

return GameCamera
