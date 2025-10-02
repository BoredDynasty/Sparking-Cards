--!nonstrict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local promise = require(ReplicatedStorage.Packages.promise)
local random = require(ReplicatedStorage.Utility.random)

export type ExplodeEffect = {
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
local function kaboom(parameters: ExplodeEffect)
	local explodeEffect = fetchAsset("ExplosionModel") :: Model & any
	local primaryPart = explodeEffect.PrimaryPart :: BasePart

	-- Set initial position and size
	primaryPart.Position = parameters.position
	local inner = primaryPart.Inner :: BasePart
	local outer = primaryPart.Outer :: BasePart

	-- Random rotation angles
	local randomRotX = random.float(-180, 180)
	local randomRotY = random.float(-180, 180)
	local randomRotZ = random.float(-180, 180)

	-- Create explosion tweens
	local innerTween = TweenPlus(inner, {
		Size = inner.Size * 3,
		Transparency = 1,
		CFrame = inner.CFrame
			* CFrame.Angles(math.rad(randomRotX), math.rad(randomRotY), math.rad(randomRotZ)),
	}, {
		Time = parameters.duration * 0.8,
		EasingStyle = "Quad",
		EasingDirection = "Out",
	})

	local outerTween = TweenPlus(outer, {
		Size = outer.Size * 5,
		Transparency = 1,
		CFrame = outer.CFrame
			* CFrame.Angles(math.rad(-randomRotX), math.rad(-randomRotY), math.rad(-randomRotZ)),
	}, {
		Time = parameters.duration,
		EasingStyle = "Sine",
		EasingDirection = "Out",
	})

	-- Set colors if provided
	if parameters.colors and #parameters.colors > 0 then
		local randomColor = parameters.colors[random.integer(1, #parameters.colors)]
		inner.Color = randomColor
		outer.Color = randomColor
	end

	-- Start tweens
	innerTween:Start()
	outerTween:Start()

	-- Cleanup
	promise.new(function()
		task.delay(parameters.duration, explodeEffect.Destroy)
	end)
end

return {
	kaboom = kaboom,
}
