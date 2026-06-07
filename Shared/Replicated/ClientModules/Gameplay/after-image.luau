--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)
local spr = require(ReplicatedStorage.Modules.spr)

-- after-image.luau
-- creates afterimage effects.
-- best examples are in animes and cartoons

-- let's try to make this module ***performant***
-- big emphasis on the word "performant"

local module = {}

local function afterImageFix(after_image: Instance, character: Model, life: number)
	for i, base_part in ipairs(after_image:GetChildren()) do
		if base_part:IsA("MeshPart") or base_part:IsA("BasePart") or base_part:IsA("UnionOperation") then
			local counterpart = character:FindFirstChild(base_part.Name) :: BasePart
			if not counterpart then
				continue
			end

			hydration(base_part) {
				CollisionGroup = "AfterImage",
				Orientation = counterpart.Orientation,
				Position = counterpart.Position,
				CanCollide = false,
				Anchored = true,
			}

			CollectionService:AddTag(base_part, "IgnoreCamera")

			-- seconds to spring frequency
			local frequency = 1 / life

			spr.target(base_part, 1, frequency, {
				Transparency = 1,
			})
		end
	end
end

function module.new(character: Model, life: number)
	if not character then
		return
	end

	character.Archivable = true

	local clone = character:Clone()
	clone.Name = "AfterImage" .. character.Name
	clone.Parent = workspace.AfterImageCache

	CollectionService:AddTag(clone, "IgnoreCamera")

	afterImageFix(clone, character, life)

	task.delay(life + 2, function()
		clone:Destroy()
	end)
end

return module
