local Functions = {}

function Functions:CreateHairs(Parent, X, Y)
	local Hairs 	= {}

	for I = 1, 7 do
		local Frame 		= Instance.new("ImageLabel")
		Frame.Image 		= ''
		Frame.Name 			= "_hair"
		Frame.Parent 		= Parent
		Frame.AnchorPoint 	= Vector2.new(0.5, 0.5)

		if I < 3 then
			Frame.Size 		= UDim2.fromOffset(Y, X)
		elseif I > 2 and I < 5 then
			Frame.Size 		= UDim2.fromOffset(X, Y)
		elseif I == 5 then
			Frame.BackgroundTransparency	= 1
			Frame.Size 						= UDim2.fromOffset(50, 50)
			Frame.Image 					= 'rbxassetid://285779644'
			Frame.Name 						= "HitMarker"
			Frame.ImageTransparency			= 1
		elseif I == 6 then
			Frame.BackgroundTransparency	= 1
			Frame.Size 						= UDim2.fromOffset(10, 10)
			Frame.Image 					= 'rbxassetid://11003529439'
			Frame.Name 						= "CenterDot"
			Frame.ImageTransparency			= 0
			Frame.Visible 					= false
		else
			Frame.BackgroundTransparency	= 1
			Frame.Name 						= 'ImageCrosshair'
			Frame.Visible 					= false
		end

		table.insert(Hairs, I, Frame)
	end

	return unpack(Hairs)
end

function Functions:RandomPointsInsideCrosshair(Offset)
	local R 			= Offset * math.sqrt(math.random())
	local Theta 		= math.random() * 2 * math.pi
	local X 			= R * math.cos(Theta)
	local Y 			= R * math.sin(Theta)

	return X, Y
end


function Functions:UpdateEnabled(UI, Bool)
	for _, Item in pairs(UI) do
		Item.Visible = Bool
	end
end

return Functions