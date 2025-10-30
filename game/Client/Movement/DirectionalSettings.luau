--!strict
--[=[
	DirectionalSettings
	@class DirectionalSettings

	Handles the directional manipulation of movement settings.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)

local class = {}
class.__index = class

export type self = {
	_movementController: any,
	_config: any,
}

function class.new(movementController): setmetatable<self, typeof(class)>
	local self = setmetatable({
		_movementController = movementController,
		_config = MovementConfig,
	}, class)

	return self
end

function class:getSettings(self: self, movementType: string, direction: Vector3): any
	local settings = self._config[movementType]
	if not settings then
		return nil
	end

	local directionalSettings = settings.Directional
	if not directionalSettings then
		return settings
	end

	local forward = workspace.CurrentCamera.CFrame.LookVector
	local right = workspace.CurrentCamera.CFrame.RightVector
	local up = workspace.CurrentCamera.CFrame.UpVector

	local dotForward = direction:Dot(forward)
	local dotRight = direction:Dot(right)
	local dotUp = direction:Dot(up)

	local newSettings = {}
	for key, value in pairs(settings) do
		if key ~= "Directional" then
			newSettings[key] = value
		end
	end

	if math.abs(dotForward) > math.abs(dotRight) and math.abs(dotForward) > math.abs(dotUp) then
		-- Forward/Backward
		if dotForward > 0 then
			-- Forward
			for key, value in pairs(directionalSettings.Forward) do
				newSettings[key] = value
			end
		else
			-- Backward
			for key, value in pairs(directionalSettings.Backward) do
				newSettings[key] = value
			end
		end
	elseif math.abs(dotRight) > math.abs(dotForward) and math.abs(dotRight) > math.abs(dotUp) then
		-- Right/Left
		if dotRight > 0 then
			-- Right
			for key, value in pairs(directionalSettings.Right) do
				newSettings[key] = value
			end
		else
			-- Left
			for key, value in pairs(directionalSettings.Left) do
				newSettings[key] = value
			end
		end
	else
		-- Up/Down
		if dotUp > 0 then
			-- Up
			for key, value in pairs(directionalSettings.Up) do
				newSettings[key] = value
			end
		else
			-- Down
			for key, value in pairs(directionalSettings.Down) do
				newSettings[key] = value
			end
		end
	end

	return newSettings
end

function class:destroy(self: self)
end

return class
