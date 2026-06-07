--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)

-- terrain-deformation.luau
-- for deforming terrain on the client.
-- e.g stepping on soft terrain makes a dent. (snow, mud, etc)

local module = {}

local dynamic_deformation = observer.new(false)

--[[
   dynamic deformation has to be off
]]
local tween_down_studs = 0.7
local reset_time = 20
local normal_radius = 0.6
local deformation_plates = {} :: { BasePart }

local raycast_params = RaycastParams.new()
raycast_params.CollisionGroup = "DynamicDeformation"

local function deformBone(bone: Bone, attachment: Attachment)
	bone:SetAttribute("IsDeformed", true)

	local original_position = bone.Position

	if not dynamic_deformation:Get() then
		if bone:GetAttribute("IsDeformed") ~= false then
			task.spawn(function()
				repeat
					task.wait()
					bone.Position += Vector3.new(0, -0.04, 0)
				until bone.Position.Y < original_position.Y - tween_down_studs
			end)

			task.wait(reset_time)

			bone.Position = original_position

			bone:SetAttribute("IsDeformed", false)
		end
	else
		local ray = workspace:Raycast(bone.WorldPosition, Vector3.new(0, -90, 0), raycast_params)
		if not ray then
			return
		end

		local tween_down = (bone.WorldPosition - ray.Position).Magnitude - 0.3

		if bone:GetAttribute("IsDeformed") ~= false then
			task.spawn(function()
				repeat
					task.wait()
					bone.Position += Vector3.new(0, -0.04, 0)
				until bone.Position.Y < original_position.Y - tween_down
			end)

			task.wait(reset_time)

			bone.Position = original_position

			bone:SetAttribute("IsDeformed", false)
		end
	end
end

function module:Start()
	local conn = nil

	conn = RunService.RenderStepped:Connect(function(deltaTime)
		for i, plate in ipairs(deformation_plates) do
			local hitbox = plate:FindFirstChild("Hitbox") :: BasePart

			local deformation_parts = workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size)

			for j, part: BasePart in ipairs(deformation_parts) do
				for t, attachment_1 in ipairs(part:GetChildren()) do
					if not attachment_1:IsA("Attachment") then
						continue
					end
					if attachment_1.Name ~= "DeformationNormalAttachment" then
						continue
					end

					for q, bone in ipairs(plate:GetChildren() :: { Bone }) do
						if not bone:GetAttribute("IsDeformed") then
							return
						end

						local distance = (bone.WorldPosition - attachment_1.WorldPosition).Magnitude

						if not (distance <= normal_radius) then
							return
						end

						deformBone(bone, attachment_1)
					end
				end
			end
		end
	end)

	return conn
end

function module:SetDynamic(boolean: boolean)
	return future.new(dynamic_deformation.Set, dynamic_deformation, boolean)
end

return module
