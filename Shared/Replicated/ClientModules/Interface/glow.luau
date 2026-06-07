--!strict

-- glow.luau

local glow_module = {}

local parts = {
	"top",
	"bottom",
	"left",
	"right",
	"left_top",
	"left_bottom",
	"right_top",
	"right_bottom",
}

function glow_module:GetDimesionOffsets(total_thickness: number): { UDim2 }
	return {
		UDim2.new(1, 0, 0, total_thickness),
		UDim2.new(1, 0, 0, total_thickness),
		UDim2.new(0, total_thickness, 1, 0),
		UDim2.new(0, total_thickness, 1, 0),
		UDim2.fromOffset(total_thickness, total_thickness),
		UDim2.fromOffset(total_thickness, total_thickness),
		UDim2.fromOffset(total_thickness, total_thickness),
		UDim2.fromOffset(total_thickness, total_thickness),
	}
end

function glow_module:GetAbsoluteCornerRadii(object: GuiObject)
	local radius = 0

	local corner = object:FindFirstChildOfClass("UICorner")

	if corner then
		local abs_size = object.AbsoluteSize
		if not abs_size then
			return 0
		end

		local corner_scale = corner.CornerRadius.Scale
		local corner_offset = corner.CornerRadius.Offset

		radius = (math.min(abs_size.X, abs_size.Y) * corner_scale) + corner_offset
	end

	return radius
end

function glow_module:Set(object: GuiObject, holder: Frame, thickness: number)
	local abs_size, abs_position = object.AbsoluteSize, object.AbsolutePosition
	if not abs_size then
		return
	end

	local ancestor = object.Parent :: GuiObject
	if not ancestor or typeof(ancestor) == "ScreenGui" then
		-- well ofc it would be a screengui
		-- but maybe i would be tweaking, yknow
	end

	local center = abs_position + (abs_size / 2)
	local relative_position = center - ancestor.AbsolutePosition

	local corner_radii = glow_module:GetAbsoluteCornerRadii(object)

	local x = abs_size.X - (2 * corner_radii)
	local y = abs_size.Y - (2 * corner_radii)

	local total_thickness = thickness + corner_radii
	local dimension_offsets = glow_module:GetDimesionOffsets(total_thickness)

	holder.Position = UDim2.fromOffset(relative_position.X, relative_position.Y)
	holder.Size = UDim2.fromOffset(x, y)

	for index, part_name in ipairs(parts) do
		local part = holder:FindFirstChild(part_name) :: Frame
		if part then
			part.Size = dimension_offsets[index]
		end
	end
end

function glow_module:SetTransparency(holder: Frame, transparency: number)
	for _, part_name in ipairs(parts) do
		local part = holder:FindFirstChild(part_name) :: Frame
		if part then
			part.BackgroundTransparency = transparency
		end
	end
end

function glow_module:SetColor(holder: Frame, color: Color3)
	for _, part_name in ipairs(parts) do
		local part = holder:FindFirstChild(part_name) :: Frame
		if part then
			part.BackgroundColor3 = color
		end
	end
end

function glow_module:Watch(object: GuiObject, holder: Frame, thickness: number)
	holder = holder:Clone()
	holder.Parent = object.Parent
	holder.ZIndex = object.ZIndex - 1

	glow_module:Set(object, holder, thickness)

	object:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		glow_module:Set(object, holder, thickness)
	end)

	object:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		glow_module:Set(object, holder, thickness)
	end)

	object:GetPropertyChangedSignal("Visible"):Connect(function()
		holder.Visible = object.Visible
	end)

	object.Destroying:Connect(function()
		holder:Destroy()
	end)

	return holder
end

return glow_module
