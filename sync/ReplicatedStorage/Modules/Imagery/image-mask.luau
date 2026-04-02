--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local mask_folder = ReplicatedStorage.Assets.ImageMasks

--[[
   types:
   - "Circle"
   - "RoundedSquare"
   - "Star"
   - "Triangle"
   - "Rhombus"
   
   @return `ViewportFrame`, `MeshPart`
]]
function module.new(id: string, type_: string)
	-- run a sanity check
	assert(
		type_ and type(type_) == "string" and mask_folder:FindFirstChild(type_),
		"Expected type to be a string."
	)

	local clipper = mask_folder:WaitForChild(type_):Clone() :: MeshPart
	clipper.Size = clipper_size
	clipper.CFrame = clipper_cf
	clipper.Transparency = 1

	local image = decal:Clone()
	image.Texture = id

	local cam = camera:Clone()
	cam.CFrame = CFrame.new(
		Vector3.new(0, (math.max(clipper.Size.X, clipper.Size.Z) / 2) / 0.17, 0),
		Vector3.new()
	) * CFrame.Angles(0, 0, -1.5707963267949)

	local vp = viewport:Clone()
	vp.CurrentCamera = cam

	-- finalize
	image.Parent = clipper
	clipper.Parent = vp
	cam.Parent = vp -- if frame is deleted, the camera will be garbage collected, and the viewport will stop rendering

	return vp, clipper
end

return module
