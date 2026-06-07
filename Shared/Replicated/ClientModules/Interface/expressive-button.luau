--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local spr = require(ReplicatedStorage.Modules.spr)

-- expressive-button.luau
-- wip

local module = {}
module.__index = module

function module.new(button: GuiObject)
	local self = setmetatable({}, module)

	self.state = observer.new("idle")
	self.original_size = button.Size
	self.original_position = button.Position
	self.original_anchor_point = button.AnchorPoint
	self.offset_anchor_point = (Vector2.one / 2) - self.original_anchor_point

	self.original_position += UDim2.new(
		self.original_size.X.Scale * self.offset_anchor_point.X,
		self.original_size.X.Offset * self.offset_anchor_point.X,
		self.original_size.Y.Scale * self.offset_anchor_point.Y,
		self.original_size.Y.Offset * self.offset_anchor_point.Y
	)

	local hitbox = Instance.new("ImageButton")
	hydration(hitbox) {
		Parent = button,
	}

	hitbox.Activated:Connect(function()
		self.state:Set("press")
	end)
	hitbox.MouseButton1Down:Connect(function()
		self.state:Set("press")
	end)
	hitbox.MouseButton1Up:Connect(function()
		self.state:Set("idle")
	end)
	hitbox.MouseLeave:Connect(function()
		self.state:Set("idle")
	end)
	hitbox.MouseEnter:Connect(function()
		self.state:Set("hover")
	end)

	local ui_scale = Instance.new("UIScale")
	ui_scale.Parent = button

	self.state.Changed:Connect(function()
		if self.state:Get() == "press" then
			spr.target(ui_scale, 0.75, 4, {
				Scale = 1.1,
			})
		elseif self.state:Get() == "hover" then
			spr.target(ui_scale, 0.75, 4, {
				Scale = 1.05,
			})
		else
			spr.target(ui_scale, 0.75, 4, {
				Scale = 1,
			})
		end
	end)
end

return module
