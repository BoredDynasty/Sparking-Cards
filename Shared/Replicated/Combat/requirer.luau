--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local promise = require(script.Parent.Parent.Packages.promise)

-- requirer.luau

-- a module for requiring module scripts in the directory
-- not to be used by any attack scripts though.

local requirer = {}

requirer.require = function(name: string): any
	local attack_module = nil
	-- use a promise
	local attackModulePromise = promise.new(function(resolve, reject)
		local modulePath = ReplicatedStorage.Combat.framework.attacks[name] :: ModuleScript?
		if not modulePath then
			reject("Module path is incorrect")
			return
		end
		local success, result = pcall(require, modulePath)
		if success then
			resolve(result)
		else
			reject("Attack module couldn't be loaded: " .. result)
			return
		end
	end)
	local worked, result = attackModulePromise:await()
	assert(worked and result, result)
	attack_module = result :: any
	return attack_module
end

return requirer
