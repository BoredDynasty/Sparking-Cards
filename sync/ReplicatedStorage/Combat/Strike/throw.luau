--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packet = require(ReplicatedStorage.Packet)

local impact = require(ReplicatedStorage.Combat.framework.effects.impact)
local observer = require(ReplicatedStorage.Utility.observer)
local trove = require(ReplicatedStorage.Packages.trove)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- throw.luau

export type throw = {
	direction: Vector3,
	speed: number, -- studs/s -- studs per second
	character: typemarshaller.Character,
}

local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude
local MAX_THROW_DURATION = 3

return function(parameters: throw)
	-- deprecated
end
