--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local audio = require(ReplicatedStorage.Modules.audio)
local glare = require(StarterPlayer.StarterPlayerScripts.Interface.glare)
local lucide = require(ReplicatedStorage.Packages.lucide)
local markdown = require(ReplicatedStorage.ClientModules.markdown)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)

-- hud.luau

local player = playerMarshaller.get()

local module = {}
module.buttons = {}

export type button = {
	name: string,
	callback: () -> (),
	icon: icon?,
	reactor: observer.Observer<boolean>,
	limit: ratelimit.Ratelimit<string>,
	hover_limit: ratelimit.Ratelimit<string>,
	icon_only: boolean,
}

export type icon = {
	IconName: string, -- "icon-name"
	Id: number, -- 123456789
	Url: string, -- "rbxassetid://123456789"
	ImageRectSize: Vector2, -- Vector2.new(48, 48)
	ImageRectOffset: Vector2, -- Vector2.new(648, 266)
}

function module.new(name: string, callback: () -> (), icon: icon, icon_only: boolean?)
	local button = {
		name = name,
		callback = callback,
		icon = icon,
		reactor = observer.new(false),
		limit = ratelimit(1, 0.5),
		hover_limit = ratelimit(1, 0.9),
		icon_only = icon_only or false,
	}

	table.insert(module.buttons, button)
end

local function getOppositeReactorValue(reactor: observer.Observer<boolean>): boolean
	return not reactor:Get()
end

function module:render()
	local hudContainer = player.PlayerGui:WaitForChild("Hud") :: ScreenGui
	local hudBackground = hudContainer:WaitForChild("Background") :: Frame
	for _, button in ipairs(hudContainer:GetChildren()) do
		local attribute = button:GetAttribute("NonDestroyable")
		if button:IsA("TextButton") and not attribute then
			button:Destroy() -- Clear existing buttons
		end
	end

	for _, button: button in ipairs(module.buttons) do
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

		UICorner.CornerRadius = UDim.new(1, 0)
		UICorner.Parent = TextButton

		Icon.Name = "Icon"
		Icon.Parent = TextButton
		Icon.AnchorPoint = Vector2.new(if button.name then 1 else 0.5, 0.5)
		Icon.BackgroundTransparency = 1
		Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		Icon.Size = UDim2.fromScale(0.40, 0.40)
		task.spawn(function()
			if button.icon_only then
				-- make the TextButton width smaller.
				TextButton.Size = UDim2.fromScale(0.2, 0.7)
			else
				TextButton.RichText = true

				-- set icon adjacent to text
				local typewriter = markdown.typewriter.new({
					instantFinishKey = Enum.KeyCode.Unknown,
				})
				typewriter:Play(TextButton, button.name)

				-- yield till done
				repeat
					task.wait(1)
				until typewriter:IsPlaying() == false

				local text_bounds = TextButton.TextBounds
				local offset = 10

				Icon.Position = UDim2.new(0.5, (-text_bounds.X / 2) - offset, 0.5, 0)

				typewriter:Destroy()
			end
		end)

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
			Icon.ImageColor3 = Color3.fromHex("ffb5a0")

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

			--audio:SFX("click")
		end)

		local default_size = TextButton.Size

		TextButton.MouseEnter:Connect(function()
			if not button.hover_limit(button.name) then
				return
			end
			-- mouse hover effect
			spr.stop(TextButton, "Size")
			spr.target(TextButton, 0.8, 8, {
				BackgroundColor3 = Color3.fromHex("#342522"),
				Size = UDim2.fromScale(default_size.X.Scale * 1.1, default_size.Y.Scale * 1.1),
			})
			--audio:SFX("hover")
		end)

		TextButton.MouseLeave:Connect(function()
			spr.stop(TextButton, "Size")
			spr.target(TextButton, 0.8, 8, {
				BackgroundColor3 = Color3.fromHex("#1a110f"),
				Size = UDim2.fromScale(default_size.X.Scale / 1.1, default_size.Y.Scale / 1.1),
			})
			--audio:SFX("hover", {
			--pitch = 0.8,
			--})
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
				spr.stop(Icon)
				spr.target(Icon, 0.35, 8, {
					Rotation = 15,
				})
			else
				spr.stop(Icon)
				spr.target(Icon, 0.35, 8, {
					Rotation = 0,
				})
			end
		end)

		ripple:Watch(TextButton, 0.37)
		glare:Watch(TextButton, {
			corner_radius = UDim.new(1),
		})

		shadow(TextButton, Color3.new(), 0.5, 14)
	end
end

function module:toggle(buttonName: string)
	local button: button? = nil

	if not hud.buttons then
		return
	end

	for _, b in ipairs(hud.buttons :: { button }) do
		if b.name == buttonName then
			button = b
			break
		end
	end

	if button then
		button.reactor:Set(getOppositeReactorValue(button.reactor))
	end
end

function module:clear()
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

	table.clear(module.buttons) -- just to make sure we don't keep any references

	local hudContainer = player.PlayerGui:WaitForChild("Hud") :: ScreenGui

	for _, button in ipairs(hudContainer:GetChildren()) do
		if button:IsA("TextButton") then
			button:Destroy() -- Clear existing buttons
		end
	end
end

function module:hide()
	local hudContainer = player.PlayerGui:WaitForChild("Hud") :: ScreenGui
	hudContainer.Enabled = false
end
function module:show()
	local hudContainer = player.PlayerGui:WaitForChild("Hud") :: ScreenGui
	hudContainer.Enabled = true
end

return module
