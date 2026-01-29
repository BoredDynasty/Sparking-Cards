--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local spr = require(ReplicatedStorage.Modules.spr)

-- transition.luau
-- ui transitions

local module = {}

export type config = {
	duration: number,
}

local player = playerMarshaller.get()
local player_gui = player.PlayerGui

local state = observer.new(false)

local function createLayerCollector(ancestor: Instance?)
	local layer_collector = Instance.new("ScreenGui")
	hydration(layer_collector) {
		Parent = ancestor or ReplicatedStorage,
		Name = "TransitionScreen",
		IgnoreGuiInset = true,
		Enabled = true,
		DisplayOrder = math.huge, -- your mom :speed-try-not-to-laugh:
	}

	return layer_collector
end

--[[
   Uses UI strokes
]]
function module:Circle(config: config?)
	if state:Get() then
		print("transition cooldown")

		return
	end

	config = config or {
		duration = 5,
	}

	state:Set(true)

	local layer_colletor = createLayerCollector(player_gui)

	local circle = Instance.new("Frame")
	hydration(circle) {
		Parent = layer_colletor,
		Name = "Circle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 10,
	}

	local ui_stroke = Instance.new("UIStroke")
	hydration(ui_stroke) {
		Parent = circle,
		Color = Color3.new(1, 1, 1),
		Thickness = 4,
	}

	spr.target(ui_stroke, 1, 1 / (config.duration or 1), {
		Thickness = 2000,
	})

	spr.completed(ui_stroke, function()
		spr.target(ui_stroke, 1, 1 / (config.duration or 1), {
			Thickness = 4,
		})
	end)

	spr.completed(ui_stroke, function()
		circle:Destroy()
		layer_colletor:Destroy()
		state:Set(false)
	end)
end

return module
