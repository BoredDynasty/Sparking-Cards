--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)

-- glare.luau

local glare_module = {
	defaults = {
		width = 50,
		height = 200,
		background_color = Color3.fromHSV(0, 0, 1),
		corner_radius = UDim.new(8, 0),
		color = Color3.fromRGB(255, 255, 255),
		opacity = 0.4,
		angle = 20,
		size = 100,
		duration = 1000, -- in milliseconds
		once = false,
	} :: glare,
	limit = ratelimit(1, 1),
	tracking = {},
}

export type glare = {
	width_factor: number?,
	height_factor: number?,
	background_color: Color3?,
	corner_radius: UDim?,
	color: Color3?,
	opacity: number?,
	angle: number?,
	size: number?,
	duration: number?, -- in milliseconds
	--[[
      If true, the glare only animates on hover and doesn't return on mouse leave.
   ]]
	once: boolean?,
}

function glare_module:Watch(object: GuiObject, props: glare?)
	-- Create holder for the glare so corners clip correctly
	props = props or glare_module.defaults
	-- reconcile
	for k, v in pairs(glare_module.defaults) do
		if not props[k] or typeof(props[k]) ~= typeof(v) then
			props[k] = v
		end
	end

	local glareHolder = Instance.new("Frame")
	glareHolder.Name = "GlareHolder"
	glareHolder.BackgroundTransparency = 1
	glareHolder.Size = UDim2.fromScale(1, 1)
	glareHolder.ClipsDescendants = true
	glareHolder.Parent = object

	-- Copy UICorner if exists
	local existingCorner = object:FindFirstChildOfClass("UICorner")
	if existingCorner then
		local newCorner = existingCorner:Clone()

		newCorner.Parent = glareHolder
	elseif not existingCorner and props.corner_radius ~= nil then
		local corner = Instance.new("UICorner")

		corner.Parent = glareHolder
		corner.CornerRadius = props.corner_radius
	end

	-- Create glare overlay
	local glare = Instance.new("Frame")
	glare.Name = "GlareOverlay"
	glare.BackgroundTransparency = 1
	glare.BorderSizePixel = 0
	glare.Size =
		UDim2.new(0, object.AbsoluteSize.X * (props.width_factor or 0.4), 1 * (props.height_factor or 1), 0)
	glare.Position = UDim2.new(-0.4)
	glare.Rotation = props.angle or -45
	glare.Parent = glareHolder
	glare.Visible = false

	-- Add gradient for better effect
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, props.color or Color3.fromRGB(255, 255, 255)),
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = if props.angle then -props.angle else -15
	gradient.Parent = glare

	local function inner()
		glare.Visible = true

		local tween = TweenPlus(glare, {
			Position = UDim2.new(1),
		}, {
			Time = (props.duration or 1000) / 1000,
			EasingStyle = "Linear",
		})

		tween:Start()

		tween.Completed:Once(function()
			task.defer(function()
				glare.Position = UDim2.new(-0.4)
			end)
		end)
	end

	local function outer()
		glare.Visible = false
	end

	local conn = object.MouseEnter:Connect(inner)
	local conn2 = object.MouseLeave:Connect(outer)

	table.insert(glare_module.tracking, {
		name = object:GetFullName(),
		conn = conn,
		conn2 = conn2,
	})
end

return glare_module
