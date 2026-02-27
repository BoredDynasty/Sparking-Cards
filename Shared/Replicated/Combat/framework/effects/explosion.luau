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
	--
end

return {
	kaboom = kaboom,
}
