--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local spr = require(ReplicatedStorage.Modules.spr)
local sway = require(StarterPlayer.StarterPlayerScripts.Interface.sway)
local trove = require(ReplicatedStorage.Packages.trove)

-- physical-bar.luau
-- a 3d gui bar.
-- should supports multiple bars on a single adornee

local assets = ReplicatedStorage.Assets

local pool = PoolerPlus:CreatePool("BarPool", function()
	return assets.SprintBar:Clone()
end)

pool:AdaptivePreload()

local module = {}
module.__index = module

local tag = "Bar"

local padding = vector.create(-3, 0, 0) -- padding away from the adornee

type PhysicalBar = setmetatable<{
	bar: typeof(pool:Get()),
	adornee: observer.Observer<Instance?>,
	padding: observer.Observer<vector>,
	value: observer.Observer<number>,
	number_value: NumberValue,
	ui_scale: UIScale,
	_trove: typeof(trove.new()),
}, typeof(module)>

function module.new()
	local self = setmetatable({}, module)

	self.bar = pool:Get()
	self.adornee = observer.new(nil) :: observer.Observer<Instance?>
	self.padding = observer.new(padding) -- padding away from the adornee
	self.value = observer.new(100)
	self.number_value = Instance.new("NumberValue")
	self.ui_scale = Instance.new "UIScale"

	sway.register(self.bar.Frame, 6 or 7, 2)

	self._trove = trove.new()

	-- use hydration module for integration with the observer class.
	-- automatically updates values for us; no extra work needed.

	hydration(self.bar) {
		Adornee = self.adornee,
		ExtentsOffset = self.padding,
		Parent = self.adornee,
	}

	self.ui_scale.Parent = self.bar.Frame

	self._trove:Add(self.adornee)
	self._trove:Add(self.padding)
	self._trove:Add(self.value)
	self._trove:Add(self.number_value)

	self.adornee:Watch(function()
		local adornee = self.adornee:Get()

		if adornee and adornee:GetAttribute(tag) then
			-- supports multiple bars.
			-- add more padding for each new bar to avoid overlap.

			local existing_bars = adornee:GetAttribute(tag) :: number

			adornee:SetAttribute(tag, existing_bars + 1)

			local new_padding = padding * existing_bars

			self.padding:Set(new_padding)
		elseif adornee and not adornee:GetAttribute(tag) then
			adornee:SetAttribute(tag, 1)

			self.padding:Set(padding)
		end
	end)

	return self
end

function module.SetAdornee(self: PhysicalBar, adornee: Instance)
	if adornee then
		self.adornee:Set(adornee)
	end
end

function module.SetValue(self: PhysicalBar, value: number)
	local t_info = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local tween = TweenService:Create(self.number_value, t_info, {
		Value = value,
	})

	tween:Play()

	self.number_value.Changed:Connect(function(new_value)
		local percentage = math.clamp(new_value, 0, 1)

		local bar_frame = self.bar.Frame
		local inner_bar = bar_frame.Bar

		local scale = UDim2.fromScale(1, percentage)

		spr.stop(inner_bar, "Size")
		spr.target(inner_bar, 0.8, 8, {
			Size = scale,
		})
	end)
end

function module.Show(self: PhysicalBar)
	-- do an effect similar to `displayorder.luau`
	-- add .25 to the scale for the effect.

	self.ui_scale.Scale = 1.25

	-- position it *further* below

	self.bar.Frame.Position = UDim2.fromScale(0.5, 5)

	spr.stop(self.ui_scale)
	spr.stop(self.bar.Frame, "Position")

	spr.target(self.ui_scale, 0.5, 1.5, {
		Scale = 1,
	})

	-- attuned values, using desmos calculator
	-- https://www.desmos.com/calculator/rzvw27ljh9
	spr.target(self.bar.Frame, 0.8, 3.5, {
		Position = UDim2.fromScale(1 / 2, 0.65),
	})

	self.bar.Frame.Visible = true
end

function module.Hide(self: PhysicalBar)
	spr.stop(self.ui_scale)
	spr.stop(self.bar.Frame, "Position")

	spr.target(self.ui_scale, 0.4, 1.5, {
		Scale = 1.25,
	})

	spr.target(self.bar.Frame, 0.5, 0.8, {
		Position = UDim2.fromScale(0.5, 5),
	})

	spr.completed(self.bar.Frame, function()
		self.bar.Frame.Visible = false
	end)
end

function module.Destroy(self: PhysicalBar)
	self._trove:Destroy()

	pool:Return(self.bar)

	setmetatable(self, nil)
end

return module
