--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require("../Interface/pop")
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local shadow = require("../Interface/shadow")
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- options.luau

local module = {
	tracked = {} :: { Option },
	limit = ratelimit(1, 0.5),
}
export type option_callbacks = {
	on: (...unknown) -> ...unknown,
	off: (...unknown) -> ...unknown,
}

type Icons = {
	[string]: typemarshaller.LucideIcon,
}

export type Option = {
	name: string,
	details: string?,
	callbacks: option_callbacks,
	icons: Icons?,
	value: observer.Observer<any>,
}

function module.new(data: Option)
	table.insert(module.tracked, data)
end

local function createOption(ancestor: Instance?)
	local Instances = {
		OptionTemplate = Instance.new("Frame"),
		Frame = Instance.new("Frame"),
		UICorner = Instance.new("UICorner"),
		TextDisplay = Instance.new("TextLabel"),
		AspectRatio = Instance.new("UIAspectRatioConstraint"),
		AspectRatio_2 = Instance.new("UIAspectRatioConstraint"),
		Toggle = Instance.new("TextButton"),
		UICorner_2 = Instance.new("UICorner"),
		Icon = Instance.new("ImageLabel"),
		AspectRatio_3 = Instance.new("UIAspectRatioConstraint"),
		AspectRatio_4 = Instance.new("UIAspectRatioConstraint"),
		UICorner_3 = Instance.new("UICorner"),
		AspectRatio_5 = Instance.new("UIAspectRatioConstraint"),
	}

	Instances.OptionTemplate.Name = "OptionTemplate"
	Instances.OptionTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.OptionTemplate.Size = UDim2.new(0.82, 0, 0.13, 0)
	Instances.OptionTemplate.BorderColor3 = Color3.new(0, 0, 0)
	Instances.OptionTemplate.BackgroundTransparency = 1
	Instances.OptionTemplate.Position = UDim2.new(0.41, 0, 0.06, 0)
	Instances.OptionTemplate.BorderSizePixel = 0
	Instances.OptionTemplate.BackgroundColor3 = Color3.new(1, 1, 1)
	Instances.OptionTemplate.Parent = ancestor or ReplicatedStorage

	Instances.Frame.Name = "Frame"
	Instances.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Frame.Size = UDim2.new(0.65, 0, 0.7, 0)
	Instances.Frame.BorderColor3 = Color3.new(0, 0, 0)
	Instances.Frame.BackgroundTransparency = 1
	Instances.Frame.Position = UDim2.new(0.36, 0, 0.5, 0)
	Instances.Frame.BorderSizePixel = 0
	Instances.Frame.BackgroundColor3 = Color3.new(1, 1, 1)
	Instances.Frame.Parent = Instances.OptionTemplate

	Instances.UICorner.Name = "UICorner"
	Instances.UICorner.CornerRadius = UDim.new(0.32, 0)
	Instances.UICorner.Parent = Instances.Frame

	Instances.TextDisplay.Name = "TextDisplay"
	Instances.TextDisplay.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.TextDisplay.Size = UDim2.new(1, 0, 1, 0)
	Instances.TextDisplay.BorderColor3 = Color3.new(0, 0, 0)
	Instances.TextDisplay.BackgroundTransparency = 1
	Instances.TextDisplay.Position = UDim2.new(0.5, 0, 0.5, 0)
	Instances.TextDisplay.BorderSizePixel = 0
	Instances.TextDisplay.BackgroundColor3 = Color3.new(1, 1, 1)
	Instances.TextDisplay.FontFace =
		Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	Instances.TextDisplay.RichText = true
	Instances.TextDisplay.TextColor3 = Color3.new(0.95, 0.87, 0.85)
	Instances.TextDisplay.Text = "Option-Template"
	Instances.TextDisplay.Parent = Instances.Frame

	Instances.AspectRatio.Name = "AspectRatio"
	Instances.AspectRatio.AspectRatio = 4.79
	Instances.AspectRatio.Parent = Instances.TextDisplay

	Instances.AspectRatio_2.Name = "AspectRatio"
	Instances.AspectRatio_2.AspectRatio = 4.79
	Instances.AspectRatio_2.Parent = Instances.Frame

	Instances.Toggle.Name = "Toggle"
	Instances.Toggle.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Toggle.Size = UDim2.new(0.25, 0, 0.7, 0)
	Instances.Toggle.BorderColor3 = Color3.new(0, 0, 0)
	Instances.Toggle.Position = UDim2.new(0.98, 0, 0.5, 0)
	Instances.Toggle.BorderSizePixel = 0
	Instances.Toggle.BackgroundColor3 = Color3.new(0.36, 0.25, 0.22)
	Instances.Toggle.FontFace = Font.new(
		"rbxasset://fonts/families/SourceSansPro.json",
		Enum.FontWeight.Regular,
		Enum.FontStyle.Normal
	)
	Instances.Toggle.TextColor3 = Color3.new(0, 0, 0)
	Instances.Toggle.Text = ""
	Instances.Toggle.Parent = Instances.OptionTemplate

	Instances.UICorner_2.Name = "UICorner"
	Instances.UICorner_2.CornerRadius = UDim.new(0.32, 0)
	Instances.UICorner_2.Parent = Instances.Toggle

	Instances.Icon.Name = "Icon"
	Instances.Icon.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Icon.Size = UDim2.new(0.15, 0, 0.29, 0)
	Instances.Icon.BackgroundTransparency = 1
	Instances.Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	Instances.Icon.ImageColor3 = Color3.new(1, 0.86, 0.82)
	Instances.Icon.Image = "rbxassetid://10747384394"
	Instances.Icon.Parent = Instances.Toggle

	Instances.AspectRatio_3.Name = "AspectRatio"
	Instances.AspectRatio_3.Parent = Instances.Icon

	Instances.AspectRatio_4.Name = "AspectRatio"
	Instances.AspectRatio_4.AspectRatio = 1.86
	Instances.AspectRatio_4.Parent = Instances.Toggle

	Instances.UICorner_3.Name = "UICorner"
	Instances.UICorner_3.CornerRadius = UDim.new(0.32, 0)
	Instances.UICorner_3.Parent = Instances.OptionTemplate

	Instances.AspectRatio_5.Name = "AspectRatio"
	Instances.AspectRatio_5.AspectRatio = 5.18
	Instances.AspectRatio_5.Parent = Instances.OptionTemplate

	return Instances.OptionTemplate
