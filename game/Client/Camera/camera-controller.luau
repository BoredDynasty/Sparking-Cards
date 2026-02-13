--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local trove = require(ReplicatedStorage.Packages.trove)

-- camera-controller.luau

local module = {}
module.effects = {}

local _trove = trove.new()

function module.new(name: string, fn: (number) -> CFrame)
	table.insert(module.effects, {
		name = name,
		fn = fn,
	})
end

local conn = nil

conn = RunService.PreRender:Connect(function(delta_time)
	if not next(module.effects) then
		return
	end

	for i, effect in ipairs(module.effects) do
		debug.profilebegin(effect.name)

		effect.fn(delta_time)

		debug.profileend()
	end
end)

return module
