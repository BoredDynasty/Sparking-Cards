--!strict

-- weld-utility
-- by Zephyred, modifified by Dynasty

local module = {}

local function createWeld(x: BasePart, y: BasePart)
	local weld = Instance.new("Weld")
	weld.Part0 = x
	weld.Part1 = y

	weld.C0 = x.CFrame:Inverse() * x.CFrame
	weld.C1 = y.CFrame:Inverse() * x.CFrame

	weld.Parent = x

	return weld
end

local function weldAll(instance: Instance, primary_part, list)
	if instance:IsA("BasePart") then
		table.insert(list, createWeld(primary_part, instance))
	end

	for _, object in ipairs(instance:GetChildren()) do
		weldAll(object, primary_part, list)
	end
end

local function unanchorWelds(welds: { Weld })
	for i, weld in ipairs(welds) do
		assert(weld.Part0, "no part one or zero for weld.")
		assert(weld.Part1, "no part one or zero for weld.")

		weld.Part0.Anchored = false
		weld.Part1.Anchored = false
	end
end

function WeldAllToPart(model, primary_part)
	local welds = {}

	weldAll(model, primary_part, welds)

	return welds
end

function module:Weld(model: Instance, primary_part: BasePart)
	local list = WeldAllToPart(model, primary_part)
	unanchorWelds(list)
end

return module
