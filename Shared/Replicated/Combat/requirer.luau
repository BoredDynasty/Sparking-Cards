--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- requirer.luau

-- a module for requiring module scripts in the directory
-- not to be used by any attack scripts though.

local requirer = {}

requirer.require = function(name: string): any
	local attack_module = nil
	print(1.5)
	local success, module = pcall(require, ReplicatedStorage.Combat.framework.attacks[name])
	print(1.6)
	if success then
		return module
	else
		warn("Could not require attack module:", name, module)
		return nil
	end
end

return requirer
