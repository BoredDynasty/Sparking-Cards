--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local observer = require(ReplicatedStorage.Utility.observer)
local promise = require(ReplicatedStorage.Packages.promise)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- displayorder.luau

local display_order = {
	tracked_interfaces = {},
	_trove = trove.new(),
}

export type interface_data = {
	identifier: string,
	state: observer.Observer<boolean>,
	canvas: CanvasGroup,
	debounce: observer.Observer<boolean>,
}

function display_order._createScale(ancestor: Instance?)
	local scale = display_order._trove:Construct(
		Instance,
		"UIScale",
		if ancestor then ancestor else workspace
	) :: UIScale

	scale.Scale = 1
	scale.Name = "ui_scale"

	return scale
end

function display_order._getScale(ancestor: Instance)
	local scale = ancestor:FindFirstChild("ui_scale", true) :: UIScale?

	if scale then
		return scale
	end

	return nil
end

function display_order.new(canvas: CanvasGroup)
	local identifier = canvas:GetFullName()

	display_order.tracked_interfaces[identifier] = {
		identifier = identifier,
		state = observer.new(false),
		canvas = canvas,
		debounce = observer.new(false),
	}

	return display_order.tracked_interfaces[identifier]
end

function display_order:toggle(canvas: CanvasGroup)
	local identifier = canvas:GetFullName()

	local data = promise
		.new(function(resolve)
			resolve(display_order.tracked_interfaces[identifier])

			return display_order.tracked_interfaces[identifier]
		end)
		:expect() :: interface_data

	if data.debounce:Get() then
		return
	end

	data.debounce:Set(true)

	task.delay(0.5, function()
		data.debounce:Set(false)
	end)

	local state = data.state

	state:Set(not state:Get())

	-- hide every other one
	for i, interface_data in pairs(display_order.tracked_interfaces) do
		if data == interface_data then
			return
		end

		interface_data.state:Set(false)
	end
end

function display_order:Watch()
	for i, interface_data in pairs(display_order.tracked_interfaces) do
		interface_data.state:Watch(function(newValue: boolean, oldValue: boolean)
			local canvas = interface_data.canvas

			if newValue then
				local scale = display_order._createScale(canvas)
				scale.Scale = 0

				canvas.Visible = true

				spr.target(scale, 0.8, 0.8, {
					Scale = 1,
				})
			else
				local scale = display_order._getScale(canvas)
				if not scale then
					return
				end

				spr.target(scale, 0.9, 0.6, {
					Scale = 0,
				})

				spr.completed(scale, function()
					promise.new(function()
						display_order._trove:Remove(scale)
					end)

					canvas.Visible = false
				end)
			end
		end)
	end
end

return display_order
