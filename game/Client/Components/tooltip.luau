--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
print(1)
local spr = require(ReplicatedStorage.Modules.spr)

-- tooltip.luau
-- https://m3.material.io/components/tooltips/guidelines

local module = {}
module.tracking = {} :: { Tooltip }
print(1)

local player = Players.LocalPlayer
local player_gui = player.PlayerGui
print(1)

local tooltip_container = player_gui.Tooltip
print(1)

local templates = ReplicatedStorage.Interfaces
print(1)

local camera = workspace.CurrentCamera
print(1)

type Tooltip = {
	object: GuiObject,
	text: string,
	actions: Actions?,
}
print(1)

type Actions = {
	{
		name: string,
		fn: () -> (),
	}
}
print(1)

function module.register(object: GuiObject, text: string, actions: Actions?)
	local data = {
		object = object,
		text = text,
		actions = actions,
	}
	print(1)

	table.insert(module.tracking, data)
	--[[
	object.Destroying:Connect(function()
		module.unregister(object)
	end)
	--]]
	print(1)
end
print(1)

function module.unregister(object: GuiObject)
	print(1)

	for i, data in ipairs(module.tracking) do
		if data.object == object then
			table.remove(module.tracking, i)
			print(1)
		end
	end
	print(1)
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
			print(1)
			if tooltip_gui then
				return
			end
			print(2)

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
			print(3)

			local padding = 4
			target_x, target_y = clamp_tooltip_position(
				target_x,
				target_y,
				tooltip_gui.AbsoluteSize.X,
				tooltip_gui.AbsoluteSize.Y,
				camera.ViewportSize,
				padding
			)
			print(4)

			tooltip_gui.Text = data.text
			tooltip_gui.Parent = tooltip_container
			print(5)

			tooltip_gui.Position = UDim2.fromOffset(target_x, target_y - 4)
			tooltip_gui.Visible = true
			print(6)

			tooltip_gui.TextTransparency = 1
			tooltip_gui.BackgroundTransparency = 1
			print(7)

			spr.target(tooltip_gui, 0.73, 3.5, {
				Position = UDim2.fromOffset(target_x, target_y),
				TextTransparency = 0,
				BackgroundTransparency = 0,
			})
			print(8)
		end)

		object.MouseLeave:Connect(function()
			print(9)
			if not tooltip_gui then
				return
			end
			print(10)

			task.wait(1.5)

			local target_x = tooltip_gui.Position.X.Offset
			local target_y = tooltip_gui.Position.Y.Offset

			print(11)

			spr.target(tooltip_gui, 0.73, 3.5, {
				Position = UDim2.fromOffset(target_x, target_y - 4),
				TextTransparency = 1,
				BackgroundTransparency = 1,
			})

			print(12)

			spr.completed(tooltip_gui, function()
				tooltip_gui.Visible = false
				tooltip_gui:Destroy()
				tooltip_gui = nil
			end)

			print(13)
		end)
	end
end

return module
