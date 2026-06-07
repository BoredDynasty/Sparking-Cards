--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local _bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local _future = require(ReplicatedStorage.Packages.future)
local _sway = require(StarterPlayer.StarterPlayerScripts.Interface.sway)
local _tooltip = require(StarterPlayer.StarterPlayerScripts.Components.tooltip)
local _wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)
local audio = require(ReplicatedStorage.Modules.audio)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local promise = require(ReplicatedStorage.Packages.promise)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local screen_3d = require(StarterPlayer.StarterPlayerScripts.Interface["screen-3d"])
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local state_machine = require(ReplicatedStorage.Utility["state-machine"])
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- hud.luau

local player = Players.LocalPlayer

local module = {}
module.buttons = {} :: { Button }
module.horizontal_position = state_machine.new()

local states = {
	"left",
	"right",
	"center",
}

for i, state in ipairs(states) do
	module.horizontal_position:RegisterState(state)
end

module.horizontal_position:Set("left")

module.active_button = nil :: Button?
module.is_processing = false

local global_ratelimit = ratelimit(1, 3.3) :: ratelimit.Ratelimit<string>

local pool = PoolerPlus:CreatePool("HudPool", function()
	local templates = ReplicatedStorage.Interfaces

	return templates.HudButton:Clone()
end)

pool:Preload(15)

export type Button = {
	name: string,
	callback: () -> (),
	icon: typemarshaller.LucideIcon,
	reactor: observer.Observer<boolean>,
	limit: ratelimit.Ratelimit<string>,
	hover_limit: ratelimit.Ratelimit<string>,
	text_button: typeof(pool:Get())?,
	is_large: boolean,
	initialized: boolean,
	default_size: UDim2,
	default_color: Color3,
	default_corner: UDim,
	default_aspect_ratio: number,
	default_aspect_type: Enum.AspectType,
	default_dominant_axis: Enum.DominantAxis,
}

function module.new(name: string, callback: () -> (), icon: typemarshaller.LucideIcon, is_large: boolean)
	local text_button = pool:Get()

	local button = {
		name = name,
		callback = callback,
		icon = icon,
		reactor = observer.new(false) :: observer.Observer<boolean>,
		limit = ratelimit(1, 3.5) :: ratelimit.Ratelimit<string>,
		hover_limit = ratelimit(3, 0.9) :: ratelimit.Ratelimit<string>,
		text_button = text_button,
		is_large = is_large,
		initialized = false,
		default_size = text_button.Size,
		default_color = text_button.BackgroundColor3,
		default_corner = text_button.UICorner and text_button.UICorner.CornerRadius or UDim.new(0.238, 0),
		default_aspect_ratio = text_button.AspectRatio.AspectRatio,
		default_aspect_type = text_button.AspectRatio.AspectType,
		default_dominant_axis = text_button.AspectRatio.DominantAxis,
	} :: Button

	table.insert(module.buttons, button)
end

local hud_container = player.PlayerGui.Hud
local hud_background = hud_container.Background

hud_background.Position = UDim2.fromScale(0.52, 0.87)

local screen3d = screen_3d.new(hud_container, 5)
local component3d = screen3d:GetComponent3D(hud_background)
component3d:Enable()

component3d.offset = CFrame.Angles(0, math.rad(7), 0) -- rotates 3D UI element 7 degrees on the Y axis to give a slight perspective effect

