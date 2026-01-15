--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local property = require(ReplicatedStorage.Utility.property)
local range_shift = require(ReplicatedStorage.Modules.Mathematics["range-shift"])

-- circular-progress.luau

local progress_module = {}

local update_callbacks = {} :: { [string]: (any) -> ...unknown }
update_callbacks.Progress = function(self)
	progress_module:UpdateFill(self, true)
end
update_callbacks.Rotation = function(self)
	progress_module:UpdateFill(self, false)
end
update_callbacks.Position = function(self)
	local circle = self.Instance :: GuiObject
	circle.Position = self.Position
end
update_callbacks.AnchorPoint = function(self)
	local circle = self.Instance :: GuiObject
	circle.AnchorPoint = self.AnchorPoint
end
update_callbacks.Size = function(self)
	local circle = self.Instance :: GuiObject
	circle.Size = self.Size
end
update_callbacks.Thickness = function(self)
	local circle = self.Instance :: GuiObject & any
	local hide_circle = circle.Circle.HideCircle :: Frame

	local thickness = 1 - self.Thickness :: number

	circle.Circle.HideCircle.Visible = true

	if self.Thickness :: number == 1 then
		hide_circle.Visible = false
	end

	hide_circle.Size = UDim2.fromScale(thickness, thickness)

	progress_module:_GetDots(self, function(a0: GuiObject)
		a0.Size = UDim2.fromScale(self.Thickness :: number / 2, self.Thickness :: number / 2)
	end)
end
update_callbacks.CircleSize = function(self)
	local circle = self.Instance :: GuiObject & any
	circle.Circle.Size = UDim2.fromScale(self.CircleSize, self.CircleSize)
end
update_callbacks.Color = function(self)
	local circle = self.Instance :: GuiObject & any

	local right_clip = circle:WaitForChild("RightClip") :: Frame | any
	local left_clip = circle:WaitForChild("LeftClip") :: Frame | any

	right_clip.Circle.BackgroundColor3 = self.Color
	left_clip.Circle.BackgroundColor3 = self.Color

	progress_module:_GetDots(self, function(a0: GuiObject)
		a0.BackgroundColor3 = self.Color
	end)
end
update_callbacks.BackgroundColor3 = function(self)
	local circle = self.Instance :: GuiObject & any

	circle.BG.BackgroundColor3 = self.BackgroundColor3

	for i, object in ipairs(circle:GetDescendants()) do
		if object.Name == "HideCircle" then
			object.BackgroundColor3 = self.BackgroundColor3
		end
	end
end
-- TODO) finish this

function progress_module.new(properties: { [string]: any })
	local progress_circle = {}

	progress_circle.Progress = 0 -- from 0 to 100 -|interchangable
	progress_circle.Rotation = 0 -- from 0 to 360 -|interchangable

	progress_circle.Position = UDim2.fromScale(0.04, 0.95)
	progress_circle.AnchorPoint = Vector2.new(0, 0)
	progress_circle.Size = 0.2 -- from 0 to 1
	progress_circle.Thickness = 0.3 -- from 0 to 1
	progress_circle.CircleSize = 0.7 -- from 0 to 1

	progress_circle.Color = Color3.fromRGB(255, 255, 255)
	progress_circle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	progress_circle.Transparency = 0 --from 0 to 1
	progress_circle.BackgroundRoundness = 0.2 -- from 0 to 1

	progress_circle.Rounded = true

	progress_circle.Instance = nil

	-- create circle

	if properties then
		for i, v in pairs(properties) do
			progress_circle[i] = v
		end
	end

	local progress_mt = setmetatable({}, {
		__index = function(t, key, value)
			if progress_circle[key] ~= nil then
				return progress_circle[keybindlink]
			end
			if progress_circle[key] ~= nil then
				return progress_circle[key]
			end
		end,
		__newindex = function(t, property, value)
			-- TODO) finish this
		end,
	})
end

function progress_module:_GetDots(self, f: (GuiObject) -> ...unknown)
	local circle = self.Instance.Circle :: GuiObject

	for i, object in ipairs(circle:GetChildren() :: { GuiObject }) do
		if string.find(object.Name, "Dot") then
			f(object)
		end
	end
end

function progress_module:UpdateFill(self, percent: boolean)
	local circle = self.Instance.Circle :: GuiObject & any

	local rotation = self.Rotation :: number
	if percent then
		rotation = self.Progress :: number * 3.6
	end

	-- that "fmod" is a new keyword!
	-- its long division; it returns the remainder!
	-- how magnificent!!!
	rotation = math.fmod(rotation, 360.1)

	-- set fill
	local right_clip = circle:WaitForChild("RightClip") :: Frame | any
	local left_clip = circle:WaitForChild("LeftClip") :: Frame | any

	local right_gradient = right_clip.Circle.UIGradient :: UIGradient
	local left_gradient = left_clip.Circle.UIGradient :: UIGradient

	local half_circle = 180
	if rotation < half_circle and rotation > -half_circle then
		right_clip.HideCircle.Visible = true

		right_gradient.Rotation = rotation
		left_gradient.Rotation = 0
	else
		right_clip.HideCircle.Visible = false

		right_gradient.Rotation = 180
		left_gradient.Rotation = rotation - 180
	end

	-- should it be rounded?
	if self.Rounded then
		local dot = circle:FindFirstChild("Dot") :: Frame
		if not dot then
			local center_dot = circle:FindFirstChild("CenterDot") :: Frame
			dot = center_dot:Clone()
			dot.Name = "Dot"
			dot.Parent = circle
		end

		-- set the position of the dot
		local angle
		if rotation <= 90 then
			angle = (360 - 90) + rotation
		else
			angle = rotation - 90
		end

		local radii_rotation = math.rad(angle)

		local range_1 = { -1, 1 }
		local range_2 = { 0, 1 }

		local cosine = math.cos(radii_rotation)
		local sine = math.sin(radii_rotation)

		local x = range_shift(range_1, range_2, cosine)
		local y = range_shift(range_1, range_2, sine)

		dot.AnchorPoint = Vector2.new(x, y)
		dot.Position = UDim2.fromScale(x, y)

		self.Progress = rotation / 3.6
		self.Rotation = rotation
	end
end
