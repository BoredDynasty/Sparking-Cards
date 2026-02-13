--!strict
--!optimize 2
-- Pooler+
-- riftkuro '25

local Constants = {}

-- timing intervals (in seconds)
Constants.OPTIMIZE_INTERVAL = 30
Constants.ADAPTIVE_PRELOAD_INTERVAL = 15
Constants.VALIDATION_INTERVAL = 60

-- memory thresholds (in MB)
Constants.MEMORY_PRESSURE_MODERATE = 700
Constants.MEMORY_PRESSURE_CRITICAL = 2000
Constants.GC_MEMORY_THRESHOLD = 300
Constants.GC_OPTIMIZATION_THRESHOLD = 1024 * 1024 -- 1MB

-- pool optimization ratios
Constants.CRITICAL_MEMORY_RATIO = 0.25 -- keep 25% during critical pressure
Constants.MODERATE_MEMORY_RATIO = 0.5 -- keep 50% during moderate pressure
Constants.PEAK_USAGE_RATIO = 0.7 -- use 70% of peak for adaptive preload

-- analytics limits
Constants.MAX_LIFETIME_SAMPLES = 100
Constants.MAX_RATE_SAMPLES = 60
Constants.MIN_REASONABLE_POOL_SIZE = 10

-- memory usage estimates (in bytes)
Constants.MEMORY_ESTIMATES = {
	Part = 1024, -- ~1KB per part
	GuiObject = 512, -- ~512B per GUI object
	Instance = 256, -- ~256B for other instances
	Table = 128, -- ~128B for tables
	Other = 64, -- ~64B for other objects
}

Constants.PRIORITY_VALUES = {
	low = 1,
	normal = 2,
	high = 3,
	critical = 4,
}

-- default reset properties for different instance types
Constants.DEFAULT_RESET_PROPERTIES = {
	BasePart = {
		"CFrame",
		"Position",
		"Orientation",
		"Size",
		"Color",
		"Material",
		"Transparency",
		"CanCollide",
		"Anchored",
		"Velocity",
		"AngularVelocity",
		"Shape",
	},
	GuiObject = {
		"Position",
		"Size",
		"AnchorPoint",
		"Rotation",
		"Visible",
		"BackgroundColor3",
		"BackgroundTransparency",
		"BorderColor3",
		"BorderSizePixel",
		"ZIndex",
	},
	TextLabel = {
		"Text",
		"TextColor3",
		"TextTransparency",
		"TextScaled",
		"Font",
		"TextSize",
	},
	ImageLabel = {
		"Image",
		"ImageColor3",
		"ImageTransparency",
		"ImageRectOffset",
		"ImageRectSize",
	},
	Frame = {},
	Part = {},
	Model = {
		"PrimaryPart",
	},
}

Constants.BASE_PROPERTIES = { "Name", "Parent" }

return Constants
