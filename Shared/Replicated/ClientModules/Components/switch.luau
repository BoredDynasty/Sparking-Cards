--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local spr = require(ReplicatedStorage.Modules.spr)

-- switch.luau
-- switches can be toggled on and off.
-- all switches should be all built the same way.
-- read M3 docs for referene: https://m3.material.io/components/switch/specs

local module = {}
module.__index = module

local function createSwitch()
	return ReplicatedStorage.Interfaces.Switch:Clone()
end
type Switch = {
	switch: typeof(createSwitch()),
	state: observer.Observer<boolean>,
	Changed: SignalPlus.Signal<boolean>,
	rate_limit: ratelimit.Ratelimit<any>,
}

local switch_colors = {
	on = {
		knob = Color3.fromRGB(26, 17, 15),
		state_image = Color3.fromRGB(255, 181, 160),
		fill = Color3.fromRGB(255, 181, 160),
	},
	off = {
		fill = Color3.fromHex("#3d322f"),
		knob = Color3.fromHex("#a08c87"),
		state_image = Color3.fromHex("#a08c87"),
	},
}

local knob_positions = {
	on = UDim2.fromScale(0.683, 0.5),
	off = UDim2.fromScale(0.283, 0.5),
}

function module.new()
	local self = setmetatable({}, module)

	self.switch = createSwitch()
	self.state = observer.new(false)
	self.Changed = SignalPlus() :: SignalPlus.Signal<boolean>
	self.rate_limit = ratelimit(1, 1.2)

	return self
end

function module:Toggle()
	self.state:Set(not self.state:Get())

	spr.target(self.switch.Fill, 0.5, 10, {
		BackgroundColor3 = if self.state:Get() then switch_colors.on.fill else switch_colors.off.fill,
	})
	spr.target(self.switch.Knob, 0.5, 10, {
		BackgroundColor3 = if self.state:Get() then switch_colors.on.knob else switch_colors.off.knob,
	})
	spr.target(self.switch.Knob.StateImage, 0.5, 10, {
		ImageColor3 = if self.state:Get()
			then switch_colors.on.state_image
			else switch_colors.off.state_image,
	})

	spr.target(self.switch.Knob, 0.5, 10, {
		Position = if self.state:Get() then knob_positions.on else knob_positions.off,
	})
end

function module:SetScale(scale: number)
	-- when the switch is too smol or big, we sometimes gotta change it!
	self.switch.UIScale.Scale = scale
end

function module:BindToGui(gui: GuiObject)
	self.switch.Parent = gui

	self.switch.Activated:Connect(function()
		if not self.rate_limit() then
			return
		end

		self:Toggle()
		self.Changed:Fire(self.state:Get())
	end)
end

function module:Destroy()
	future.Try(function()
		if self.switch then
			self.switch:Destroy()
		end
	end)

	self.Changed:Destroy()
	self.state:Destroy()

	setmetatable(self, nil)
end

return module
