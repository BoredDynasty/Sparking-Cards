--!strict

-- shadow.luau

-- specifically for Drop shadows

return function(parent: Instance, color: Color3, transparency: number, spread: number)
	local function gaussian(n: number, sigma: number)
		local weights = {}
		local sum = 0
		for i = -n, n do
			local weight = math.exp(-((i ^ 2) / (2 * sigma ^ 2)))
			table.insert(weights, weight)
			sum += weight
		end
		for i = 1, #weights do
			weights[i] = (weights[i] / sum) * (1 - transparency)
		end
		return weights
	end
	local sigma = spread / 2
	local weights = gaussian(spread, sigma)
	local layers = Instance.new("Folder")
	layers.Name = "ShadowLayers"
	layers.Parent = parent
	for i, opacity in ipairs(weights) do
		local index = i - #weights // 2
		local offset = math.abs(index) - 1
		local layer = Instance.new("Frame")
		layer.Name = tostring(i)
		layer.AnchorPoint = Vector2.new(0.5, 0.5)
		layer.BackgroundTransparency = 1
		layer.Position = UDim2.fromScale(0.5, 0.5)
		layer.Size = UDim2.new(1, offset * 2, 1, offset * 2)
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Transparency = 1 - opacity
		stroke.Parent = layer
		if parent:FindFirstChildOfClass("UICorner") then
			local corner = parent:FindFirstChildOfClass("UICorner") :: UICorner
			corner = corner:Clone()
			corner.Parent = layer
		end
		layer.Parent = layers
	end
	return layers
end
