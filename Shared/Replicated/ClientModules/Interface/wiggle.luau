--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spr = require(ReplicatedStorage.Modules.spr)

-- wiggle.luau
-- a small wiggle effect for ui

--[[
   ```luau
   
   -- example usage

   local wiggle = require(path.to.wiggle)

   wiggle(path.to.ui, function()
      print("completed wiggle animation!"
   end)
   ```
]]
return function(object: GuiObject, fn: () -> ()?)
	spr.target(object, 0.3, 4, {
		Rotation = 10,
	})

	task.delay(0.3, function()
		spr.target(object, 0.3, 4, {
			Rotation = -10,
		})

		task.delay(0.3, function()
			spr.target(object, 0.2, 6, {
				Rotation = 0,
			})

			task.delay(0.2, function()
				if fn then
					fn()
				end
			end)
		end)
	end)
end
