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

local function onPreRender(delta_time)
	if not next(module.effects) then
		return
	end

	for i, effect in ipairs(module.effects) do
		debug.profilebegin(effect.name)

		effect.fn(delta_time)

		debug.profileend()
	end
end

function module:Enable()
	if conn then
		return
	end

	conn = RunService.PreRender:Connect(onPreRender)
end

function module:Disable()
	if conn then
		conn:Disconnect()
		conn = nil
	end
end

conn = RunService.PreRender:Connect(onPreRender)

return module
