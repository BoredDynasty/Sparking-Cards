--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local hydration = require(ReplicatedStorage.Utility.hydration)
local settings_data = require(ReplicatedStorage.Structures["settings-data"])
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- health-pulse.luau
-- a pulse effect for when you're low on health

local module = {}

-- constants
local pulse_speed = 3
local max_fov = 73
local min_fov = 67 -- SIX SEVEN AHHAHAHAHAHA
local max_blur_effect = 5 -- clamp(x, 0, 5)
local max_transparency = 0.3 -- clamp(x, 0, 1)
local base_blur = 0 -- the blur size at full health

local _trove = trove.new()

local tag = "Pulse"

local camera = workspace.CurrentCamera

local player = Players.LocalPlayer
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
		spr.target(blur, 0.4, pulse_speed, {
			Size = blur_size,
		})
		spr.target(camera, 0.4, pulse_speed, {
			FieldOfView = field_of_view,
		})
		spr.target(background, 0.4, pulse_speed, {
			BackgroundTransparency = background_transparency,
		})
	end)
end

function module:Off()
	_trove:Clean()

	local profile = fetchProfile()

	local saved_options = {} :: { [string]: typemarshaller.SettingValue }

	if profile and profile.Data and type(profile.Data.options) == "table" then
		saved_options = profile.Data.options
	end

	spr.target(camera, 0.4, pulse_speed, {
		FieldOfView = saved_options.fov or 70,
	})
end

return module
