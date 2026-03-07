-- Title: Weld script 2.2
-- Date: September 6th 2014
-- Author: Zephyred
--
-- Release notes:
-- * The root instance will be welded too if it's a part
-- * Increased flexibility, each call now creates it's own list of welds so you have more control over it.
--
----------------------------
local P			= script.Parent
----- NO EDITING BELOW -----

-- This function actually creates the weld.
function CreateWeld(x, y)
	local weld = Instance.new("Weld") 
	weld.Part0 = x
	weld.Part1 = y
	weld.C0 = x.CFrame:inverse() * x.CFrame  
	weld.C1 = y.CFrame:inverse() * x.CFrame  
	weld.Parent = x
	return weld
end

-- A recursive function (google it) which traverses all parts in a model to weld them.
function WeldAll(instance, mainPart, list)
	if instance:IsA("BasePart") then
		table.insert(list, CreateWeld(mainPart, instance))
	end
	for _,v in pairs(instance:GetChildren()) do	
		WeldAll(v, mainPart, list)
	end	
end

-- Unanchores all parts in a weld list.
function UnanchorWeldList(weldList)
	for i,v in pairs(weldList) do
		v.Part0.Anchored = false
		v.Part1.Anchored = false
	end
end

-- This is the function you should use if you want to weld a model.
-- Parameters:
-- model = The Model containing the parts.
-- mainPart = The part where all other parts will be welded against. 
-- Returns:
-- A Lua table containing all welds, which can be fed into the UnanchorWeldList function, as demonstrated in the example code.
function WeldAllToPart(model, mainPart)
	local welds = {}
	WeldAll(model, mainPart, welds)
	return welds
end

----- EXAMPLE CODE -----
local weldList1 = WeldAllToPart(P, P.Engine) -- Weld a model, returns a list of welds.
UnanchorWeldList(weldList1) -- Unanchores the list of welds given.

script:Destroy() -- Clean up this script.