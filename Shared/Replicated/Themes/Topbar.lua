return {

	-- When no state is specified the modification is applied to *all* states (Deselected, Selected and Viewing)
	{ "IconCorners", "CornerRadius", UDim.new(1, 0) },
	{ "Selection", "RotationSpeed", 1 },
	{ "Selection", "Size", UDim2.new(1, 0, 1, 1) },
	{ "Selection", "Position", UDim2.new(0, 0, 0, 0) },
	{
		"SelectionGradient",
		"Color",
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(86, 86, 86)),
		}),
	},

	-- When the icon is deselected
	{ "IconImage", "Image", "", "Deselected" },
	{ "IconLabel", "Text", "", "Deselected" },
	{ "IconLabel", "Position", UDim2.fromOffset(0, 0), "Deselected" }, -- 0, -1
	{ "Widget", "MinimumWidth", 44, "Deselected" },
	{ "Widget", "MinimumHeight", 44, "Deselected" },
	{ "Widget", "BorderSize", 4, "Deselected" },
	{ "IconButton", "BackgroundColor3", Color3.fromRGB(0, 0, 0), "Deselected" },
	{ "IconButton", "BackgroundTransparency", 0.3, "Deselected" },
	{ "IconImageScale", "Value", 0.5, "Deselected" },
	{ "IconImageCorner", "CornerRadius", UDim.new(0, 0), "Deselected" },
	{ "IconImage", "ImageColor3", Color3.fromRGB(255, 255, 255), "Deselected" },
	{ "IconImage", "ImageTransparency", 0, "Deselected" },
	{
		"IconLabel",
		"FontFace",
		Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		"Deselected",
	},
	{ "IconLabel", "TextSize", 16, "Deselected" },
	{ "IconSpot", "BackgroundTransparency", 1, "Deselected" },
	{ "IconOverlay", "BackgroundTransparency", 0.925, "Deselected" },
	{ "IconSpotGradient", "Enabled", false, "Deselected" },
	{ "IconGradient", "Enabled", false, "Deselected" },
	{ "ClickRegion", "Active", true, "Deselected" }, -- This is set to false within scrollers to ensure scroller can be dragged on mobile
	{ "Menu", "Active", false, "Deselected" },
	{ "ContentsList", "HorizontalAlignment", Enum.HorizontalAlignment.Center, "Deselected" },
	{ "Dropdown", "BackgroundColor3", Color3.fromRGB(0, 0, 0), "Deselected" },
	{ "Dropdown", "BackgroundTransparency", 0.3, "Deselected" },
	{ "Dropdown", "MaxIcons", 4, "Deselected" },
	{ "Menu", "MaxIcons", 4, "Deselected" },
	{ "Notice", "Position", UDim2.new(1, -12, 0, -1), "Deselected" },
	{ "Notice", "Size", UDim2.new(0, 20, 0, 20), "Deselected" },
	{ "NoticeLabel", "TextSize", 13, "Deselected" },
	{ "PaddingLeft", "Size", UDim2.new(0, 9, 1, 0), "Deselected" },
	{ "PaddingRight", "Size", UDim2.new(0, 11, 1, 0), "Deselected" },

	-- When the icon is selected
	-- Selected also inherits everything from Deselected if nothing is set
	{ "IconSpot", "BackgroundTransparency", 0, "Selected" },
	{ "IconSpot", "BackgroundColor3", Color3.fromHex("#675496"), "Selected" },
	{ "IconSpotGradient", "Enabled", true, "Selected" },
	{ "IconSpotGradient", "Rotation", 45, "Selected" },
	{
		"IconSpotGradient",
		"Color",
		ColorSequence.new(Color3.fromRGB(96, 98, 100), Color3.fromRGB(77, 78, 80)),
		"Selected",
	},

	-- When a cursor is hovering above, a controller highlighting, or touchpad (mobile) pressing (but not released)
	--{"IconSpot", "BackgroundTransparency", 0.75, "Viewing"},
}
