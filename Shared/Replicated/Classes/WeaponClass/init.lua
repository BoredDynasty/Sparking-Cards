--!nonstrict

-- WeaponClass.lua

local WeaponClass = {}
WeaponClass.__index = WeaponClass

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local DamageIndict = require(script.DamageIndict)

export type ToolType = "Melee" | "Projectile"

--[=[
    @within WeaponClass
        @return table
--]=]
function WeaponClass.new()
	local self = setmetatable({}, WeaponClass)
	self.tool = nil :: Tool
	self.type = nil :: string
	self.cooldown = {}
end

--[=[
    @within WeaponClass
        @return any
        @tag Simple raycast so I don't have to script one myself
--]=]
function WeaponClass:Raycast(range: number)
	local player = Players:GetPlayerFromCharacter(self.tool.Parent)
	local character = player.Character
	local humanoid = character.Humanoid

	local target = nil

	if character and humanoid.Health > 0 then
		local origin = character.HumanoidRootPart.CFrame.Position
		local destination = character.HumanoidRootPart.CFrame.Position
				+ character.HumanoidRootPart.CFrame.LookVector * range
			or 100

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
		raycastParams.FilterDescendantsInstances = { character }
		local raycast = game.Workspace:Raycast(origin, destination, raycastParams)
		if raycast then
			if
				raycast.Instance.Parent:FindFirstChild("HumanoidRootPart")
				or raycast.Instance.Parent.Parent:FindFirstChild("HumanoidRootPart")
			then
				target = raycast.Instance.Parent:FindFirstChild("HumanoidRootPart")
					or raycast.Instance.Parent.Parent:FindFirstChild("HumanoidRootPart")
				print(`Found Target: {target}`)
				target = Players:GetPlayerFromCharacter(target)
			end
		end
	end
	return target
end

return WeaponClass
