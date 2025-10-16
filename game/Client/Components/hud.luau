--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local audio = require(ReplicatedStorage.Modules.audio)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)

-- hud.luau

local player = playerMarshaller.get()

local hud = {}
hud.buttons = {}

export type button = {
	name: string,
	callback: () -> (),
	icon: icon?,
	reactor: observer.Observer<boolean>,
	limit: ratelimit.Ratelimit<string>,
	hover_limit: ratelimit.Ratelimit<string>,
}

export type icon = {
	IconName: string, -- "icon-name"
	Id: number, -- 123456789
	Url: string, -- "rbxassetid://123456789"
	ImageRectSize: Vector2, -- Vector2.new(48, 48)
	ImageRectOffset: Vector2, -- Vector2.new(648, 266)
}

function hud:create(name: string, callback: () -> (), icon: icon)
	local button = {
		name = name,
		callback = callback,
		icon = icon,
		reactor = observer.new(false),
		limit = ratelimit.new(1, 0.5),
		hover_limit = ratelimit.new(1, 0.9),
	}
	table.insert(hud.buttons, button)
end

local function getOppositeReactorValue(reactor: observer.Observer<boolean>): boolean
	return not reactor:Get()
end

function hud:render()
	local hudContainer = player.PlayerGui:WaitForChild("Hud") :: ScreenGui
	local hudBackground = hudContainer:WaitForChild("Background") :: Frame
	for _, button in ipairs(hudContainer:GetChildren()) do
		local attribute = button:GetAttribute("NonDestroyable")
		if button:IsA("TextButton") and not attribute then
			button:Destroy() -- Clear existing buttons
		end
	end

	for _, button: button in pairs(hud.buttons) do
		print("Rendering button:", button.name)
		-- Here you would create the actual button UI element and connect the callback
		-- Instances:

		local icon = button.icon and button.icon.IconName or "file"

		local TextButton = Instance.new("TextButton")
		local UICorner = Instance.new("UICorner")
		local Icon = Instance.new("ImageLabel")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")

		--Properties:

		TextButton.Parent = hudBackground
		TextButton.Name = button.name
		TextButton.AnchorPoint = Vector2.new(0.5, 0.5)
		TextButton.BackgroundColor3 = Color3.fromHex("#1a110f")
		TextButton.BorderSizePixel = 0
		TextButton.Size = UDim2.fromScale(0.35, 0.7)
		TextButton.Font = Enum.Font.Gotham
		TextButton.TextColor3 = Color3.fromHex("ffb5a0")
		TextButton.TextSize = 14.000
		--[[
		if not button.icon then
			TextButton.Text = button.name
		else
			TextButton.Text = "" -- No text if an icon is provided
		end
		--]]

		if button.name then
			-- set icon adjacent to text:

			TextButton.Text = button.name
			-- get text bounds
			local text_bounds = TextButton.TextBounds
			local offset = 15

			Icon.Position = UDim2.new(0.5, text_bounds.X - offset, 0.5)
			Icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
		end

		UICorner.CornerRadius = UDim.new(1, 0)
		UICorner.Parent = TextButton

		Icon.Name = "Icon"
		Icon.Parent = TextButton
		Icon.AnchorPoint = Vector2.new(if button.name then 1 else 0.5, 0.5)
		Icon.BackgroundTransparency = 1
		Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		Icon.Size = UDim2.fromScale(0.40, 0.40)
		if not button.name then
			-- make the TextButton width smaller.
			TextButton.Size = UDim2.fromScale(0.2, 0.7)
		end

		local defaultIcon = promise
			.new(function(resolve: (icon) -> ...unknown, reject: (string) -> ...unknown)
				local ok, output = pcall(function()
					return lucide.GetAsset(icon, 256 * 2)
				end)

				if ok then
					resolve(output)
				else
					reject("Couldn't get lucide icon asset")
				end
			end)
			:catch(warn)
			:expect() :: icon

		if defaultIcon then
			Icon.ImageRectOffset = defaultIcon.ImageRectOffset
			Icon.ImageRectSize = defaultIcon.ImageRectSize
			Icon.Image = defaultIcon.Url

			UIAspectRatioConstraint.Parent = Icon
		else
			warn("Failed to fetch asset!")
		end

		TextButton.MouseButton1Click:Connect(function()
			if not button.limit(button.name) then
				return
			end

			local value = getOppositeReactorValue(button.reactor)

			button.reactor:Set(value)

			audio:SFX("click")
		end)

		TextButton.MouseEnter:Connect(function()
			if not button.hover_limit(button.name) then
				return
			end
			-- mouse hover effect
			spr.stop(TextButton, "Size")
			spr.target(TextButton, 0.8, 8, {
				BackgroundColor3 = Color3.fromHex("#342522"),
				Size = UDim2.fromScale(TextButton.Size.X.Scale * 1.1, TextButton.Size.Y.Scale * 1.1),
			})
			audio:SFX("hover")
		end)

		TextButton.MouseLeave:Connect(function()
			spr.stop(TextButton, "Size")
			spr.target(TextButton, 0.8, 8, {
				BackgroundColor3 = Color3.fromHex("#1a110f"),
				Size = UDim2.fromScale(TextButton.Size.X.Scale / 1.1, TextButton.Size.Y.Scale / 1.1),
			})
			audio:SFX("hover", {
				pitch = 0.8,
			})
		end)
		button.reactor:Watch(function(newValue: boolean)
			local oppositeValue = getOppositeReactorValue(button.reactor)
			print("Button state changed:", oppositeValue, "->", newValue)

			if button.callback then
				promise.new(button.callback):catch(warn)
			else
				warn("No callback defined for button:", button.name)
			end

			-- tilt the icon
			-- button size
			if newValue then
				spr.target(Icon, 0.8, 8, {
					Rotation = 15,
				})

				--ripple()
			else
				spr.target(Icon, 0.8, 8, {
					Rotation = 0,
				})
			end
		end)

		shadow(TextButton, Color3.new(), 0.5, 14)
	end
end

function hud:toggle(buttonName: string)
	local button: button? = nil

	if not hud.buttons then
		return
	end

	for _, b in pairs(hud.buttons) :: { button } do
		if b.name == buttonName then
			button = b
			break
		end
	end

	if button then
		button.reactor:Set(getOppositeReactorValue(button.reactor))
	end
end

function hud:clear()
	for i, btn in pairs(hud.buttons) do
		btn.reactor:Destroy()

		if btn.limit.count_map[btn.name] then
			btn.limit.count_map[btn.name] = nil
		end

		if btn.hover_limit.count_map[btn.name] then
			btn.hover_limit.count_map[btn.name] = nil
		end

		hud.buttons[i] = nil
	end

	table.clear(hud.buttons) -- just to make sure we don't keep any references

	local hudContainer = player.PlayerGui:WaitForChild("Hud") :: ScreenGui

	for _, button in ipairs(hudContainer:GetChildren()) do
		if button:IsA("TextButton") then
			button:Destroy() -- Clear existing buttons
		end
	end
end

function hud:hide()
	local hudContainer = player.PlayerGui:WaitForChild("Hud") :: ScreenGui
	hudContainer.Enabled = false
end
function hud:show()
	local hudContainer = player.PlayerGui:WaitForChild("Hud") :: ScreenGui
	hudContainer.Enabled = true
end

return hud
