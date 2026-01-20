--!strict

-- pop.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spr = require(ReplicatedStorage.Modules.spr)

return function(object: Instance | { Instance }, ratio: number?)
	ratio = ratio or 0.8

	local objects = (typeof(object) == "table") and object or { object }

	for _, gui in ipairs(objects) do
		-- Create or get existing UIScale
		local uiScale = gui:FindFirstChild("PopScale") :: UIScale
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Name = "PopScale"
			uiScale.Parent = gui
		end

		-- Instantly set to 1 before animating
		uiScale.Scale = 1

		-- Animate to ratio (squeeze), then back to 1 (pop)
		spr.target(uiScale, 1, 20, { Scale = ratio })
		spr.completed(uiScale, function()
			spr.target(uiScale, 1, 12, { Scale = 1 })
		end)
	end
end
