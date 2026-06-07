--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local hydration = require(ReplicatedStorage.Utility.hydration)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)

-- ability-controller.luau

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local root_part = humanoid.RootPart :: BasePart

-- variables:

local attachment = Instance.new("Attachment")
attachment.Parent = root_part

local linear_velocity = Instance.new("LinearVelocity")
hydration(linear_velocity) {
	Attachment0 = attachment,
	MaxForce = math.huge, -- AKA your mom
	Enabled = false,
	Parent = root_part,
}

local juke_limit = ratelimit(2, 5)
local spin_limit = ratelimit(2, 4)

local module = {}

function module:Juke(direction: "Left" | "Right")
	if not juke_limit() then
		return
	end

	-- prevent this while airborne.
	if humanoid.FloorMaterial == Enum.Material.Air then
		return
	end

	local power = 60

	local lateral = root_part.CFrame.RightVector
	if direction == "Left" then
		lateral = -lateral
	end

	linear_velocity.VectorVelocity = lateral * power
	linear_velocity.Enabled = true

	-- slowly reduce the velocity to zero over 0.3 seconds
	local t_info = TweenInfo.new(0.3, Enum.EasingStyle.Quad)

	local tween = TweenService:Create(linear_velocity, t_info, {
		VectorVelocity = Vector3.new(0, 0, 0),
	})

	tween:Play()

	task.delay(0.30, function()
		linear_velocity.Enabled = false
	end)

	-- drain stamina
	local current_stamina = character:GetAttribute("Stamina") :: number or 0

	local drain_rate = 12

	local new_stamina = math.max(0, current_stamina - drain_rate)

	character:SetAttribute("Stamina", new_stamina)
end

function module:Spin()
	if not spin_limit() then
		return
	end

	-- prevent this while airborne.
	if humanoid.FloorMaterial == Enum.Material.Air then
		return
	end

	humanoid.AutoRotate = false

	local t_info = TweenInfo.new(0.3, Enum.EasingStyle.Quad)

	local tween = TweenService:Create(root_part, t_info, {
		CFrame = root_part.CFrame * CFrame.Angles(0, math.rad(360), 0),
	})

	tween:Play()
	tween.Completed:Connect(function()
		humanoid.AutoRotate = true
	end)

	--TODO) add forward burst during spin
end

return module
