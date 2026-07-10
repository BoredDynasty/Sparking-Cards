--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local bounds = require(ReplicatedStorage.ClientModules.Utilities.bounds)
local future = require(ReplicatedStorage.Packages.future)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local promise = require(ReplicatedStorage.Packages.promise)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require(ReplicatedStorage.ClientModules.Interface.ripple)
local screen_3d = require(ReplicatedStorage.ClientModules.Interface["screen-3d"])
local shadow = require(ReplicatedStorage.ClientModules.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local state_machine = require(ReplicatedStorage.Utility["state-machine"])
local sway = require(ReplicatedStorage.ClientModules.Interface.sway)
local tooltip = require(ReplicatedStorage.ClientModules.Components.tooltip)
const pop = require(ReplicatedStorage.ClientModules.Interface.pop)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local wiggle = require(ReplicatedStorage.ClientModules.Interface.wiggle)

-- hud.luau

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local hud_container = player.PlayerGui.Hud
local hud_background = hud_container.Background

hud_background.Position = UDim2.fromScale(0.52, 0.87)

local module = {}
module.buttons = {} :: { Button }

local pool = PoolerPlus:CreatePool("HudPool", function()
	local templates = ReplicatedStorage.Interfaces

	return templates.HudButton:Clone()
end)

type Button = {
	name: string,
	callback: () -> (),
	icon: typemarshaller.LucideIcon,
	limit: ratelimit.Ratelimit<any>,
	text_button: typeof(pool:Get()),
	is_large: boolean,
}

function module.new(name: string, callback: () -> (), icon: typemarshaller.LucideIcon, is_large: boolean)
	local btn = pool:Get()

	local tbl: Button = {
		name = name,
		callback = callback,
		icon = icon,
		limit = ratelimit(1, 1.5) :: ratelimit.Ratelimit<any>,
		text_button = pool:Get(),
		is_large = is_large,
	}

	table.insert(module.buttons, tbl)

	return tbl
end

function module:Render()
	module:Clear()

	-- sort the table from how big the buttons are
	-- smallest to biggest

	table.sort(module.buttons, function(a: Button, b: Button)
		return (a.is_large and 1 or 0) < (b.is_large and 1 or 0)
	end)

	for i, button: Button in ipairs(module.buttons) do
		local icon = button.icon and button.icon.IconName or "file"

		local text_button = button.text_button
		local ui_corner = text_button.UICorner
		local icon_image = text_button.ImageLabel

		text_button.Name = button.name

		text_button.AutoButtonColor = false

		icon_image.Position = UDim2.fromScale(0.5, 0.5)
		icon_image.AnchorPoint = Vector2.one / 2

		local default_corner = UDim.new(0.238, 0)

		if button.is_large then
			-- make the TextButton width larger.
			text_button.Size = UDim2.fromScale(0.077, 1.036)
			text_button.AspectRatio.AspectRatio = 1.513
			text_button.AspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
			text_button.AspectRatio.DominantAxis = Enum.DominantAxis.Width
		end

		task.spawn(function()
			local default_icon = lucide.GetAsset(icon)

			if default_icon then
				icon_image.ImageRectOffset = default_icon.ImageRectOffset
				icon_image.ImageRectSize = default_icon.ImageRectSize
				icon_image.Image = default_icon.Url
			else
				warn("Failed to fetch asset!")
			end
		end)

		local default_size = text_button.Size
		local default_color = text_button.BackgroundColor3

		-- the color of the button, but more *juicy*
		local contrast_color = Color3.fromRGB(
			math.clamp(default_color.R * 1.2, 0, 1),
			math.clamp(default_color.G * 1.2, 0, 1),
			math.clamp(default_color.B * 1.2, 0, 1)
		)

		text_button.Activated:Connect(function()
			if not button.limit() then
				print("Button", button.name, "is on cooldown.")
				return
			end

			button.callback()

			-- lets do some fun effects here.
			-- pop the size of the button and then shrink it back down to normal size.
			pop(text_button, 1.2)
			ripple(text_button, 0.9)
			audio:PlaySFX("click")
			--[[
			spr.target(text_button, 0.2, 1.5, {
				BackgroundColor3 = contrast_color,
			})
				--]]
		end)

		-- dynamic shadow transparency based on button index, so that buttons further down the list have a more transparent shadow, to create a sense of depth.
		shadow(text_button, Color3.new(), 0.5 + (i * 0.05), 16, 1, 1)

		text_button.Parent = hud_container
	end
end

function module:Clear()
	for _, button in ipairs(hud_container:GetChildren()) do
		local attribute = button:GetAttribute("NonDestroyable")
		if button:IsA("TextButton") and not attribute then
			button:Destroy() -- Clear existing buttons
		end
	end
end

function module:Destroy()
	for _, button in ipairs(module.buttons) do
		pool:Return(button.text_button)
	end
end


local ui_scale = Instance.new("UIScale")
ui_scale.Parent = hud_container
ui_scale.Scale = 1

function module:Hide()
	spr.stop(ui_scale)
	spr.stop(hud_background, "Position")

	spr.target(ui_scale, 0.4, 1.5, {
		Scale = 1.25,
	})

	spr.target(hud_background, 0.5, 0.8, {
		Position = UDim2.fromScale(0.5, 2),
	})

	spr.completed(hud_background, function()
		hud_background.Visible = false
	end)
end

function module:Show()
	hud_container.Enabled = true
	hud_background.Position = UDim2.fromScale(0.5, 2)

	ui_scale.Scale = 1.25
	spr.stop(ui_scale)
	spr.target(ui_scale, 0.5, 1.5, {
		Scale = 1,
	})

	spr.stop(hud_background)
	spr.target(hud_background, 0.8, 3.5, {
		Position = UDim2.fromScale(0.5, 0.922),
	})
end

return module