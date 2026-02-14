--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- combo.luau
-- a module for keeping track of combos

-- using ./data.luau

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

export type ComboData = {
	CurrentCombo: number,
	LastHitTime: number,
	MaxCombo: number,
}

local combo_module = {
	COMBO_RESET_TIME = 2, -- seconds
}

--- Creates a new combo data table
--- @param initial_combo number -- initial combo count
--- @return ComboData
function combo_module.new(initial_combo: number?): ComboData
	return {
		CurrentCombo = initial_combo or 0,
		LastHitTime = 0,
		MaxCombo = initial_combo or 0,
	}
end

--- Increments the combo counter
--- @param combo_data ComboData
--- @param current_time number
function combo_module:increment(combo_data: ComboData, current_time: number): ()
	if combo_module:is_active(combo_data, current_time) then
		combo_data.CurrentCombo += 1
	else
		combo_data.CurrentCombo = 1
	end

	combo_data.LastHitTime = current_time
	combo_data.MaxCombo = math.max(combo_data.MaxCombo, combo_data.CurrentCombo)
end

--- Resets the combo counter
--- @param combo_data ComboData
function combo_module:reset(combo_data: ComboData): ()
	combo_data.CurrentCombo = 0
	combo_data.LastHitTime = 0
end

--- Checks if combo is still active based on reset time
--- @param combo_data ComboData
--- @param current_time number
--- @return boolean
function combo_module:is_active(combo_data: ComboData, current_time: number): boolean
	return (current_time - combo_data.LastHitTime) < combo_module.COMBO_RESET_TIME
end

--- Gets the time elapsed since last hit
--- @param combo_data ComboData
--- @param current_time number
--- @return number
function combo_module:get_time_since_last_hit(combo_data: ComboData, current_time: number): number
	return current_time - combo_data.LastHitTime
end

return combo_module
