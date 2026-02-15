--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local future = require(ReplicatedStorage.Packages.future)
local input = require(ReplicatedStorage.Packages.input)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

-- hud.luau

local player = Players.LocalPlayer

local module = {}
module.buttons = {} :: { Button }

local global_ratelimit = ratelimit(1, 2.5)

local pool = PoolerPlus:CreatePool("HudPool", function()
	local templates = ReplicatedStorage.Interfaces

	return templates.HudButton:Clone()
end)

local mouse = input.Mouse.new()

pool:AdaptivePreload()

export type Button = {
	name: string,
	callback: () -> (),
	icon: typemarshaller.LucideIcon,
	reactor: observer.Observer<boolean>,
	limit: ratelimit.Ratelimit<string>,
	hover_limit: ratelimit.Ratelimit<string>,
	text_button: typeof(pool:Get()),
	is_large: boolean,
}

function module.new(name: string, callback: () -> (), icon: typemarshaller.LucideIcon, is_large: boolean)
	local button = {
		name = name,
		callback = callback,
		icon = icon,
		reactor = observer.new(false) :: observer.Observer<boolean>,
		limit = ratelimit(1, 0.5) :: ratelimit.Ratelimit<string>,
		hover_limit = ratelimit(1, 0.9) :: ratelimit.Ratelimit<string>,
		text_button = pool:Get(),
		is_large = is_large,
	}

	table.insert(module.buttons, button)
end

local hud_container = player.PlayerGui.Hud
local hud_background = hud_container.Background

function module:Render()
	for _, button in ipairs(hud_container:GetChildren()) do
		local attribute = button:GetAttribute("NonDestroyable")
		if button:IsA("TextButton") and not attribute then
			button:Destroy() -- Clear existing buttons
		end
	end

	-- sort the table from how big the buttons are
	-- smallest to biggest

	table.sort(module.buttons, function(a: Button, b: Button)
		return (a.is_large and 1 or 0) < (b.is_large and 1 or 0)
	end)

	for _, button: Button in ipairs(module.buttons) do
		--print("Rendering button:", button.name)
		-- Here you would create the actual button UI element and connect the callback
		-- Instances:

		local icon = button.icon and button.icon.IconName or "file"

		local text_button = button.text_button
		local ui_corner = text_button.UICorner
		local icon_image = text_button.ImageLabel

		--Properties:

		text_button.Parent = hud_background
		text_button.Name = button.name

		text_button.AutoButtonColor = false

		icon_image.Position = UDim2.fromScale(0.5, 0.5)
		icon_image.AnchorPoint = Vector2.one / 2

		local default_corner = ui_corner.CornerRadius

		task.spawn(function()
			if button.is_large then
				-- make the TextButton width larger.
				text_button.Size = UDim2.fromScale(0.077, 1.036)
			end
		end)

		task.spawn(function()
			local ok, default_icon = future.Try(lucide.GetAsset, icon, 256 * 2):Await()

			if ok then
				icon_image.ImageRectOffset = default_icon.ImageRectOffset
				icon_image.ImageRectSize = default_icon.ImageRectSize
				icon_image.Image = default_icon.Url
			else
				warn("Failed to fetch asset!")
			end
		end)

		text_button.MouseButton1Click:Connect(function()
			if not button.limit(button.name) or not global_ratelimit() then
				return
			end

			button.reactor:Map(function(current)
				return not current
			end)
		end)

		local default_size = text_button.Size
		local default_color = text_button.BackgroundColor3

		local lighter_color = default_color:Lerp(Color3.new(1, 1, 1), 0.2)

		text_button.MouseEnter:Connect(function()
			if not button.hover_limit(button.name) then
				return
			end

			wiggle(icon_image)

			-- mouse hover effect
			spr.stop(text_button, "Size")
			spr.stop(text_button, "BackgroundColor3")
			spr.target(text_button, 0.8, 8, {
				BackgroundColor3 = lighter_color,
			})
			audio:PlaySFX("hover")
		end)

		text_button.MouseLeave:Connect(function()
			spr.stop(text_button, "Size")
			spr.stop(text_button, "BackgroundColor3")
			spr.target(text_button, 0.8, 8, {
				BackgroundColor3 = default_color,
			})
			audio:PlaySFX("leave")
		end)

		mouse.LeftDown:Connect(function()
			local size, position = text_button.AbsoluteSize, text_button.AbsolutePosition
			local is_within_button = bounds.inner(position, size, mouse:GetPosition())

			--print("inner: ", is_within_button)

			if not is_within_button then
				return
			end

			-- "pop" the UICorner
			-- "pop" the horizontal size of the button a bit
			-- darken the color of the button a bit

			spr.stop(ui_corner)
			spr.target(ui_corner, 0.3, 8, {
				CornerRadius = UDim.new(1 / 8, 0), -- 0.125
			})

			spr.stop(text_button, "BackgroundColor3")
			spr.stop(text_button, "Size")
			spr.target(text_button, 0.3, 8, {
				Size = default_size + UDim2.fromOffset(10, 0),
				BackgroundColor3 = default_color:Lerp(Color3.new(0, 0, 0), 0.2),
			})
		end)

		mouse.LeftUp:Connect(function()
			local size, position = text_button.AbsoluteSize, text_button.AbsolutePosition
			local is_within_button = bounds.inner(position, size, mouse:GetPosition())

			--print("inner: ", is_within_button)

			if not is_within_button then
				return
			end

			-- revert the "pop" of the UICorner and button size
			-- and the color of the button

			spr.stop(ui_corner)
			spr.target(ui_corner, 0.3, 8, {
				CornerRadius = default_corner,
			})

			spr.stop(text_button, "Size")
			spr.stop(text_button, "BackgroundColor3")
			spr.target(text_button, 0.3, 8, {
				Size = default_size,
				BackgroundColor3 = default_color,
			})
		end)

		button.reactor:Watch(function(newValue: boolean)
			if button.callback then
				task.spawn(future.Try, button.callback)
			else
				warn("No callback defined for button: ", button.name)
			end

			audio:PlaySFX("click")

			-- tilt the icon
			-- button size
			if newValue then
				spr.stop(icon_image)
				spr.target(icon_image, 0.35, 8, {
					Rotation = 15,
				})
			else
				spr.stop(icon_image)
				spr.target(icon_image, 0.35, 8, {
					Rotation = 0,
				})
			end
		end)

		shadow(text_button, Color3.new(), 0.5)
	end