end

local function booleanToString(boolean: boolean): "on" | "off"
	if boolean then
		return "on"
	else
		return "off"
	end
end

local function updateIcon(btn_icon: ImageLabel, boolean_state: boolean, icon_data: Icons)
	assert(typeof(boolean_state) == "boolean", "State is not a boolean: " .. typeof(boolean_state))

	local current_icon = select(
		2,
		future
			.Try(function()
				local str = booleanToString(boolean_state)

				return icon_data[str]
			end)
			:Unwrap()
	)

	assert(current_icon, "Could not fetch icon from data table: " .. tablekit.ToString(icon_data :: any))

	task.spawn(function()
		btn_icon.ImageContent = select(2, future.Try(Content.fromAssetId, current_icon.Id):Await())
		btn_icon.ImageRectOffset = current_icon.ImageRectOffset
		btn_icon.ImageRectSize = current_icon.ImageRectSize
	end)

	return true
end

function module:Get(name: string): Option?
	for i, option in ipairs(module.tracked) do
		if string.lower(name) == string.lower(option.name) then
			return option
		end
	end

	return nil
end

function module:Render(holder: Instance)
	-- cleanup existing
	for i, object in ipairs(holder:GetChildren()) do
		if object:IsA("Frame") then
			object:Destroy()
		end
	end

	-- render
	for i, option in ipairs(module.tracked) do
		local option_template = createOption(holder)

		local text_display = option_template:FindFirstChild("TextDisplay", true) :: TextLabel
		local toggle_btn = option_template:FindFirstChild("Toggle", true) :: TextButton
		local btn_icon = option_template:FindFirstChild("Icon", true) :: ImageLabel

		shadow(toggle_btn)

		local callbacks = option.callbacks :: { [string]: (...unknown) -> () }
		local icon_data = option.icons
		local value = option.value

		assert(icon_data, "Where is the icon data?: " .. tablekit.ToString(option :: any))

		if type(value:Get()) == "boolean" then
			future.new(updateIcon, btn_icon, value:Get(), icon_data)
		end

		local fancy = [[
		<b>%s</b></br>%s
		]]

		text_display.Text = string.format(fancy :: any, option.name, option.details)

		toggle_btn.Activated:Connect(function()
			if module.limit(option.name) then
				return
			end

			pop(toggle_btn)

			value:Map(function(current)
				return not current
			end)

			local boolean_state = value:Get()
			local str_state = booleanToString(boolean_state)

			local next_callback = callbacks[str_state]
			if next_callback then
				task.spawn(future.new, next_callback)

				if type(value:Get()) == "boolean" then
					future.new(updateIcon, btn_icon, value:Get(), icon_data)
				end
			end
		end)
	end
end

function module:Clear()
	return future.new(table.clear, module.tracked)
end

return module
