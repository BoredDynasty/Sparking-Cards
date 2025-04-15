--!strict

local Projectile = {}
--[[
	Projectile needs to be:
	- unanchored
	- cancollide true or false
	- if its a model weld all parts together
	Metric table HAS to contain these and in the same order:
	- position1
	- position2
	- duration
	- position2Object
	
	Function returns:
	- force
]]
export type metricTypes = {
	position1: Vector3,
	position2: Vector3,
	duration: number,
	position2Object: BasePart,
}
local function getMetrics(metricTable: metricTypes): Vector3
	local position1 = metricTable.position1 :: Vector3
	local position2 = metricTable.position2 :: Vector3
	local duration = metricTable.duration :: number
	local position2Object = metricTable.position2Object :: BasePart

	local gravity = game.Workspace.Gravity :: number

	position2 = position2Object.Position

	local direction = position2 - position1
	position2 = position2 + position2Object.AssemblyLinearVelocity * duration
	direction = position2 - position1
	task.wait()
	local force = direction / duration + Vector3.new(0, gravity * duration * 0.5, 0)

	return force
end
function Projectile.new(object: BasePart, metricTable: metricTypes)
	task.spawn(function()
		local force = getMetrics(metricTable)
		if object:IsA("Model") then
			local primaryPart = nil
			local totalMass = 0
			local clone = object:Clone()
			primaryPart = clone.PrimaryPart
			primaryPart.Position = metricTable.position1
			clone.Parent = game.Workspace

			for _, part: BasePart in clone:GetDescendants() do
				if part:IsA("BasePart") then
					totalMass = totalMass + part:GetMass()
				end
				task.wait()
			end

			primaryPart:ApplyImpulse(force * totalMass)
			primaryPart:SetNetworkOwner(nil)
		else
			local clone = object:Clone()
			clone.Position = metricTable.position1
			clone.Parent = game.Workspace
			task.wait()
			clone:ApplyImpulse(force * clone.AssemblyMass)
			clone:SetNetworkOwner(nil)
		end
	end)
end
return Projectile
