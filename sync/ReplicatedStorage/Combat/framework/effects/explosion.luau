--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local future = require(ReplicatedStorage.Packages.future)
local random = require(ReplicatedStorage.Utility.random)
local spr = require(ReplicatedStorage.Modules.spr)

export type explode_model = {
	position: Vector3,
	duration: number,
	colors: { Color3 },
}

--[[

   Example Usage

   ```luau

   local explosion = require(path.to.explosion)

   explosion.kaboom({
       position = Vector3.new(0, 5, 0),
       duration = 1.5,
       colors = {
          Color3.fromRGB(255, 89, 0),  -- Orange
          Color3.fromRGB(255, 0, 0),   -- Red
          Color3.fromRGB(255, 255, 0)  -- Yellow
      }
   })
]]
local function kaboom(parameters: explode_model)
	local explode_model = fetchAsset("ExplosionModel") :: Model
	local primary_part = explode_model.PrimaryPart :: BasePart

	-- Set initial position and size
	primary_part.Position = parameters.position
	local inner = primary_part:FindFirstChild("Inner") :: BasePart
	local outer = primary_part:FindFirstChild("Outer") :: BasePart

	-- Random rotation angles
	local rotation_x = random.float(-180, 180)
	local rotation_y = random.float(-180, 180)
	local rotation_z = random.float(-180, 180)

	spr.target(inner, 1, 1 / (parameters.duration * 0.8), {
		Size = inner.Size * 3,
		Transparency = 1,
		CFrame = inner.CFrame
			* CFrame.Angles(math.rad(rotation_x), math.rad(rotation_y), math.rad(rotation_z)),
	})
	spr.target(outer, 1, 1 / parameters.duration, {
		Size = outer.Size * 5,
		Transparency = 1,
		CFrame = outer.CFrame
			* CFrame.Angles(math.rad(-rotation_x), math.rad(-rotation_y), math.rad(-rotation_z)),
	})

	-- Set colors if provided
	if parameters.colors and #parameters.colors > 0 then
		local randomColor = parameters.colors[random.integer(1, #parameters.colors)]
		inner.Color = randomColor
		outer.Color = randomColor
	end

	-- Cleanup
	future.Try(function()
		return task.delay(parameters.duration, explode_model.Destroy, explode_model)
	end)
end

return {
	kaboom = kaboom,
}
