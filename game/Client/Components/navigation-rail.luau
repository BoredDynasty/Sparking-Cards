--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local audio = require(ReplicatedStorage.Modules.audio)
local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

export type config = {
	name: string,
	icon: Content,
	callback: (boolean | unknown) -> ...unknown,
	holder: Instance,
	active: observer.Observer<boolean>,
}

local module = {}

module.watching = {} :: { config }

local function createButton(ancestor: Instance)
	local Instances = {
		ButtonTemplate = Instance.new("TextButton"),
		UICorner = Instance.new("UICorner"),
		Icon = Instance.new("ImageLabel"),
		AspectRatio = Instance.new("UIAspectRatioConstraint"),
		AspectRatio_2 = Instance.new("UIAspectRatioConstraint"),
	}

	Instances.ButtonTemplate.Name = "ButtonTemplate"
	Instances.ButtonTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.ButtonTemplate.Size = UDim2.new(0.88, 0, 0.11, 0)
	Instances.ButtonTemplate.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.ButtonTemplate.Position = UDim2.new(0, 25, 0, 25)
	Instances.ButtonTemplate.BorderSizePixel = 0
	Instances.ButtonTemplate.BackgroundColor3 = Color3.fromRGB(93, 64, 55)
	Instances.ButtonTemplate.FontFace = Font.new(
		"rbxasset://fonts/families/SourceSansPro.json",
		Enum.FontWeight.Regular,
		Enum.FontStyle.Normal
	)
	Instances.ButtonTemplate.RichText = true
	Instances.ButtonTemplate.TextColor3 = Color3.fromRGB(0, 0, 0)
	Instances.ButtonTemplate.Text = ""
	Instances.ButtonTemplate.Parent = ancestor or ReplicatedStorage

	Instances.UICorner.Name = "UICorner"
	Instances.UICorner.CornerRadius = UDim.new(1, 0)
	Instances.UICorner.Parent = Instances.ButtonTemplate

	Instances.Icon.Name = "Icon"
	Instances.Icon.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Icon.Size = UDim2.new(0.4, 0, 0.4, 0)
	Instances.Icon.BackgroundTransparency = 1
	Instances.Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	Instances.Icon.ImageColor3 = Color3.fromRGB(255, 219, 209)
	Instances.Icon.Image = "rbxassetid://10723407389"
	Instances.Icon.Parent = Instances.ButtonTemplate

	Instances.AspectRatio.Name = "AspectRatio"
	Instances.AspectRatio.DominantAxis = Enum.DominantAxis.Height
	Instances.AspectRatio.Parent = Instances.Icon

	Instances.AspectRatio_2.Name = "AspectRatio"
	Instances.AspectRatio_2.AspectRatio = 1
	Instances.AspectRatio_2.Parent = Instances.ButtonTemplate

	return Instances.ButtonTemplate
end

function module.new(config: config | unknown)
	local configuration = tablekit.Reconcile(config :: any, {
		active = observer.new(false),
	}) :: config

	table.insert(module.watching, configuration)
end

function module:Render()
	for i, data in ipairs(module.watching) do
		local button = createButton(data.holder)

		local image_label = button:FindFirstChildOfClass("ImageLabel")
		if image_label then
			image_label.ImageContent = data.icon
		end

		button.Activated:Connect(function()
			local is_active = data.active:Get()

			task.spawn(future.new, data.callback, is_active)

			pop(button)

			audio:PlaySFX("click")
		end)

		shadow(button)
	end
end

return module
