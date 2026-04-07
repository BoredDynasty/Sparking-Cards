--!strict
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local bezier_tween = require(ReplicatedStorage.Modules.Animation["bezier-tween"])
local future = require(ReplicatedStorage.Packages.future)
local scatter = require(ReplicatedStorage.Modules.Animation.scatter)
local waypoints = require(ReplicatedStorage.Modules.Geometry.waypoints)

-- no-freefall.luau
-- no freefall rewrite rewrite

local module = {}

PhysicsService:RegisterCollisionGroup("FreefallPlayers")

local points_folder = workspace:WaitForChild("Points")

local collisions = {}
local parts: { BasePart } = {}

local function nearestToCharacter(position: Vector3, group: Instance): BasePart
	local closest_part, closest_part_magnitude = nil, 0

	local tmp_magnitude
	for i, part in ipairs(group:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		if closest_part then
			tmp_magnitude = (position - part.Position).Magnitude

			if tmp_magnitude < closest_part_magnitude then
				closest_part = part
				closest_part_magnitude = tmp_magnitude
			end
		else
			closest_part = part
			closest_part_magnitude = (position - part.Position).Magnitude
		end
	end

	return closest_part :: BasePart
end

local function roundVector(vec3: Vector3, unit: number)
	return vec3 - Vector3.new(vec3.X % unit, vec3.Y % unit, vec3.Z % unit)
end

local function clearParts()
	for i, part in ipairs(parts) do
		part:Destroy()
	end

	table.clear(parts)
end

local function poof(character: Model)
	local root_part = character:WaitForChild("HumanoidRootPart") :: BasePart

	local poof_template = Instance.new("Part")
	poof_template.Position = root_part.Position
	poof_template.Anchored = true
	poof_template.CanCollide = false
	poof_template.Transparency = 1
	poof_template.CastShadow = false

	for i = 1, 50 do
		local clone = poof_template:Clone()
		clone.Parent = workspace
		clone.Material = Enum.Material.SmoothPlastic
		clone.BrickColor = BrickColor.random()
		clone.Transparency = 0
		clone.Name = "Effect"

		scatter:Out(clone)
		-- add a size factor
		local size_factor = math.random(5, 15) / 10
		local tween = TweenService:Create(clone, TweenInfo.new(0.5), {
			Size = Vector3.new(1, 1, 1) * size_factor,
			Transparency = 1,
		})
		tween:Play()
	end

	poof_template:Destroy()
end

local function makeCharacterVisible(character: Model, value: number)
	for i, part in ipairs(character:GetDescendants()) do
		if (part:IsA("BasePart") or part:IsA("Decal")) and part.Name ~= "HumanoidRootPart" then
			part.Transparency = value
		end
	end
end

local function effects(character: Model, bool: boolean)
	local root_part = character:WaitForChild("HumanoidRootPart") :: BasePart

	-- create
	if bool then
		local trail = Instance.new("Trail")
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		trail.FaceCamera = true
		trail.LightEmission = 1
		trail.LightInfluence = 1
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.0149, 0),
			NumberSequenceKeypoint.new(1, 0),
		})
		trail.Enabled = true
		trail.Lifetime = 0.5
		trail.MaxLength = 0
		trail.MinLength = 0.05
		trail.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.0379, 0.594),
			NumberSequenceKeypoint.new(0.2, 0.856),
			NumberSequenceKeypoint.new(0.8, 0.85),
			NumberSequenceKeypoint.new(0.916, 0.65),
			NumberSequenceKeypoint.new(1, 0),
		})

		local attachment0 = Instance.new("Attachment", root_part)
		attachment0.Position = Vector3.new(1, 0, 0)
		attachment0.Name = "A0"

		local attachment1 = Instance.new("Attachment", root_part)
		attachment1.Position = Vector3.new(-1, 0, 0)
		attachment1.Name = "A1"

		trail.Parent = root_part
		trail.Attachment0 = attachment0
		trail.Attachment1 = attachment1
	else
		-- destroy
		future.Try(function()
			root_part:WaitForChild("Trail"):Destroy()
			root_part:WaitForChild("A0"):Destroy()
			root_part:WaitForChild("A1"):Destroy()
		end)
	end
end

local function collisions(character: Model, bool)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("Part") or part:IsA("MeshPart") then
			if bool then
				part.CollisionGroup = "FreefallPlayers"
			else
				part.CollisionGroup = "Default"
			end
		end
	end
end

function module:Fire(character: Model)
	if not character then
		warn("not valid character: ", typeof(character), character)
	end

	if character:GetAttribute("IsFreefall") == true then
		warn("freefall is already active")
	end

	character:SetAttribute("IsFreefall", true)

	local root_part = character:WaitForChild("HumanoidRootPart") :: BasePart

	-- TODO: add sounds

	local end_position = nearestToCharacter(root_part.Position, points_folder).Position
	local start_position = root_part.Position + Vector3.new(0, 0, -3)
	local control = (
		root_part.Position
		+ Vector3.new(start_position.X - end_position.X, 200, start_position.Z - end_position.Z)
	)

	local waypoints_ = waypoints:FromVec3(start_position, control, end_position)

	local body_position = Instance.new("BodyPosition")
	body_position.MaxForce = Vector3.one * math.huge
	body_position.Parent = root_part
	body_position.D = 1800
	body_position.P = 20000
	body_position.Position = root_part.Position

	local tween = bezier_tween.new(root_part, "Position", waypoints_)

	collisions(character, true)
	poof(character)
	effects(character, true)
	makeCharacterVisible(character, 1)

	tween.Signal:Wait()

	repeat
		body_position.P += 100
		task.wait()
	until roundVector(root_part.Position, 1) == roundVector(end_position, 1)

	body_position:Destroy()
	poof(character)
	effects(character, false)
	makeCharacterVisible(character, 0)

	character:SetAttribute("IsFreefall", false)

	collisions(character, false)

	task.delay(3, clearParts)
end

return module
