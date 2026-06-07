--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local spr = require(ReplicatedStorage.Modules.spr)

-- tooltip.luau
-- https://m3.material.io/components/tooltips/guidelines

local module = {}

local registered_tooltips: { Tooltip } = {}

local player = Players.LocalPlayer
local player_gui = player.PlayerGui

local tooltip_container = player_gui.Tooltip

local templates = ReplicatedStorage.Interfaces

local camera = workspace.CurrentCamera

type Tooltip = {
	object: GuiObject,
	text: string,
	actions: Actions?,
	tooltip_gui: GuiObject?,
	hide_thread: thread?,
}

type Actions = {
	{
		name: string,
		fn: () -> (),
	}
}

local pool = PoolerPlus:CreatePool("TooltipPool", function()
	return templates.PlainTooltip:Clone()
end)

local function close_all_tooltips()
	for _, data in ipairs(registered_tooltips) do
		if data.tooltip_gui then
			local tooltip = data.tooltip_gui
			data.tooltip_gui = nil
			if data.hide_thread then
				task.cancel(data.hide_thread)
				data.hide_thread = nil
			end
			-- Animate out immediately
			spr.target(tooltip, 0.8, 4, {
				TextTransparency = 1,
				BackgroundTransparency = 1,
			})
			spr.completed(tooltip, function()
				tooltip.Visible = false
				pool:Return(tooltip)
			end)
		end
	end
end

local function position_tooltip(tooltip: GuiObject, object: GuiObject): UDim2
	local obj_pos = object.AbsolutePosition
	local obj_size = object.AbsoluteSize
	local tooltip_size = tooltip.AbsoluteSize
	local screen_size = camera.ViewportSize

	-- Try above first
	local x = obj_pos.X + obj_size.X / 2 - tooltip_size.X / 2
	local y_above = obj_pos.Y - tooltip_size.Y - 4

	if y_above >= 0 then
		-- Clamp to screen
		x = math.clamp(x, 4, screen_size.X - tooltip_size.X - 4)
		y_above = math.max(y_above, 4)
		return UDim2.fromOffset(x, y_above)
	else
		-- Try below
		local y_below = obj_pos.Y + obj_size.Y + 4
		if y_below + tooltip_size.Y <= screen_size.Y then
			x = math.clamp(x, 4, screen_size.X - tooltip_size.X - 4)
			return UDim2.fromOffset(x, y_below)
		else
			-- Fallback to above, clamped
			x = math.clamp(x, 4, screen_size.X - tooltip_size.X - 4)
			y_above = math.max(y_above, 4)
			return UDim2.fromOffset(x, y_above)
		end
	end
end

function module.new(object: GuiObject, text: string, actions: Actions?)
	-- Remove existing for this object

	for i, data in ipairs(registered_tooltips) do
		if data.object == object then
			if data.tooltip_gui then
				local tooltip = data.tooltip_gui
				data.tooltip_gui = nil

				if data.hide_thread then
					task.cancel(data.hide_thread)
					data.hide_thread = nil
				end

				spr.target(tooltip, 0.8, 4, {
					TextTransparency = 1,
					BackgroundTransparency = 1,
				})

				spr.completed(tooltip, function()
					tooltip.Visible = false
					pool:Return(tooltip)
				end)
			end

			table.remove(registered_tooltips, i)

			break
		end
	end

	local data: Tooltip = {
		object = object,
		text = text,
		actions = actions,
		tooltip_gui = nil,
		hide_thread = nil,
	}

	table.insert(registered_tooltips, data)

	-- Set up events
	object.MouseEnter:Connect(function()
		-- Close all other tooltips
		close_all_tooltips()

		-- Cancel any hide thread for this one
		if data.hide_thread then
			task.cancel(data.hide_thread)
			data.hide_thread = nil
		end

		-- Get tooltip from pool
		local tooltip = pool:Get()
		data.tooltip_gui = tooltip

		-- Set text
		if tooltip:IsA("TextLabel") or tooltip:IsA("TextButton") then
			tooltip.Text = text
		end

		-- Position
		local pos = position_tooltip(tooltip, object)
		tooltip.Position = pos
		tooltip.Parent = tooltip_container
		tooltip.Visible = true

		-- Animate in
		tooltip.TextTransparency = 1
		tooltip.BackgroundTransparency = 1
		spr.target(tooltip, 0.8, 4, {
			TextTransparency = 0,
			BackgroundTransparency = 0,
		})
	end)

	object.MouseLeave:Connect(function()
		if not data.tooltip_gui then
			return
		end

		-- Start hide timer
		data.hide_thread = task.delay(1.5, function()
			if data.tooltip_gui then
				local tooltip = data.tooltip_gui
				data.tooltip_gui = nil
				data.hide_thread = nil

				spr.target(tooltip, 0.8, 4, {
					TextTransparency = 1,
					BackgroundTransparency = 1,
				})
				spr.completed(tooltip, function()
					tooltip.Visible = false
					pool:Return(tooltip)
				end)
			end
		end)
	end)
end

return module
