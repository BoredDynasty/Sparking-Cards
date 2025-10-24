--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fireworks = require(ReplicatedStorage.Modules.Fireworks)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local dropper = require(ReplicatedStorage.ClientModules.dropper)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- prism-awarder.luau

local prism_awarder = {}

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

--[[
   Awards the player with the specified amount of prisms.
   A wrapper for the dropper.luau module

   @param amount - The amount of prisms to award.
   @param fireworks - Whether to play fireworks effect. Default is false.

   ```luau
   -- Example usage:

   prism_awarder.award(10, true)
   ```
]]
function prism_awarder.award(amount: number, fireworks: boolean?)
	dropper:Drop(player, amount, "Prism_OBJ")

	if fireworks then
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then
			return
		end

		Fireworks(rootPart)
	end
end

return prism_awarder
