--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local future = require(ReplicatedStorage.Packages.future)
local spr = require(ReplicatedStorage.Modules.spr)

-- chip.luau

local module = {}

local pool = PoolerPlus:CreatePool("ChipPool", function()
	local templates = ReplicatedStorage.Interfaces

	return templates.Chip:Clone()
end)

pool:AdaptivePreload()

type Chip = setmetatable<{
	chip_gui: typeof(pool:Get()),
	active: boolean,
	fn: () -> ()?,
	Clicked: SignalPlus.Signal<>,
}, typeof(module)>

function module.new()
	return setmetatable({
		chip_gui = pool:Get(),
		active = false,
		fn = nil,
		Clicked = SignalPlus(),
	}, module)
end

function module.SetText(self: Chip, text: string)
	future.Try(function()
		self.chip_gui.Text = text
	end)
end

function module.SetCallback(self: Chip, fn: () -> ()?)
	future.Try(function()
		self.fn = fn

		self.chip_gui.Activated:Connect(function()
			module:Select()

			self.fn()

			self.Clicked:Fire()
		end)
	end)
end

function module.Select(self: Chip)
	if self.active then
		return
	end

	self.active = true

	-- animate the outline
	local outline = self.chip_gui.Outline
	outline.UIStroke.Transparency = 1
	outline.UIStroke.Thickness = 0

	spr.target(outline.UIStroke, 0.5, 4, {
		Thickness = 2.5,
	})

	spr.target(outline.UIStroke, 0.9, 7, {
		Transparency = 0,
	})

	local gradient = outline.UIGradient

	-- animate the gradient.

	local conn = nil

	conn = RunService.RenderStepped:Connect(function(delta_time)
		if not self.active then
			spr.target(outline.UIStroke, 0.5, 4, {
				Thickness = 0,
			})

			spr.target(outline.UIStroke, 0.9, 7, {
				Transparency = 1,
			})

			if conn then
				conn:Disconnect()
			end

			return
		end

		gradient.Rotation += math.deg(delta_time)
	end)
end

function module.Deselect(self: Chip)
	future.Try(function()
		self.active = false
	end)
end

return module
