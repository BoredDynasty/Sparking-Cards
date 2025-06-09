--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Emphasis = require(ReplicatedStorage.Utility.Emphasis)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

-- Dropdown.luau

--[[
    Mainly used for Split-buttons.
]]

local Dropdown = {}
Dropdown.__index = Dropdown

export type dropdown_interface = Frame & {
	Icon: ImageLabel,
	Chevron: Frame & {
		Overlay: Frame,
		HitBox: TextButton,
		ChevronIcon: ImageLabel,
		UICorner: UICorner,
	},
	HitBox: TextButton,
	TextLabel: TextLabel,
	UICorner: UICorner,
	Overlay: Frame & {
		UICorner: UICorner,
	},
}

type self = {
	interface: dropdown_interface,
	state: typeof(statemachine.new()),
	audio: typeof(audio.new()),
	open: (self: self) -> (),
	close: (self: self) -> (),
}

export type Dropdown = { typeof(setmetatable({} :: self, Dropdown)) }

function Dropdown.new(interface: dropdown_interface, audio_construct: typeof(audio.new)): Dropdown
	local states = {
		opened = {
			name = "opened",
			transitions = {
				closed = "closed",
			},
		},
		closed = {
			name = "closed",
			transitions = {
				opened = "opened",
			},
		},
	}
	local self = setmetatable({
		interface = interface,
		state = statemachine.new(states, "closed"),
		audio = audio_construct,
	}, Dropdown)
	return self
end

function Dropdown:open(self: self)
	self.state:transition("opened")
	TweenPlus(self.interface.Chevron.ChevronIcon, {
		Rotation = 180,
	}, {
		Time = Emphasis.standard,
		EasingStyle = "Back",
		EasingDirection = "Out",
	}):Start()
end

function Dropdown:close(self: self)
	self.state:transition("closed")
	TweenPlus(self.interface.Chevron.ChevronIcon, {
		Rotation = 0,
	}, {
		Time = Emphasis.standard,
		EasingStyle = "Back",
		EasingDirection = "Out",
	}):Start()
end

return Dropdown
