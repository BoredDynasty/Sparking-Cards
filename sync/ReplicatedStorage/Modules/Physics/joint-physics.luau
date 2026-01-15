--!strict

-- joint-physics.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)

local joint_physics = {}

function joint_physics.new(p0: BasePart, p1: BasePart, c0: CFrame?, c1: CFrame?)
	local joint = Instance.new("Weld")

	hydration(joint) {
		Parent = p1,
		Part0 = p0,
		Part1 = p1,
		C0 = c0 or CFrame.new(),
		C1 = if c0 then c1 or CFrame.new() else p1.CFrame:ToObjectSpace(p0.CFrame),
	}

	return joint
end

function joint_physics:Combine(model: Model, root: BasePart)
	for i, base_part in ipairs(model:GetChildren()) do
		if base_part:IsA("BasePart") or base_part:IsA("UnionOperation") and base_part ~= root then
			joint_physics.new(base_part, root)
		end

		root.Anchored = false
	end
end

return joint_physics
