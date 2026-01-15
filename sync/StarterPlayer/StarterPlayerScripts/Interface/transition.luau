--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

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
function module:Circle(config: config)
	if state:Get() then
		print("transition cooldown")

		return
	end

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

	local goal = {
		Thickness = 2000,
	}

	local tween = TweenPlus(ui_stroke, goal, {
		Time = config.duration or 1,
		EasingStyle = "Quad",
		EasingDirection = "InOut",
	})

	tween:Start()
	tween.Completed:Wait()

	local tween2 = TweenPlus(ui_stroke, {
		Thickness = 0,
	}, {
		Time = config.duration or 1,
		EasingStyle = "Quad",
		EasingDirection = "InOut",
	})

	tween2:Start()
	tween2.Completed:Wait()

	layer_colletor:Destroy()
	state:Set(false)
end

return module
