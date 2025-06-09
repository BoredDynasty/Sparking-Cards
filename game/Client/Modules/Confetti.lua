--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local random = require(ReplicatedStorage.Utility.random)

-- Util

local random_seed = random.create()

return function(colors: { Color3 }, container: Folder)
	task.spawn(function()
		for _ = 1, 4, 1 do
			for _ = 1, 20, 1 do
				local newConfettiVisual = Instance.new("Frame")
				newConfettiVisual.Size = UDim2.fromScale(0.09, 0.035)
				local nextNumber = random_seed:integer(-0.3, 1.3)
				newConfettiVisual.Position = UDim2.new(nextNumber, 0, -0.2, 0)
				nextNumber = random_seed:integer(3, 360)
				newConfettiVisual.Rotation = nextNumber
				newConfettiVisual.Parent = container

				newConfettiVisual.BackgroundColor3 = colors[math.random(1, #colors)]
				newConfettiVisual.BorderSizePixel = 0

				local fallInfo = TweenInfo.new(random_seed:integer(1, 3))
				local goal = {
					Position = UDim2.new(
						newConfettiVisual.Position.X.Scale,
						0,
						newConfettiVisual.Position.Y.Scale + 9.3,
						0
					),
				}
				local confettiTween = TweenService:Create(newConfettiVisual, fallInfo, goal)
				confettiTween:Play()
				confettiTween.Completed:Connect(function()
					newConfettiVisual:Destroy()
					for _, frame in container:GetChildren() do
						if frame:IsA("Frame") then
							frame:Destroy() -- no memory leak sir.
						end
					end
				end)
			end
		end
		task.wait(0.35)
	end)
end
