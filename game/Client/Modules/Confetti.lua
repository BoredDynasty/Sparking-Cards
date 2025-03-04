-- Util

local TweenService = game:GetService("TweenService")

local random = Random.new()

return function(colors: { Color3 }, container: Folder)
	task.spawn(function()
		for _ = 1, 4, 1 do
			for _ = 1, 20, 1 do
				local newConfettiVisual = Instance.new("Frame")
				newConfettiVisual.Size = UDim2.fromScale(0.09, 0.035)
				newConfettiVisual.Position = UDim2.new(random:NextNumber(-0.3, 1.3), 0, -0.2, 0)
				newConfettiVisual.Rotation = random:NextNumber(3, 360)
				newConfettiVisual.Parent = container

				newConfettiVisual.BackgroundColor3 = colors[math.random(1, #colors)]
				newConfettiVisual.BorderSizePixel = 0

				local fallInfo = TweenInfo.new(random:NextNumber(1, 3))
				local confettiTween = TweenService:Create(newConfettiVisual, fallInfo, {
					Position = UDim2.new(
						newConfettiVisual.Position.X.Scale,
						0,
						newConfettiVisual.Position.Y.Scale + 1.3,
						0
					),
				})
				confettiTween.Completed:Connect(function()
					newConfettiVisual:Destroy()
					confettiTween:Destroy()
					for _, frame in container:GetChildren() do
						if frame:IsA("Frame") then
							frame:Destroy()
						end
					end
				end)
			end
		end
		task.wait(0.35)
	end)
end
