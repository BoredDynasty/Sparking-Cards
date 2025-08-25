--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local hint = require(ReplicatedStorage.ClientModules.Hint)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)

-- hud.luau

local player = playerMarshaller.get()

local hud = {
	buttons = {},
}

export type button = {
	name: string,
	callback: () -> (),
	icon: icon?,
	reactor: observer.Observer<string>,
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
		reactor = observer.new("open"),
	}
	table.insert(hud.buttons, button)
end

local function getOppositeReactorValue(reactor: observer.Observer<string>): string
	return reactor:Get() == "open" and "close" or "open"
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
	for _, button in pairs(hud.buttons) :: { button } do
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
		TextButton.BackgroundColor3 = Color3.fromRGB(143, 76, 56)
		TextButton.BorderSizePixel = 0
		TextButton.Size = UDim2.fromScale(0.35, 0.7)
		TextButton.Font = Enum.Font.Gotham
		TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		TextButton.TextSize = 14.000
		if not button.icon then
			TextButton.Text = button.name
		else
			TextButton.Text = "" -- No text if an icon is provided
		end

		UICorner.CornerRadius = UDim.new(1, 0)
		UICorner.Parent = TextButton

		Icon.Name = "Icon"
		Icon.Parent = TextButton
		Icon.AnchorPoint = Vector2.new(0.5, 0.5)
		Icon.BackgroundTransparency = 1
		Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		Icon.Size = UDim2.fromScale(0.40, 0.40)

		local defaultIcon = lucide.GetAsset(icon, 256 * 2) -- blank file icon
		assert(defaultIcon, "Failed to fetch asset!")
		Icon.ImageRectOffset = defaultIcon.ImageRectOffset
		Icon.ImageRectSize = defaultIcon.ImageRectSize
		Icon.Image = defaultIcon.Url

		UIAspectRatioConstraint.Parent = Icon

		TextButton.MouseButton1Click:Connect(function()
			local value = getOppositeReactorValue(button.reactor)
			button.reactor:Set(value)
		end)
		button.reactor:Watch(function(newValue: string)
			local oppositeValue = getOppositeReactorValue(button.reactor)
			print("Button state changed:", oppositeValue, "->", newValue)

			if button.callback then
				button.callback()
			else
				warn("No callback defined for button:", button.name)
			end

			-- tilt the icon
			if newValue == "open" then
				TweenPlus(
					Icon,
					{ Rotation = 15 },
					{ Time = 0.25, EasingDirection = "Out", EasingStyle = "Back" }
				):Start()
			else
				TweenPlus(
					Icon,
					{ Rotation = 0 },
					{ Time = 0.25, EasingDirection = "Out", EasingStyle = "Back" }
				):Start()
			end
		end)
		shadow(TextButton, Color3.new(), 0.5, 14)
		hint("Toggle the " .. button.name:lower() .. " page.", TextButton)
	end
end

function hud:toggle(buttonName: string)
	local button: button? = nil
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
	table.clear(hud.buttons)
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

function hud:bindHint(button: GuiButton, str: string)
	hint(str, button)
end

return hud
