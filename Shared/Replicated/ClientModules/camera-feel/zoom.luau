--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local input = require(ReplicatedStorage.Packages.input)
local observer = require(ReplicatedStorage.Utility.observer)

-- zoom.luau

export type config = {
	min: number,
	max: number,
	speed: number,
}

local module = {}

module.scale = observer.new(1)
module.config = nil :: config?

local mouse = input.Mouse.new()

function module:GetScale()
	return module.scale:Get()
end

function module:GetChangedSignal()
	return module.scale.Changed
end

function module:SetConfiguration(config: config)
	module.config = config
end

(mouse.Scrolled :: RBXScriptSignal<number, boolean>):Connect(function(amount: number, processed: boolean)
	if processed then
		return
	end

	local current_scale = module.scale:Get()
	local new_scale = current_scale - amount * (module.config and module.config.speed or 0)
	if module.config then
		new_scale = math.clamp(new_scale, module.config.min, module.config.max)
	end

	module.scale:Set(new_scale)
end)