function module:Render()
	local active_buttons = {} :: { [Instance]: boolean }

	for _, button in ipairs(module.buttons) do
		active_buttons[button.text_button] = true
	end

	for _, child in ipairs(hud_background:GetChildren()) do
		if child:IsA("TextButton") and not active_buttons[child] then
			child:Destroy()
		end
	end

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

		text_button.Parent = hud_background
		text_button.Name = button.name
		text_button.LayoutOrder = i
		text_button.AutoButtonColor = false

		text_button.Size = if button.is_large then UDim2.fromScale(0.077, 1.036) else button.default_size

		if button.is_large then
			text_button.AspectRatio.AspectRatio = 1.513
			text_button.AspectRatio.AspectType = Enum.AspectType.FitWithinMaxSize
			text_button.AspectRatio.DominantAxis = Enum.DominantAxis.Width
		else
			text_button.AspectRatio.AspectRatio = button.default_aspect_ratio
			text_button.AspectRatio.AspectType = button.default_aspect_type
			text_button.AspectRatio.DominantAxis = button.default_dominant_axis
		end

		icon_image.Position = UDim2.fromScale(0.5, 0.5)
		icon_image.AnchorPoint = Vector2.one / 2

		local default_corner = button.default_corner
		local default_size = text_button.Size
		local default_color = button.default_color
		local lighter_color = default_color:Lerp(Color3.new(1, 1, 1), 0.2)

		if not button.initialized then
			button.initialized = true

			text_button.Activated:Connect(function()
				if module.is_processing then
					audio:PlaySFX("cancel")
					return
				end

				button.reactor:Set(not button.reactor:Get())
			end)

			text_button.MouseButton1Up:Connect(function()
				if button.reactor:Get() then
					audio:PlaySFX("cancel")
					return
				end

				spr.stop(ui_corner)
				spr.target(ui_corner, 0.7, 4.9, {
					CornerRadius = default_corner,
				})

				spr.stop(icon_image, "Rotation")
				spr.target(icon_image, 0.35, 8, {
					Rotation = 0,
				})

				spr.stop(text_button, "Size")
				spr.stop(text_button, "BackgroundColor3")
				spr.target(text_button, 0.7, 6, {
					Size = default_size,
					BackgroundColor3 = default_color,
				})
			end)

			text_button.MouseEnter:Connect(function()
				if not button.hover_limit(button.name) then
					audio:PlaySFX("cancel")
					return
				end

				if button.reactor:Get() then
					audio:PlaySFX("cancel")
					return
				end

				spr.stop(icon_image, "Rotation")
				spr.target(icon_image, 0.35, 8, {
					Rotation = 15,
				})

				spr.stop(text_button, "Size")
				spr.stop(text_button, "BackgroundColor3")
				spr.target(text_button, 0.8, 8, {
					BackgroundColor3 = lighter_color,
				})
				audio:PlaySFX("hover")
			end)

			text_button.MouseLeave:Connect(function()
				if button.reactor:Get() then
					audio:PlaySFX("cancel")
					return
				end

				spr.stop(icon_image, "Rotation")
				spr.target(icon_image, 0.35, 8, {
					Rotation = 0,
				})

				spr.stop(text_button, "Size")
				spr.stop(text_button, "BackgroundColor3")
				spr.target(text_button, 0.8, 8, {
					BackgroundColor3 = default_color,
				})
				audio:PlaySFX("leave")
			end)

			button.reactor:Watch(function(current, _)
				if current then
					if module.is_processing or not button.limit(button.name) or not global_ratelimit() then
						audio:PlaySFX("cancel")
						button.reactor:Set(false)
						return
					end

					if module.active_button and module.active_button ~= button then
						module.active_button.reactor:Set(false)
					end

					module.active_button = button
					module.is_processing = true

					spr.stop(ui_corner)
					spr.target(ui_corner, 0.7, 4.9, {
						CornerRadius = UDim.new(1 / 8, 0),
					})

					spr.stop(icon_image, "Rotation")
					spr.target(icon_image, 0.35, 8, {
						Rotation = 15,
					})

					spr.stop(text_button, "BackgroundColor3")
					spr.stop(text_button, "Size")
					spr.target(text_button, 0.7, 5, {
						Size = default_size + UDim2.fromOffset(10, 10),
						BackgroundColor3 = default_color:Lerp(Color3.new(0, 0, 0), 0.2),
					})

					ripple(text_button, 0.9)

					audio:PlaySFX("click")

					local function complete()
						module.is_processing = false

						if module.active_button == button then
							module.active_button = nil
						end
					end

					local success, callback_result = pcall(button.callback)
					if not success then
						warn("Hud button callback error:", callback_result)
						complete()
					else
						local promise_candidate = callback_result :: any
						if promise.is(promise_candidate) then
							promise_candidate:andThen(complete, function(err)
								warn("Hud button callback promise failed:", err)
								complete()
							end)
						else
							complete()
						end
					end
				else
					spr.stop(ui_corner)
					spr.target(ui_corner, 0.7, 4.9, {
						CornerRadius = default_corner,
					})

					spr.stop(icon_image, "Rotation")
					spr.target(icon_image, 0.35, 8, {
						Rotation = 0,
					})

					spr.stop(text_button, "Size")
					spr.stop(text_button, "BackgroundColor3")
					spr.target(text_button, 0.7, 6, {
						Size = default_size,
						BackgroundColor3 = default_color,
					})
				end
			end)
		end

		task.defer(function()
			local default_icon = lucide.GetAsset(icon)

			if default_icon then
				icon_image.ImageRectOffset = default_icon.ImageRectOffset
				icon_image.ImageRectSize = default_icon.ImageRectSize
				icon_image.Image = default_icon.Url
			else
				warn("Failed to fetch asset!")
			end
		end)

		if not text_button:FindFirstChild("ShadowLayers") then
			shadow(text_button, Color3.new(), 0.5 + (i * 0.05), 16, 1, 1)
		end
	end
end

function module:Toggle(buttonName: string)
	if module.is_processing then
		return
	end

	local button: Button? = nil
	for _, b in ipairs(module.buttons :: { Button }) do
		if b.name == buttonName then
			button = b
			break
		end
	end

	if button then
		if button.reactor:Get() then
			button.reactor:Set(false)
		else
			if module.active_button and module.active_button ~= button then
				module.active_button.reactor:Set(false)
			end
			button.reactor:Set(true)
		end
	end
end

function module:Clear()
	for i = #module.buttons, 1, -1 do
		local btn = module.buttons[i]

		if btn.reactor then
			btn.reactor:Destroy()
		end

		if btn.text_button then
			btn.text_button.Parent = nil
			pool:Return(btn.text_button)
			btn.text_button = nil
		end

		if btn.limit.count_map[btn.name] then
			btn.limit.count_map[btn.name] = nil
		end

		if btn.hover_limit.count_map[btn.name] then
			btn.hover_limit.count_map[btn.name] = nil
		end

		table.remove(module.buttons, i)
	end

	module.active_button = nil
	module.is_processing = false
end

function module:GetHorizontalAlignment()
	if module.horizontal_position:Get() == "left" then
		return Enum.HorizontalAlignment.Left
	elseif module.horizontal_position:Get() == "right" then
		return Enum.HorizontalAlignment.Right
	else
		return Enum.HorizontalAlignment.Center
	end
end

local ui_scale = Instance.new("UIScale")
ui_scale.Parent = hud_container
ui_scale.Scale = 1

function module:Hide()
	spr.stop(ui_scale)
	spr.stop(hud_background, "Position")

	module:SetAlignment("left")

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

	module:SetAlignment("left")

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

function module:SetAlignment(state: "left" | "right" | "center")
	-- sadly, we cannot animate this.

	module.horizontal_position:Set(state)

	local alignment = module:GetHorizontalAlignment()

	hud_background.UIListLayout.HorizontalAlignment = alignment
end

function module:IsVisible()
	return hud_background.Visible
end

return module
