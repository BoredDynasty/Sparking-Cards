--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local lerp = require(StarterPlayer.StarterPlayerScripts.Utilities.lerp)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)

-- sway.luau
-- a module for making UI, "sway"

local sway = {}

local player = playerMarshaller.get()
local character = player.Character
local rootPart = character.HumanoidRootPart
local humanoid = character.Humanoid

local swayVector = Vector2.zero
local bobbleVector = Vector2.zero

local swaySpeed = 2.5

export type objectList = {
	[string]: {
		disconnect: () -> (),
		initialPosition: UDim2,
	},
}

--local list: objectList = {}

local function renderStepped(deltaTime: number, canvas: CanvasGroup | Frame, initialPosition: UDim2)
	local delta = UserInputService:GetMouseDelta()

	local currentTime = tick()

	local x = lerp(swayVector.X, delta.X * 2.5, deltaTime * swaySpeed)
	local y = lerp(swayVector.Y, delta.Y * 2.5, deltaTime * swaySpeed)

	swayVector = Vector2.new(x, y)

	if humanoid.MoveDirection.Magnitude > 0 then
		-- lowers speed, change divided by ...
		x = math.cos(currentTime * 10) * rootPart.AssemblyLinearVelocity.Magnitude / 2
		y = math.abs(math.sin(currentTime * 10)) * rootPart.AssemblyLinearVelocity.Magnitude / 2
		bobbleVector = Vector2.new(x, y)

		canvas.Position = initialPosition
			+ UDim2.fromOffset(bobbleVector.X + swayVector.X, bobbleVector.Y + swayVector.Y)
	else
		canvas.Position = initialPosition + UDim2.fromOffset(swayVector.X, swayVector.Y)
	end
end

function sway:on(canvas: CanvasGroup | Frame)
	local initialPosition = canvas.Position

	gamecamera:Bind("sway", renderStepped, canvas, initialPosition)
end

function sway:off(canvas: CanvasGroup | Frame)
	gamecamera:UnBind("sway")
end

return sway
