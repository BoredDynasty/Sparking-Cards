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
type metricTypes = {
	position1: Vector3,
	position2: Vector3,
	duration: number,
	position2Object: BasePart,
}
local function getMetrics(metricTable: metricTypes): Vector3
	if metricTable == nil then
		return
	end

	local position1: Vector3 = metricTable[1]
	local position2: Vector3 = metricTable[2]
	local duration: number = metricTable[3]
	local position2Object: BasePart = metricTable[4]

	position2 = position2Object.Position
	local direction = position2 - position1
	position2 = position2 + position2Object.AssemblyLinearVelocity * duration
	direction = position2 - position1
	local force = direction / duration + Vector3.new(0, game.Workspace.Gravity * duration * 0.5, 0)

	return force
end
function Projectile.New(object: BasePart, metricTable: metricTypes)
	task.spawn(function()
		if object == nil or metricTable == nil then
			return
		end
		local force = getMetrics(metricTable)
		if object:IsA("Model") then
			local primaryPart = nil
			local totalMass = 0
			local clone = object:Clone()
			primaryPart = clone.PrimaryPart
			primaryPart.Position = metricTable[1]
			clone.Parent = game.Workspace

			for _, part in clone:GetDescendants() do
				if part:IsA("BasePart") then
					totalMass = totalMass + part:GetMass()
				end
			end

			primaryPart:ApplyImpulse(force * totalMass)
			primaryPart:SetNetworkOwner(nil)
		else
			local clone = object:Clone()
			clone.Position = metricTable[1]
			clone.Parent = game.Workspace

			clone:ApplyImpulse(force * clone.AssemblyMass)
			clone:SetNetworkOwner(nil)
		end
	end)
end
return Projectile
