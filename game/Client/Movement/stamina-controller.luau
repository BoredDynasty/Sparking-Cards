--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

-- stamina-controller.luau

local _trove = trove.new()

local controller = {}
controller._trove = _trove

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local max_stamina = 100
local regeneration_delay = 2.5
local regeneration_rate = 10
local last_drain = observer.new(0)
local is_regenerating = observer.new(false)

local bar_size = UDim2.fromScale(0.5, 0.97)

character:SetAttribute("Stamina", max_stamina)
character:SetAttribute("AntiRegenerate", false)

type interface = BillboardGui & {
	Frame: CanvasGroup & {
		Bar: Frame,
		TextLabel: TextLabel,
	},
}

local function constructBar(ancestor: Instance?): interface
	local Instances = {
		SprintBar = Instance.new("BillboardGui"),
		Frame = Instance.new("CanvasGroup"),
		UICorner = Instance.new("UICorner"),
		Bar_2 = Instance.new("Frame"),
		UICorner_2 = Instance.new("UICorner"),
		AspectRatio = Instance.new("UIAspectRatioConstraint"),
		UIScale = Instance.new("UIScale"),
	}

	Instances.SprintBar.Name = "SprintBar"
	Instances.SprintBar.ExtentsOffset = Vector3.new(-3, 0, 0)
	Instances.SprintBar.MaxDistance = 0
	Instances.SprintBar.AlwaysOnTop = true
	Instances.SprintBar.Size = UDim2.new(10, 0, 5, 0)
	Instances.SprintBar.Parent = ancestor or workspace

	Instances.Frame.Name = "Frame"
	Instances.Frame.AnchorPoint = Vector2.new(0.5, 1)
	Instances.Frame.Size = UDim2.new(0.01, 0, 0.31, 0)
	Instances.Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.Frame.Position = UDim2.new(0.5, 0, 0.66, 0)
	Instances.Frame.BorderSizePixel = 0
	Instances.Frame.BackgroundColor3 = Color3.fromRGB(35, 25, 23)
	Instances.Frame.Parent = Instances.SprintBar

	Instances.UICorner.Name = "UICorner"
	Instances.UICorner.CornerRadius = UDim.new(1, 0)
	Instances.UICorner.Parent = Instances.Frame

	Instances.Bar_2.Name = "Bar"
	Instances.Bar_2.AnchorPoint = Vector2.new(0.5, 1)
	Instances.Bar_2.ZIndex = 4
	Instances.Bar_2.Size = UDim2.new(0.5, 0, 0.97, 0)
	Instances.Bar_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.Bar_2.Position = UDim2.new(0.5, 0, 0.99, 0)
	Instances.Bar_2.BorderSizePixel = 0
	Instances.Bar_2.BackgroundColor3 = Color3.fromRGB(241, 223, 218)
	Instances.Bar_2.Parent = Instances.Frame

	Instances.UICorner_2.Name = "UICorner"
	Instances.UICorner_2.CornerRadius = UDim.new(1, 0)
	Instances.UICorner_2.Parent = Instances.Bar_2

	Instances.AspectRatio.Name = "AspectRatio"
	Instances.AspectRatio.AspectRatio = 0.05
	Instances.AspectRatio.Parent = Instances.Frame

	Instances.UIScale.Name = "UIScale"
	Instances.UIScale.Scale = 3
	Instances.UIScale.Parent = Instances.Frame

	return Instances.SprintBar :: any
end

local bar = constructBar(character)
bar.Adornee = character.PrimaryPart

characterMarshaller.added(player, function(new_character)
	if new_character:FindFirstChild("SprintBar") then
		return
	end

	bar = constructBar(new_character)
	bar.Adornee = new_character.PrimaryPart
end)

_trove:Connect(character:GetAttributeChangedSignal("Stamina"), function()
	local stamina = character:GetAttribute("Stamina") :: number?
	if not stamina then
		return
	end

	local percentage = math.clamp(stamina / max_stamina, 0, 1)

	local scale = UDim2.fromScale(bar_size.X.Scale, bar_size.Y.Scale * percentage)

	local bar_frame = bar:FindFirstChild("Frame") :: Frame
	local inner_bar = bar_frame:FindFirstChild("Bar") :: Frame

	local tween = TweenPlus(inner_bar, {
		Size = scale,
	}, {
		EasingDirection = "Out",
		EasingStyle = "Back",
	})

	tween:Start()
end)

function controller:Update(deltaTime: number)
	local anti_regenerate = character:GetAttribute("AntiRegenerate") :: boolean
	local current_stamina = character:GetAttribute("Stamina") :: number or max_stamina

	if anti_regenerate then
		last_drain:Set(0)
		is_regenerating:Set(true)
	else
		last_drain:Map(function(current: number)
			return current * deltaTime
		end)

		if last_drain:Get() >= regeneration_delay then
			is_regenerating:Set(true)
		end
	end

	if is_regenerating:Get() and current_stamina < max_stamina then
		local regenerate_amount = regeneration_rate * deltaTime

		current_stamina = math.min(current_stamina + regenerate_amount, max_stamina)

		character:SetAttribute("Stamina", current_stamina)
	end
end

return controller
