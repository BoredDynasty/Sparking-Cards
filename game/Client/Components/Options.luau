--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local markdown = require(ReplicatedStorage.ClientModules.markdown)
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require("../Interface/pop")
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require("../Interface/ripple")

-- options.luau

local options = {
	tracked = {},
	limit = ratelimit(1, 3),
}

export type data = {
	name: string,
	description: string,
	state: observer.Observer<boolean>,
	functions: {
		on: (newValue: any) -> (),
		off: (newValue: any) -> (),
		toggle: () -> (),
	},
	icons: {
		on: string,
		off: string,
	}?,
	override: "on" | "off" | nil,
}

export type settingUI = Frame & {
	Frame: Frame & {
		TextDisplay: TextLabel,
	},
	Toggle: TextButton & {
		Icon: ImageLabel,
	},
	OptionTemplate: Frame,
}

function options.new(data: data)
	if not data.icons then
		data.icons = {
			on = "rbxassetid://10709790644",
			off = "rbxassetid://10747384394",
		}
	end

	-- override
	if data.override and data.functions[data.override] then
		data.functions[data.override]()
	end

	table.insert(options.tracked, data)

	return data
end

function options:get(name: string): data?
	for _, option in ipairs(options.tracked :: { data }) do
		if option.name == name then
			return option
		end
	end

	return nil
end

function options:all(): { data }
	return options.tracked
end

function options:reset()
	for _, option in ipairs(options.tracked :: { data }) do
		option.state:Set(false)
	end
end

function options:enable(name: string)
	local option = options:get(name)
	if option then
		option.state:Set(true)
	end
end

function options:disable(name: string)
	local option = options:get(name)
	if option then
		option.state:Set(false)
	end
end

function options:toggle(name: string)
	local option = options:get(name)
	if option then
		option.state:Set(not option.state:Get())
	end
end

function options:create_setting(ancestor: Instance?): settingUI
	-- Instances:

	local OptionTemplate = Instance.new("Frame")
	local Frame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local TextDisplay = Instance.new("TextLabel")
	local Toggle = Instance.new("TextButton")
	local UICorner_2 = Instance.new("UICorner")
	local Icon = Instance.new("ImageLabel")
	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	local UICorner_3 = Instance.new("UICorner")

	--Properties:

	OptionTemplate.Name = "OptionTemplate"
	OptionTemplate.Parent = ancestor or ReplicatedStorage
	OptionTemplate.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	OptionTemplate.BackgroundTransparency = 1.000
	OptionTemplate.BorderColor3 = Color3.fromRGB(0, 0, 0)
	OptionTemplate.BorderSizePixel = 0
	OptionTemplate.Position = UDim2.new(-4.00597671e-08, 0, 0, 0)
	OptionTemplate.Size = UDim2.new(0, 518, 0, 100)

	Frame.Parent = OptionTemplate
	Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Frame.BackgroundTransparency = 1.000
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Position = UDim2.new(0.0354033373, 0, 0.150000006, 0)
	Frame.Size = UDim2.new(0.647876382, 0, 0.699999988, 0)

	UICorner.CornerRadius = UDim.new(0.319999993, 0)
	UICorner.Parent = Frame

	TextDisplay.Name = "TextDisplay"
	TextDisplay.Parent = Frame
	TextDisplay.AnchorPoint = Vector2.new(0.5, 0.5)
	TextDisplay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextDisplay.BackgroundTransparency = 1.000
	TextDisplay.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextDisplay.BorderSizePixel = 0
	TextDisplay.Position = UDim2.new(0.5, 0, 0.5, 0)
	TextDisplay.Size = UDim2.new(1, 0, 1, 0)
	TextDisplay.Font = Enum.Font.Gotham
	TextDisplay.Text = "option"
	TextDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextDisplay.TextSize = 14.000

	Toggle.Name = "Toggle"
	Toggle.Parent = OptionTemplate
	Toggle.BackgroundColor3 = Color3.fromRGB(143, 76, 56)
	Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Toggle.BorderSizePixel = 0
	Toggle.Position = UDim2.new(0.720077217, 0, 0.150000006, 0)
	Toggle.Size = UDim2.new(0, 130, 0, 70)
	Toggle.Font = Enum.Font.SourceSans
	Toggle.Text = ""
	Toggle.TextColor3 = Color3.fromRGB(0, 0, 0)
	Toggle.TextSize = 14.000

	UICorner_2.CornerRadius = UDim.new(0.319999993, 0)
	UICorner_2.Parent = Toggle

	Icon.Name = "Icon"
	Icon.Parent = Toggle
	Icon.BackgroundTransparency = 1.000
	Icon.Position = UDim2.new(0.423076928, 0, 0.357142866, 0)
	Icon.Size = UDim2.new(0, 20, 0, 20)
	Icon.Image = "rbxassetid://10747384394"

	UIAspectRatioConstraint.Parent = Icon

	UICorner_3.CornerRadius = UDim.new(0.319999993, 0)
	UICorner_3.Parent = OptionTemplate

	return OptionTemplate
end

function options:render(ancestor: Instance)
	local visited = table.create(#options.tracked) :: { string }

	for i, option in ipairs(options.tracked :: { data }) do
		local needle = table.find(visited, option.name)

		if needle and visited[needle] then
			return
		end

		table.insert(visited, option.name)

		local template = options:create_setting()

		local label = template.Frame.TextDisplay
		local typewriter = markdown.typewriter.new()

		typewriter:Play(label, option.name .. "\n\n" .. option.description)

		task.spawn(function()
			repeat
				task.wait(1)
			until typewriter:IsPlaying() == false

			typewriter:Destroy()
		end)

		local uri = option.icons and option.icons[option.override or "off"] or ""
		local iconContent = Content.fromUri(uri) or Content.none

		template.Toggle.Icon.ImageContent = iconContent

		template.Toggle.MouseButton1Click:Connect(function()
			if not options.limit(template:GetFullName()) then
				print("cooldown: ", template:GetFullName())

				return
			end

			option.functions[if option.state:Get() == false then "off" else "on"]()

			pop(template.Toggle, 1.1)
			ripple(template.Toggle, 1.1 / 2)

			option.state:Set(not option.state:Get())
		end)

		option.state:Watch(function(newValue: boolean)
			local newUri = option.icons and option.icons[if newValue then "on" else "off"] or ""
			local newIconContent = Content.fromUri(newUri) or Content.none
			template.Toggle.Icon.ImageContent = newIconContent
		end)

		template.Parent = ancestor
	end

	table.clear(visited)
end

function options:destroy()
	for i, option in ipairs(options.tracked :: { data }) do
		option.state:Destroy()
	end
	table.clear(options.tracked)
end

return options
