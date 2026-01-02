--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local hydration = require(ReplicatedStorage.Utility.hydration)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

-- health-pulse.luau
-- a pulse effect for when you're low on health

local module = {}

local pulse_speed = 3
local max_fov = 73
local min_fov = 67 -- SIX SEVEN AHHAHAHAHAHA
local max_blur_effect = 5 -- clamp(x, 0, 5)
local max_transparency = 0.3 -- clamp(x, 0, 1)
local base_blur = 0 -- the blur size at full health

local _trove = trove.new()

local tag = "Pulse"

local camera = gamecamera:GetCamera()

local player = playerMarshaller.get()
local player_gui = player.PlayerGui

function module:On()
	local screen_gui = _trove:Construct(Instance, "ScreenGui", player_gui) :: LayerCollector
	hydration(screen_gui) {
		Name = tag,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	}

	local background = _trove:Construct(Instance, "Frame", screen_gui) :: Frame
	hydration(background) {
		Name = tag .. "Frame",
		BackgroundColor3 = Color3.fromRGB(136, 21, 21),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		ZIndex = 0,
	}

	local blur = _trove:Construct(Instance, "BlurEffect", Lighting) :: BlurEffect
	hydration(blur) {
		Name = tag,
		Size = base_blur,
	}

	_trove:Connect(RunService.PreRender, function(deltaTime: number)
		-- calculate
		local sine = math.sin(os.time() * pulse_speed)

		local blur_size = base_blur + sine * max_blur_effect
		local field_of_view = min_fov + (sine + 1) / 2 * (max_fov - min_fov)
		local background_transparency = 1 - math.clamp((0.3 + 0.2 * sine), 0, max_transparency)

		-- set the properties
		blur.Size = blur_size
		camera.FieldOfView = field_of_view
		background.BackgroundTransparency = background_transparency
	end)
end

function module:Off()
	_trove:Clean()

	camera.FieldOfView = 70
end

return module
