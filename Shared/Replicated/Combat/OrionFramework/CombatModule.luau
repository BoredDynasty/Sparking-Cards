--!nonstrict
local CombatModule = {}
CombatModule.__index = CombatModule

function CombatModule.new(name)
	local self = setmetatable({}, CombatModule)
	self.Name = name
	return self
end

function CombatModule:M1(character, trove, ...)
	-- Placeholder for M1 attack
end

function CombatModule:Skill(character, trove, ...)
	-- Placeholder for Skill attack
end

function CombatModule:Ultimate(character, trove, ...)
	-- Placeholder for Ultimate attack
end

function CombatModule:Support(character, trove, ...)
	-- Placeholder for Support attack
end

return CombatModule
