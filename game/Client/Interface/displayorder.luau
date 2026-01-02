--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local custom_lighting = require(ReplicatedStorage.ClientModules["custom-lighting"])
local future = require(ReplicatedStorage.Packages.future)
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- displayorder.luau

local module = {}

export type CanvasData = {
	canvas: CanvasGroup,
	state: observer.observer_mt<boolean>,
	connections: { SignalPlus.Connection },
}

local _trove = trove.new()
local tracked = {} :: { [string]: CanvasData }

local limit = ratelimit(1, 2)

function createScale(ancestor: Instance)
	local scale = _trove:Construct(Instance, "UIScale", ancestor) :: UIScale
	hydration(scale) {
		Scale = 1,
		Name = "ui_scale",
	}

	return scale
end

function getScale(ancestor: Instance)
	return ancestor:FindFirstChild("ui_scale", true) :: UIScale?
end

function module.new(canvas: CanvasGroup, position: Vector2?, size: Vector2?)
	local identifier = canvas:GetFullName()

	local data = {
		canvas = canvas,
		state = observer.new(canvas.Visible),
		connections = {} :: { SignalPlus.Connection },
	}

	tracked[identifier] = data

	canvas.Destroying:Once(function()
		local data = tracked[identifier]

		for i, conn in ipairs(data.connections :: { SignalPlus.Connection }) do
			conn:Disconnect()
		end

		table.clear(tracked[identifier])

		tracked[identifier] = nil
	end)

	return data
end

function module:Toggle(canvas: CanvasGroup)
	local identifier = canvas:GetFullName()

	local ok, data = future
		.Try(function()
			return tracked[identifier]
		end)
		:Unwrap()

	if not ok or not data then
		return
	end

	if limit(identifier) then
		return
	end

	local state = data.state

	state:Map(function(current: boolean)
		return not current
	end)

	-- hide every other one
	for i, interface_data in pairs(tracked) do
		if data == interface_data then
			continue
		end

		interface_data.state:Set(false)
	end
end

function module:Watch()
	for i, interface_data in pairs(tracked) do
		local conn = nil

		conn = interface_data.state:Watch(function(newValue: boolean)
			local canvas = interface_data.canvas

			if newValue then
				-- visible

				local scale = createScale(canvas)
				scale.Scale = 0

				canvas.Visible = true
				canvas.BackgroundTransparency = 1

				spr.target(scale, 0.8, 1.5, {
					Scale = 1,
				})
			else
				local scale = getScale(canvas)
				if not scale then
					return
				end

				spr.target(scale, 0.9, 1, {
					Scale = 0,
				})

				spr.completed(scale, function()
					future.Try(_trove.Remove, _trove, scale :: any)

					canvas.Visible = false
				end)

				custom_lighting.unblur()
			end
		end)

		if conn then
			table.insert(interface_data.connections, conn)
		end
	end
end

return module
