--!nonstrict

-- Hint.luau

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Spring = require(script.Parent.Parent.Interface.spring)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local hintGui = playerGui:WaitForChild("Hint") :: ScreenGui
local hintCanvas = hintGui:WaitForChild("CanvasGroup") :: CanvasGroup
local hintFrame = hintCanvas:FindFirstChild("Frame") :: Frame

local details = hintFrame:FindFirstChild("Details") :: TextLabel

local characterLimit = math.exp(5)

local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local connection: RBXScriptConnection? = nil
local hintSpring = Spring.new(Vector2.new(), 200, 10, 1) -- Using your original spring values

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

	-- Reset spring with current mouse position
	hintSpring:Reset(hintSpring, Vector2.new(mouse.X, mouse.Y))

	if not connection then
		connection = RunService.RenderStepped:Connect(function(deltaTime: number)
			local viewSize = camera.ViewportSize
			local offset = (scale.X.Scale * viewSize)

			-- Update target position
			hintSpring:SetTarget(hintSpring, Vector2.new(mouse.X, mouse.Y))

			-- Update spring physics
			hintSpring:Update(hintSpring, deltaTime)

			-- Determine which side of the screen the mouse is on
			local isMouseOnRightHalf = mouse.X > viewSize.X / 2

			-- Calculate the offset based on mouse position
			local xOffset = isMouseOnRightHalf and -offset.X - 440 -- Move to left of cursor
				or 440 -- Move to right of cursor

			-- Apply position with spring effect
			local finalPosition = UDim2.new(0, (hintSpring.Position.X + xOffset), 0, hintSpring.Position.Y)

			hintFrame.Position = finalPosition
		end)
	end

	hintFrame.Visible = true
	details.Text = t
end
