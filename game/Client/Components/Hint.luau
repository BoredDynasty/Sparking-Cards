--!strict

-- Hint.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local hintGui = playerGui:WaitForChild("Hint") :: ScreenGui
local hintCanvas = hintGui:WaitForChild("CanvasGroup") :: CanvasGroup
local hintFrame = hintCanvas:FindFirstChild("Frame") :: Frame

local details = hintFrame:FindFirstChild("Details") :: TextLabel

local characterLimit = 46

local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local connection: RBXScriptConnection? = nil

-- Spring physics parameters
local springPosition = Vector2.new()
local targetPosition = Vector2.new()
local velocity = Vector2.new()
local stiffness = 200 -- Spring stiffness
local damping = 10 -- Damping factor
local mass = 1 -- Mass of the spring system

return function(t: string, element: GuiObject)
	if (t:len() or #t or string.len(t)) >= characterLimit then
		print("char limit")
	end

	element.MouseLeave:Once(function()
		--Fade:FadeOut(hintFrame, 0.4)
		task.wait() -- for a much more cooler effect
		hintFrame.Visible = false
		if connection then
			connection:Disconnect()
			connection = nil
		end
		return
	end)

	local scale = hintFrame.Size
	if connection and typeof(connection) == "RBXScriptConnection" then
		connection:Disconnect()
		connection = nil
	end

	-- Reset spring values
	springPosition = Vector2.new(mouse.X, mouse.Y)
	targetPosition = springPosition
	velocity = Vector2.new()

	if not connection then
		connection = RunService.RenderStepped:Connect(function(deltaTime: number)
			local viewSize = camera.ViewportSize
			local offset = (scale.X.Scale * viewSize)

			-- Update target position
			targetPosition = Vector2.new(mouse.X, mouse.Y)

			-- Spring physics calculation
			local force = (targetPosition - springPosition) * stiffness
			local dampingForce = velocity * -damping
			local acceleration = (force + dampingForce) / mass

			velocity = velocity + acceleration * deltaTime
			springPosition = springPosition + velocity * deltaTime

			-- Determine which side of the screen the mouse is on
			local isMouseOnRightHalf = mouse.X > viewSize.X / 2

			-- Calculate the offset based on mouse position
			local xOffset = isMouseOnRightHalf and -offset.X - 440 -- Move to left of cursor
				or 440 -- Move to right of cursor

			-- Apply position with spring effect
			local finalPosition = UDim2.new(0, (springPosition.X + xOffset), 0, springPosition.Y)

			hintFrame.Position = finalPosition
		end)
	end

	hintFrame.Visible = true
	details.Text = t
end