end

function module:Toggle(buttonName: string)
	local button: Button? = nil

	if not module.buttons then
		return
	end

	for _, b in ipairs(module.buttons :: { Button }) do
		if b.name == buttonName then
			button = b
			break
		end
	end

	if button then
		button.reactor:Map(function(current)
			return not current
		end)
	end
end

function module:Clear()
	for i, btn in pairs(module.buttons) do
		btn.reactor:Destroy()

		if btn.limit.count_map[btn.name] then
			btn.limit.count_map[btn.name] = nil
		end

		if btn.hover_limit.count_map[btn.name] then
			btn.hover_limit.count_map[btn.name] = nil
		end

		module.buttons[i] = nil
	end

	for _, button in ipairs(hud_container:GetChildren()) do
		if button:IsA("TextButton") then
			button:Destroy() -- Clear existing buttons
		end
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
		Position = UDim2.fromScale(0.472, 2),
	})

	spr.completed(hud_background, function()
		hud_background.Visible = false
	end)
end

function module:Show()
	hud_container.Enabled = true
	hud_background.Position = UDim2.fromScale(0.472, 2)

	ui_scale.Scale = 1.25
	spr.stop(ui_scale)
	spr.target(ui_scale, 0.5, 1.5, {
		Scale = 1,
	})

	spr.stop(hud_background)
	spr.target(hud_background, 0.8, 3.5, {
		Position = UDim2.fromScale(0.472, 0.922),
	})
end

function module:IsVisible()
	return hud_background.Visible
end

return module
