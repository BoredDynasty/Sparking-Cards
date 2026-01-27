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
return function(object: GuiObject, fn: () -> ())
	spr.target(object, (1 / 8), (1 / 2), {
		Rotation = math.rad(35),
	})

	task.wait(1)

	spr.stop(object, "Rotation")

	spr.target(object, 1, 2, {
		Rotation = math.rad(0),
	})

	task.spawn(spr.completed, object, fn or function()
		return
	end)
end
