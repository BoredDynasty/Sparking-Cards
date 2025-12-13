--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local trove = require(ReplicatedStorage.Packages.trove)

local module = {}

local tag = "PosterizeEffect"

local camera = gamecamera.camera

local _trove = trove.new()

function module:Clear()
	for i, post_processing in ipairs(Lighting:GetChildren()) do
		if post_processing:IsA("ColorCorrectionEffect") then
			if not string.find(post_processing.Name, tag) then
				continue
			end

			post_processing:Destroy()
		end
	end

	_trove:Clean()
end

function module:On()
	local position = observer.new(CFrame.new())
	local size = vector.create(49.15, 32.2, 0.001)

	local offset = CFrame.new(0, 0, -1.01)

	local color_correction = Instance.new("ColorCorrectionEffect")
	hydration(color_correction) {
		Brightness = -1,
		Contrast = 100,
		Saturation = -0.1,
		Name = tag,
		Parent = Lighting,
	}

	local part = Instance.new("Part")
	hydration(part) {
		CastShadow = false,
		CanCollide = false,
		CanQuery = false,
		Anchored = true,
		Size = size,
		Transparency = 1,
		Name = "ContrastPart",
		Parent = workspace,
		CFrame = position,
	}

	local surface_gui = Instance.new("SurfaceGui")
	hydration(surface_gui) {
		Adornee = part,
		Face = Enum.NormalId.Back,
		Parent = part,
		AlwaysOnTop = true,
		LightInfluence = 0,
	}

	local frame = Instance.new("Frame")
	hydration(frame) {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(128, 128, 128),
		BackgroundTransparency = 0.015,
		BorderSizePixel = 0,
		Parent = surface_gui,
	}

	local conn = RunService.PreRender:Connect(function(deltaTime)
		-- when we change the position variable, it automatically updates the CFrame of the part
		position:Set(camera.CFrame * offset)
	end)

	_trove:Add(conn)
	_trove:Add(part)
	_trove:Add(position :: any, "Destroy")
end

return module
