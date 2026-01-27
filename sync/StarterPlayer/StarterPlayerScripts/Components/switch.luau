--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spr = require(ReplicatedStorage.Modules.spr)

-- switch.luau
-- switches can be toggled on and off.
-- all switches should be all built the same way.
-- wip

local module = {}
module.__index = module

export type Switch = {
	is_on: boolean,
	switch_gui: SwitchGui,
	Toggle: (self: Switch) -> (),
	SetState: (self: Switch, state: boolean) -> (),
}

type SwitchGui = GuiObject & {
	Fill: ImageLabel,
	Knob: TextButton & {
		StateImage: ImageLabel,
	},
}

type Switch__mt = setmetatable<Switch, typeof(module)>

local knob_positions = {
	on = UDim2.fromScale(0.683, 0.5),
	off = UDim2.fromScale(0.317, 0.5),
}

-- define colors

local switch_colors = {
	fill_on = Color3.fromRGB(255, 181, 160),
	fill_off = Color3.fromHex("#392e2b"),
	knob_on = Color3.fromRGB(26, 17, 15),
	knob_off = Color3.fromHex("#423734"),
}

function module.new(gui: SwitchGui, initial_state: boolean)
	local self = {} :: Switch

	self.is_on = initial_state
	self.switch_gui = gui

	return setmetatable(self, module)
end

function module:SetState(self: Switch, state: boolean)
	self.is_on = state

	if self.is_on then
		spr.target(self.switch_gui.Fill, 1, 3, {
			BackgroundColor3 = switch_colors.fill_on,
		})
		spr.target(self.switch_gui.Knob, 0.5, 3, {
			Position = knob_positions.on,
			BackgroundColor3 = switch_colors.knob_on,
		})
	else
		spr.target(self.switch_gui.Fill, 1, 3, {
			BackgroundColor3 = switch_colors.fill_off,
		})
		spr.target(self.switch_gui.Knob, 0.5, 3, {
			Position = knob_positions.off,
			BackgroundColor3 = switch_colors.knob_off,
		})
	end
end
