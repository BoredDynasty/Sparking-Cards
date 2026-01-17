--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Emphasis = require(ReplicatedStorage.Utility.Emphasis)

return function(object: GuiObject | { GuiObject }, ratio: number?)
	-- Default ratio if not specified
	ratio = ratio or 0.8

	-- Handle both single objects and tables
	local objects = (typeof(object) == "table") and object or { object }
	local TInfo: TweenInfo

	for _, gui in objects do
		-- Create or get existing UIScale
		local uiScale = Instance.new("UIScale")
		uiScale.Name = "PopScale"
		uiScale.Parent = gui

		-- Create pop effect sequence

		TInfo = TweenInfo.new(Emphasis.standard * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local squeeze = TweenService:Create(uiScale, TInfo, { Scale = ratio })
		TInfo = TweenInfo.new(Emphasis.standard * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local pop = TweenService:Create(uiScale, TInfo, { Scale = 1 })

		-- Play the sequence
		squeeze:Play()
		squeeze.Completed:Once(function()
			pop:Play()
		end)
	end
end
