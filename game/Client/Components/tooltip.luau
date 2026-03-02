--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local input = require(ReplicatedStorage.Packages.input)
local spr = require(ReplicatedStorage.Modules.spr)

-- tooltip.luau
-- https://m3.material.io/components/tooltips/guidelines

local module = {}
module.tracking = {} :: { Tooltip }

local player = Players.LocalPlayer
local player_gui = player.PlayerGui

-- ensure the Tooltip ScreenGui is available
local tooltip_container = player_gui:WaitForChild("Tooltip") :: ScreenGui

local mouse = input.Mouse.new()

local templates = ReplicatedStorage:WaitForChild("Interfaces")

local camera = workspace.CurrentCamera

local active_tooltip = nil

type Tooltip = {
	object: GuiObject,
	text: string,
	actions: Actions?,
}

type Actions = {
	{
		name: string,
		fn: () -> (),
	}
}

function module.register(object: GuiObject, text: string, actions: Actions?)
	local data = {
		object = object,
		text = text,
		actions = actions,
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
	for i, data in ipairs(module.tracking) do
		local object = data.object
		local tooltip_gui = nil :: TextButton?

		object.MouseEnter:Connect(function()
			if tooltip_gui then
				return
			end

			local gui_bounds = {
				size = object.AbsoluteSize,
				position = object.AbsolutePosition,
			}

			tooltip_gui = templates.PlainTooltip:Clone()
			assert(tooltip_gui, "huh?")

			local target_x = gui_bounds.position.X
				+ (gui_bounds.size.X / 2)
				- (tooltip_gui.AbsoluteSize.X / 2)
			local target_y = gui_bounds.position.Y - tooltip_gui.AbsoluteSize.Y - 4

			local padding = 4
			target_x, target_y = clamp_tooltip_position(
				target_x,
				target_y,
				tooltip_gui.AbsoluteSize.X,
				tooltip_gui.AbsoluteSize.Y,
				camera.ViewportSize,
				padding
			)

			tooltip_gui.Text = data.text
			tooltip_gui.Parent = tooltip_container

			tooltip_gui.Position = UDim2.fromOffset(target_x, target_y - 4)
			tooltip_gui.Visible = true

			tooltip_gui.TextTransparency = 1
			tooltip_gui.BackgroundTransparency = 1

			spr.target(tooltip_gui, 0.73, 3.5, {
				Position = UDim2.fromOffset(target_x, target_y),
				TextTransparency = 0,
				BackgroundTransparency = 0,
			})
		end)

		object.MouseLeave:Connect(function()
			if not tooltip_gui then
				return
			end

			task.wait(1.5)

			local target_x = tooltip_gui.Position.X.Offset
			local target_y = tooltip_gui.Position.Y.Offset

			spr.target(tooltip_gui, 0.73, 3.5, {
				Position = UDim2.fromOffset(target_x, target_y - 4),
				TextTransparency = 1,
				BackgroundTransparency = 1,
			})

			spr.completed(tooltip_gui, function()
				tooltip_gui.Visible = false
				tooltip_gui:Destroy()
				tooltip_gui = nil
			end)
		end)
	end
end

return module
