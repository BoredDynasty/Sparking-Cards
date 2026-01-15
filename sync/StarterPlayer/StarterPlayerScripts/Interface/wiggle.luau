--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spr = require(ReplicatedStorage.Modules.spr)

-- wiggle.luau
-- a small wiggle effect for ui

--[[
   ```luau
   
   -- example usage

   local wiggle = require(path.to.wiggle)

   local completed = wiggle(path.to.ui)

   completed(path.to.ui, function()
      print("completed wiggle animation!"
   end)
   ```
]]
return function(object: GuiObject)
	spr.target(object, (1 / 8), (1 / 2), {
		Rotation = math.rad(35),
	})

	task.wait(1)

	spr.stop(object, "Rotation")

	spr.target(object, 1, 2, {
		Rotation = math.rad(0),
	})

	return spr.completed
end
