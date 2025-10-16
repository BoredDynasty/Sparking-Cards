--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local random = require(ReplicatedStorage.Utility.random)
local shadow = require(script.Parent.shadow)
local trove = require(ReplicatedStorage.Packages.trove)

-- confetti.luau

-- Util

local random_seed = random.create()
local _trove = trove.new()

return function(colors: { Color3 }, container: Instance, add_shadow: boolean?)
	for i = 1, 4, 1 do
		for j = 1, 20, 1 do
			local newConfettiVisual = Instance.new("Frame")
			newConfettiVisual.Size = UDim2.fromScale(0.09, 0.035)
			newConfettiVisual.AnchorPoint = Vector2.new(0.5, 0.5)
			newConfettiVisual:SetAttribute("IsConfetti", true)

			local nextNumber = random_seed:integer(-0.3, 1.3)

			newConfettiVisual.Position = UDim2.new(nextNumber, 0, -0.2, 0)

			nextNumber = random_seed:integer(3, 360)
			newConfettiVisual.Rotation = nextNumber
			newConfettiVisual.Parent = container

			newConfettiVisual.BackgroundColor3 = colors[random_seed:integer(1, #colors)]
			newConfettiVisual.BorderSizePixel = 0

			_trove:Add(newConfettiVisual)

			if add_shadow then
				shadow(newConfettiVisual)
			end

			local goal = {
				Position = UDim2.new(
					newConfettiVisual.Position.X.Scale,
					0,
					newConfettiVisual.Position.Y.Scale + 9.3,
					0
				),
			}

			local confettiTween = TweenPlus(newConfettiVisual, goal, {
				Time = 3 + (j / 10),
				EasingStyle = "Linear",
				EasingDirection = "Out",
			})

			confettiTween:Start()
			confettiTween.Completed:Connect(function()
				_trove:Remove(newConfettiVisual)
			end)
		end
	end
end
