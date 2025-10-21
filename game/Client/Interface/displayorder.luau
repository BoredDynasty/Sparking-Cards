--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local custom_lighting = require(ReplicatedStorage.ClientModules["custom-lighting"])
local input = require(ReplicatedStorage.Packages.input)
local observer = require(ReplicatedStorage.Utility.observer)
local promise = require(ReplicatedStorage.Packages.promise)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- displayorder.luau

local display_order = {
	tracked_interfaces = {},
	_trove = trove.new(),
	_mouse = input.Mouse.new(),
}

export type interface_data = {
	identifier: string,
	state: observer.Observer<boolean>,
	canvas: CanvasGroup,
	debounce: observer.Observer<boolean>,
	bounds: {
		position: Vector2,
		size: Vector2,
	},
}

function display_order._createScale(ancestor: Instance?)
	local scale = display_order._trove:Construct(
		Instance,
		"UIScale",
		if ancestor then ancestor else ReplicatedStorage
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

function display_order.new(canvas: CanvasGroup, position: Vector2?, size: Vector2?)
	local identifier = canvas:GetFullName()

	if not position or not size then
		local frame = canvas:FindFirstChild("Frame") or canvas:FindFirstChildOfClass("Frame")
		-- i dont usually name my layers sooooo...
		if not frame then
			-- thats odd, lmao
			return
		end

		position = frame.AbsolutePosition
		size = frame.AbsoluteSize
	end

	display_order.tracked_interfaces[identifier] = {
		identifier = identifier,
		state = observer.new(false),
		canvas = canvas,
		debounce = observer.new(false),
		bounds = {
			position = position,
			size = size,
		},
		connections = {} :: { SignalPlus.Connection },
	}

	canvas.Destroying:Once(function()
		local data = display_order.tracked_interfaces[identifier]

		for i, conn in pairs(data.connections) do
			conn:Disconnect()
		end

		display_order.tracked_interfaces[identifier].state:Destroy()
		display_order.tracked_interfaces[identifier].debounce:Destroy()

		table.clear(display_order.tracked_interfaces[identifier])

		display_order.tracked_interfaces[identifier] = nil
	end)

	return display_order.tracked_interfaces[identifier]
end

function display_order:toggle(canvas: CanvasGroup)
	local identifier = canvas:GetFullName()

	local data = promise
		.new(function(resolve)
			resolve(display_order.tracked_interfaces[identifier])
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
				-- visible

				local scale = display_order._createScale(canvas)
				scale.Scale = 0

				canvas.Visible = true

				spr.target(scale, 0.8, 1.5, {
					Scale = 1,
				})

				custom_lighting.blur()
			else
				local scale = display_order._getScale(canvas)
				if not scale then
					return
				end

				spr.target(scale, 0.9, 1, {
					Scale = 0,
				})

				spr.completed(scale, function()
					promise.new(function()
						display_order._trove:Remove(scale)
					end)

					canvas.Visible = false
				end)

				custom_lighting.unblur()
			end
		end)

		local conn = (display_order._mouse.LeftDown :: RBXScriptSignal):Connect(function()
			local mousePos = display_order._mouse:GetPosition()

			if bounds.outer(interface_data.bounds.position, interface_data.bounds.size, mousePos) then
				interface_data.state:Set(false)
			end
		end)

		table.insert(interface_data.connections, conn)
	end
end

return display_order
