--!strict

-- image-mask.luau

-- original by Boatbomber.
-- https://github.com/boatbomber/ImageMask/

local module = {}

local camera = Instance.new("Camera")
camera.FieldOfView = 20

local viewport = Instance.new("ViewportFrame")
viewport.BackgroundColor3 = Color3.new()
viewport.BackgroundTransparency = 1
viewport.LightDirection = Vector3.new(0, 1, 0)
viewport.Ambient = Color3.new(1, 1, 1)
viewport.Size = UDim2.new(0, 100, 0, 100)

local decal = Instance.new("Decal")
decal.Face = Enum.NormalId.Top

local clipper_size = Vector3.new(1, 0.1, 1)
local clipper_cf = CFrame.new(0, -0.1, 0)

function module.new(id, type_: string)
	local clipper
end
