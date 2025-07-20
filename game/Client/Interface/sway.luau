--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)

-- sway.luau
-- a module for making UI, "sway"

local sway = {}

local player = playerMarshaller.get()
local character = player.Character
local rootPart = character.HumanoidRootPart
local humanoid = character.Humanoid

local lerp = function(a: number, b: number, t: number)
	return a + (b - a) * t
end

local swayVector = Vector2.zero
local bobbleVector = Vector2.zero

local swaySpeed = 2.5

export type objectList = {
	[string]: {
		disconnect: () -> (),
		initialPosition: UDim2,
	},
}

local list: objectList = {}
local scopeLength = 10

local function renderStepped(deltaTime: number, canvas: CanvasGroup | Frame, initialPosition: UDim2)
	local delta = UserInputService:GetMouseDelta()
	local currentTime = tick()
	swayVector.X = lerp(swayVector.X, delta.X * 2.5, deltaTime * swaySpeed)
	swayVector.Y = lerp(swayVector.Y, delta.Y * 2.5, deltaTime * swaySpeed)
	if humanoid.MoveDirection.Magnitude > 0 then
		-- lowers speed, change divided by ...
		bobbleVector.X = math.cos(currentTime * 10) * rootPart.AssemblyLinearVelocity.Magnitude / 2
		bobbleVector.Y = math.abs(math.sin(currentTime * 10)) * rootPart.AssemblyLinearVelocity.Magnitude / 2

		canvas.Position = initialPosition
			+ UDim2.fromOffset(bobbleVector.X + swayVector.X, bobbleVector.Y + swayVector.Y)
	else
		canvas.Position = initialPosition + UDim2.fromOffset(swayVector.X, swayVector.Y)
	end
end

function sway:on(canvas: CanvasGroup | Frame)
	local identification = canvas:GetFullName()
	local initialPosition = canvas.Position
	local connection = nil

	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		renderStepped(deltaTime, canvas, initialPosition)
	end)
	list[identification] = {
		disconnect = function()
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end,
		initialPosition = initialPosition,
	}
end

function sway:off(canvas: CanvasGroup | Frame)
	local identification = canvas:GetFullName()
	promise
		.new(function(resolve, reject)
			local layer = list[identification]
			if not layer then
				reject("could not find layer!")
				return
			end
			layer.disconnect()
			canvas.Position = layer.initialPosition
			resolve("cleaned Gui Sway!")
		end)
		:andThen(print)
		:catch(warn)
end

return sway
