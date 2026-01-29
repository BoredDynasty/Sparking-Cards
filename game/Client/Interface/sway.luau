--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local lerp = require(StarterPlayer.StarterPlayerScripts.Utilities.lerp)

-- sway.luau
-- a module for making UI, "sway"

local module = {}

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root_part = character.PrimaryPart
local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid

local sway_vector = Vector2.one
local bobble_vector = Vector2.one

local sway_speed = 2.5

local tracked = {}

local function onRenderStepped(
	deltaTime: number,
	canvas: GuiObject,
	initial_position: UDim2,
	amplitude: Vector2
)
	if not initial_position then
		return
	end

	local delta = UserInputService:GetMouseDelta()
	local current_time = os.time()

	local x = lerp(sway_vector.X, delta.X * amplitude.X, deltaTime * sway_speed)
	local y = lerp(sway_vector.Y, delta.Y * amplitude.Y, deltaTime * sway_speed)

	sway_vector = Vector2.new(x, y)

	if humanoid.MoveDirection.Magnitude > 0 then
		local velocity = root_part.AssemblyLinearVelocity
		local magnitude = velocity.Magnitude

		x = math.cos(current_time * 10) * magnitude * amplitude.X / 2
		y = math.abs(math.sin(current_time * 10)) * magnitude * amplitude.Y / 2

		bobble_vector = Vector2.new(x, y)

		local offset = UDim2.fromOffset(bobble_vector.X + sway_vector.X, bobble_vector.Y + sway_vector.Y)

		canvas.Position = initial_position + offset
	else
		if sway_vector and sway_vector.X and sway_vector.Y then
			local offset = UDim2.fromOffset(sway_vector.X, sway_vector.Y)

			canvas.Position = initial_position + offset
		end
	end
end

function module.register(canvas: GuiObject, x_amplitude: number, y_amplitude: number)
	table.insert(tracked, {
		canvas = canvas,
		initial_position = canvas.Position,
		x_amplitude = x_amplitude,
		y_amplitude = y_amplitude,
	})
end

RunService.RenderStepped:Connect(function(deltaTime)
	debug.profilebegin("ui-sway")

	for i, object in ipairs(tracked) do
		local amplitude = Vector2.new(object.x_amplitude, object.y_amplitude)

		onRenderStepped(deltaTime, object.canvas, object.initial_position, amplitude)
	end

	debug.profileend()
end)

return module
