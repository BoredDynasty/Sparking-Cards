--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.promise)
local Trove = require(ReplicatedStorage.Packages.trove)
local StateMachine = require(ReplicatedStorage.Utility.statemachine)

local Orion = {}
Orion.CombatModules = {}

--[[
	Initializes the Orion framework for a given character.
	@param character The character to initialize the framework for.
	@returns A new Orion instance.
]]
function Orion.new(character)
	local self = {}
	setmetatable(self, { __index = Orion })

	self.Character = character
	self.Trove = Trove.new()
	self.StateMachine = StateMachine.new({
		Initial = "Idle",
		States = {
			Idle = {
				Transitions = {
					Attacking = "Attacking",
				},
			},
			Attacking = {
				Transitions = {
					Idle = "Idle",
				},
			},
		},
	})

	return self
end

local CombatModulesDir = script.Parent:WaitForChild("CombatModules")

--[[
	Loads a combat module by name.
	@param moduleName The name of the module to load.
	@returns A promise that resolves with the loaded module.
]]
function Orion:LoadModule(moduleName)
	if Orion.CombatModules[moduleName] then
		return Promise.resolve(Orion.CombatModules[moduleName])
	end

	return Promise.new(function(resolve, reject)
		local module = CombatModulesDir:FindFirstChild(moduleName)
		if not module or not module:IsA("ModuleScript") then
			return reject(string.format("Combat module '%s' not found.", moduleName))
		end

		local success, result = pcall(require, module)
		if not success then
			return reject(string.format("Failed to load combat module '%s': %s", moduleName, tostring(result)))
		end

		Orion.CombatModules[moduleName] = result
		resolve(result)
	end)
end

--[[
	Executes an attack using a loaded combat module.
	@param moduleName The name of the combat module to use.
	@param attackType The type of attack to execute (e.g., "M1", "Skill").
	@param ... Additional arguments for the attack.
]]
function Orion:ExecuteAttack(moduleName, attackType, ...)
	local self = self
	return self:LoadModule(moduleName):andThen(function(module)
		if not module[attackType] then
			return Promise.reject(string.format("Attack type '%s' not found in module '%s'.", attackType, moduleName))
		end

		local attackTrove = Trove.new()
		self.Trove:Add(attackTrove)

		local result = module[attackType](self.Character, attackTrove, ...)
		return Promise.resolve(result)
	end)
end

--[[
	Cleans up the Orion instance.
]]
function Orion:Destroy()
	self.Trove:Destroy()
end

return Orion
