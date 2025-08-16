--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local promise = require(script.Parent.Parent.Packages.promise)

-- requirer.luau

-- a module for requiring module scripts in the directory
-- not to be used by any attack scripts though.

local requirer = {}

requirer.require = function(name: string): any
	local attack_module = nil
	return require(ReplicatedStorage.Combat.framework.attacks["Frost"]) --placeholder
end

return requirer
