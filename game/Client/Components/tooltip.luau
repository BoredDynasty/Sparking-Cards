--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local input = require(ReplicatedStorage.Packages.input)
local spr = require(ReplicatedStorage.Modules.spr)

-- tooltip.luau
-- https://m3.material.io/components/tooltips/guidelines

local module = {}
module.tracking = {} :: { Tooltip }

local player = Players.LocalPlayer
local player_gui = player.PlayerGui

local mouse = input.Mouse.new()

local templates = ReplicatedStorage.Interfaces

local camera = workspace.CurrentCamera

local plain_pool = PoolerPlus:CreatePool("PlainTooltipPool", function()
	return templates.PlainTooltip:Clone()
end)

plain_pool:AdaptivePreload()

local active_tooltip = nil

type Tooltip = {
	object: GuiObject,
	text: string,
	actions: Actions?,
	gui_bounds: { [string]: Vector2 },
}

type Actions = {
	{
		name: string,
		fn: () -> (),
	}
}

function module.register(object: GuiObject, text: string, actions: Actions?)
	local gui_bounds = {
		size = object.AbsoluteSize,
		position = object.AbsolutePosition,
	}

	local data = {
		object = object,
		text = text,
		actions = actions,
		gui_bounds = gui_bounds,
	}

	table.insert(module.tracking, data)

	object.Destroying:Connect(function()
		task.spawn(module.unregister, object)
	end)
end

function module.unregister(object: GuiObject)
	for i, data in ipairs(module.tracking) do
		if data.object == object then
			table.remove(module.tracking, i)
		end
	end
end

local function clamp_tooltip_position(
	target_x: number,
	target_y: number,
	tooltip_width: number,
	tooltip_height: number,
	screen_size: Vector2,
	padding: number
): (number, number)
	local min_x = padding
	local max_x = screen_size.X - tooltip_width - padding
	local min_y = padding
	local max_y = screen_size.Y - tooltip_height - padding

	local clamped_x = math.clamp(target_x, min_x, max_x)
	local clamped_y = math.clamp(target_y, min_y, max_y)

	return clamped_x, clamped_y
end

function module:Start()
	local last_check: number = 0.0
	local check_interval = 1 / 60
	local last_postion = mouse:GetPosition()

	local screen_size = camera.ViewportSize

	local conn = nil

	conn = mouse.Moved:Connect(function(position: Vector2)
		last_check += RunService.Heartbeat:Wait()

		if last_check < check_interval then
			return
		end
		last_check = 0

		if last_postion and (position - last_postion).Magnitude < 1 then
			return
		end

		last_postion = position

		-- iterate the registered tooltips

		debug.profilebegin("tooltip_iter")

		for i, data in ipairs(module.tracking) do
			if active_tooltip ~= nil then
				return
			end

			local object = data.object

			local gui_bounds = data.gui_bounds

			local is_inside = bounds.inner(gui_bounds.position, gui_bounds.size, position)
			if not is_inside then
				continue
				-- continue iterating over the next piece of data.
			end

			local is_active = object:GetAttribute("TooltipActive") :: boolean
			if is_active then
				continue
				-- we are already handling this one; continue iteration.
			end

			object:SetAttribute("TooltipActive", true)
			active_tooltip = object

			-- render the tooltip.

			local tooltip_gui = plain_pool:Get() -- TODO) allow for both rich and plain tooltips.
			-- keep a 4dp distance between the target and tooltip.
			-- make sure the tooltip doesn't go past the screen bounds.

			local target_x = gui_bounds.position.X
				+ (gui_bounds.size.X / 2)
				- (tooltip_gui.AbsoluteSize.X / 2)
			local target_y = gui_bounds.position.Y - tooltip_gui.AbsoluteSize.Y + 10

			local padding = 4
			target_x, target_y = clamp_tooltip_position(
				target_x,
				target_y,
				tooltip_gui.AbsoluteSize.X,
				tooltip_gui.AbsoluteSize.Y,
				screen_size,
				padding
			)

			tooltip_gui.Text = data.text
			tooltip_gui.Parent = player_gui.Tooltip
			tooltip_gui.AnchorPoint = Vector2.zero

			-- before we set the position, we need to animate it!!!

			tooltip_gui.Position = UDim2.fromOffset(target_x, target_y + 10) -- below the target, with a 10 pixel offset for the animation
			tooltip_gui.Visible = true

			-- transparency effects

			tooltip_gui.TextTransparency = 1
			tooltip_gui.BackgroundTransparency = 1

			-- animate!!!
			spr.target(tooltip_gui, 0.73, 3.5, {
				Position = UDim2.fromOffset(target_x, target_y),
				TextTransparency = 0,
				BackgroundTransparency = 0,
			})

			-- after mouseleave, remove the tooltip.

			local leave_conn = nil

			local done = false -- this flag prevents further function execution.

			leave_conn = mouse.Moved:Connect(function(new_position: Vector2)
				if done then
					return
				end

				local is_inside = bounds.inner(gui_bounds.position, gui_bounds.size, new_position)
				if is_inside then
					return
				end

				-- mouse has left the target; remove the tooltip.

				-- the Material 3 guidelines state that we should wait 1.5s before removing.

				done = true

				task.wait(1.5)

				object:SetAttribute("TooltipActive", false)
				active_tooltip = nil

				spr.target(tooltip_gui, 0.73, 3.5, {
					Position = UDim2.fromOffset(target_x, target_y - 4),
					TextTransparency = 1,
					BackgroundTransparency = 1,
				})

				spr.completed(tooltip_gui, function()
					tooltip_gui.Visible = false
					plain_pool:Return(tooltip_gui)

					if leave_conn then
						leave_conn:Disconnect()
					end
				end)
			end)
		end

		debug.profileend()
	end)
end

return module
