--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserGameSettings = game:GetService("UserGameSettings")

local future = require(ReplicatedStorage.Packages.future)
local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- ui-blur.luau

type BlurSettings = {
	Fragmented: boolean?, -- Little sunlight effect using displaced geometry
	Inverted: boolean?, -- Inverts the screen colors for that particular GuiObject
	StrokeSize: number?, -- Outer blur; "1" means the actual model is the same size as the frame (DepthOfField stuff)
}

local player = playerMarshaller.get()

local camera = gamecamera.camera

local depth_of_field = Instance.new("DepthOfFieldEffect")
hydration(depth_of_field) {
	Name = "UIBlur",
	FarIntensity = 0,
	FocusDistance = 0,
	InFocusRadius = 0,
	NearIntensity = 1,
	Parent = Lighting,
}

local container = camera:FindFirstChild("UIBlur") :: Folder
local inverted_container = container:FindFirstChild("Inverted") or Instance.new("Model")
inverted_container.Name = "Inverted"

local quality_level = UserGameSettings.SavedQualityLevel

local offset = 0.02
local inverted_instanes = observer.new(0)

local module = {}
module.__index = module

local function GetContainer(): Folder
	if not container then
		container = Instance.new("Folder")
		hydration(container) {
			Name = "UIBlur",
			Parent = camera,
		}

		inverted_container.Parent = container
	end
	return container
end

local function GenerateInverter()
	local highlight = inverted_container:FindFirstChild("Inverter") :: Highlight?
	if not highlight then
		highlight = Instance.new("Highlight")
		hydration(highlight) {
			Name = "Inverter",
			Adornee = inverted_container,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
			FillColor = Color3.new(0.5, 0.5, 0.5),
			FillTransparency = 1,
			OutlineColor = Color3.new(),
			OutlineTransparency = 1,
			Parent = inverted_container,
		}
	end
end

local function GenerateForEffect(object: BlurEffect)
	--
end

function module.new(interface: GuiObject, config: BlurSettings)
	local self = setmetatable({}, module)

	--
end
