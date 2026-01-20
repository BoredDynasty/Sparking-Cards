--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local random = require(ReplicatedStorage.Utility.random)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- confetti.luau

-- Util

local random_seed = random.create()
local _trove = trove.new()

return function(colors: { Color3 }?, container: Instance, add_shadow: boolean?)
	colors = colors
		or {
			Color3.new(1, 0, 0),
			Color3.new(0, 0.101961, 1),
			Color3.new(0, 1, 0.666667),
			Color3.new(1, 0.85098, 0),
		}

	for i = 1, 4, 1 do
		for j = 1, 20, 1 do
			local confetti = Instance.new("Frame")
			confetti.Size = UDim2.fromScale(0.09, 0.035)
			confetti.AnchorPoint = Vector2.new(0.5, 0.5)
			confetti:SetAttribute("IsConfetti", true)

			local nextNumber = random_seed:integer(-0.3, 1.3)

			confetti.Position = UDim2.new(nextNumber, 0, -0.2, 0)

			nextNumber = random_seed:integer(3, 360)
			confetti.Rotation = nextNumber
			confetti.Parent = container

			confetti.BackgroundColor3 = colors[random_seed:integer(1, #colors)]
			confetti.BorderSizePixel = 0

			_trove:Add(confetti)

			if add_shadow then
				shadow(confetti)
			end

			local goal = {
				Position = UDim2.new(confetti.Position.X.Scale, 0, confetti.Position.Y.Scale + 9.3, 0),
			}

			spr.target(confetti, 1, 1 / (3 + (j / 10)), goal)

			spr.completed(confetti, function()
				task.defer(confetti.Destroy, confetti)
			end)
		end
	end
end
