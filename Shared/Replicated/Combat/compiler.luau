--!strict

-- compiler.luau

-- a module to give the main orion script all the combat modules
-- without the hassle of requiring each and every one

local tbl = {}

local folder = script.Parent.framework.attacks

for name, module in folder:GetChildren() do
	if module:IsA("ModuleScript") then
		tbl[module.Name] = require(module)
		print("Loaded combat module: " .. module.Name)
	end
end

return tbl
