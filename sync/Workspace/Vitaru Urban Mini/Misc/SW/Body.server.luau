local P			= script.Parent
local mainPart	= P.SS
----- NO EDITING BELOW -----
local weldedParts = {}
table.insert(weldedParts,mainPart)

function Weld(x, y)
	weld = Instance.new("Weld") 
	weld.Part0 = x
	weld.Part1 = y
	local CJ = CFrame.new(x.Position) 
	weld.C0 = x.CFrame:inverse() * CJ  
	weld.C1 = y.CFrame:inverse() * CJ  
	weld.Parent = x	
	table.insert(weldedParts,y)
end

function WeldRec(instance)
	local childs = instance:GetChildren()
	for _,v in pairs(childs) do
		if v:IsA("BasePart") then
			Weld(mainPart, v)
		end
		WeldRec(v)
	end	
end

WeldRec(P)
--WeldRec(P.Parent.Lights)

for _,v in pairs(weldedParts) do
	if v:IsA("BasePart") then
		v.Anchored = false
	end
end

script:Destroy()