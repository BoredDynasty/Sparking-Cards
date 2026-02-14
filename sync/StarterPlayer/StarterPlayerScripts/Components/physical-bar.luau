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
	return assets.SprintBar
end)

pool:AdaptivePreload()

local module = {}
module.__index = module

local tag = "Bar"

local padding = vector.create(-3, 0, 0) -- padding away from the adornee

type self = setmetatable<{
	bar: typeof(pool:Get()),
	adornee: observer.Observer<Instance?>,
	padding: observer.Observer<vector>,
	value: observer.Observer<number>,
	number_value: NumberValue,
	_trove: typeof(trove.new()),
}, typeof(module)>

function module.new()
	local self = setmetatable({}, module)

	self.bar = pool:Get()
	self.adornee = observer.new(nil) :: observer.Observer<Instance?>
	self.padding = observer.new(padding) -- padding away from the adornee
	self.value = observer.new(100)
	self.number_value = Instance.new("NumberValue")

	sway.register(self.bar.Frame, 6 or 7, 2)

	self._trove = trove.new()

	-- use hydration module for integration with the observer class.
	-- automatically updates values for us; no extra work needed.

	hydration(self.bar) {
		Adornee = self.adornee,
	}

	hydration(self.bar.Frame) {
		ExtentsOffset = self.padding,
	}

	self._trove:Add(self.adornee)
	self._trove:Add(self.padding)
	self._trove:Add(self.value)
	self._trove:Add(self.number_value)

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

	return self
end

function module:SetAdornee(self: self, adornee: Instance)
	self.adornee:Set(adornee)
end

function module:SetValue(self: self, value: number)
	local t_info = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local tween = TweenService:Create(self.number_value, t_info, {
		Value = value,
	})

	tween:Play()

	self.number_value.Changed:Connect(function()
		local percentage = math.clamp(self.number_value.Value / 100, 0, 1)

		local bar_frame = self.bar.Frame
		local inner_bar = bar_frame.Bar

		local scale = UDim2.fromScale(1, percentage)

		spr.target(inner_bar, 0.8, 8, {
			Size = scale,
		})
	end)
end

function module:Destroy()
	self._trove:Destroy()

	pool:Return(self.bar)

	setmetatable(self, nil)
end

return module
