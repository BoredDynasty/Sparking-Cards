--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local lerp = require(StarterPlayer.StarterPlayerScripts.Utilities.lerp)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- sway.luau
-- a module for making UI, "sway"

local module = {}

local player = playerMarshaller.get()
local character = player.Character
local root_part = character.PrimaryPart
local humanoid = character.Humanoid

local sway_vector = Vector2.one
local bobble_vector = Vector2.one

local swaySpeed = 2.5

type objectList = {
	{
		canvas: CanvasGroup | Frame,
		initial_position: UDim2,
	}
}

local tracked = table.create(100) :: objectList

local function onRenderStepped(deltaTime: number, canvas: CanvasGroup | Frame, initial_position: UDim2)
	if not initial_position then
		return
	end

	local delta = UserInputService:GetMouseDelta()

	local current_time = os.time()

	local x = lerp(sway_vector.X, delta.X * 2.5, deltaTime * swaySpeed)
	local y = lerp(sway_vector.Y, delta.Y * 2.5, deltaTime * swaySpeed)

	sway_vector = Vector2.new(x, y)

	if humanoid.MoveDirection.Magnitude > 0 then
		-- lowers speed, change divided by ...

		local velocity = root_part.AssemblyLinearVelocity
		local magnitude = velocity.Magnitude

		x = math.cos(current_time * 10) * magnitude / 2
		y = math.abs(math.sin(current_time * 10)) * magnitude / 2

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

function module:Track(canvas: CanvasGroup | Frame)
	table.insert(tracked, {
		canvas = canvas,
		initial_position = canvas.Position,
	})
end

RunService.RenderStepped:Connect(function(deltaTime)
	debug.profilebegin("ui-sway")

	for i, object in ipairs(tracked) do
		onRenderStepped(deltaTime, object.canvas, object.initial_position)
	end

	debug.profileend()
end)

return module
