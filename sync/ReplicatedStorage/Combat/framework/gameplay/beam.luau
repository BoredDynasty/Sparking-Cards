--!strict
-- beam.luau

local module = {}
module.__index = module

export type BeamParams = {
	origin: Vector3,
	direction: Vector3?,
	target: Vector3?,
	max_distance: number?,
	speed: number?,
	width: number?,
	color: Color3?,
	texture: string?,
	damage: number?,
	falloff: boolean?,
	pierce: boolean?,
	pierce_count: number?,
	ignored_instances: { Instance }?,
	source: Model?, -- used for damage attribution
	life_time: number?, -- visual life time
	hit_particle: ParticleEmitter?, -- optional particle effect to play at hit point
}

local function createAttachmentPart(position: Vector3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(position)
	part.Parent = workspace

	local att = Instance.new("Attachment")
	att.Parent = part

	return part, att
end

local function createBeam(att0: Attachment, att1: Attachment, width: number, texture: string, color: Color3?)
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.FaceCamera = true
	beam.Width0 = width
	beam.Width1 = width
	beam.Segments = 8

	if color then
		local color_sequence = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(1, color),
		})

		--cp0.Keypoints = { ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(1, color) }

		beam.Color = color_sequence
	end

	beam.Texture = texture or ""
	beam.Parent = att0.Parent -- attach to one of the parts

	return beam
end

local function is_descendant_ignored(instance: Instance, ignored: { Instance })
	if not instance then
		return false
	end

	for i, inst in ipairs(ignored) do
		if inst and instance:IsDescendantOf(inst) or inst == instance then
			return true
		end
	end

	return false
end

-- we will use raycasting here.
function module.fire(params: BeamParams)
	if not params.origin then
		warn("origin required to fire a beam.")
		return
	end

	local direction = params.direction
		or (params.target and (params.target - params.origin).Unit)
		or Vector3.new(0, 0, -1)
	local max_distance = params.max_distance or 1000

	local end_position = params.origin + direction * max_distance

	-- raycast params

	local raycast_params = RaycastParams.new()
	raycast_params.FilterType = Enum.RaycastFilterType.Blacklist
	raycast_params.IgnoreWater = true
	raycast_params.FilterDescendantsInstances = params.ignored_instances or {}

	local raycast_result = workspace:Raycast(params.origin, direction * max_distance, raycast_params)

	-- determine beam end position
	local hit_position = end_position
	local hit_instance = nil

	if raycast_result then
		hit_position = raycast_result.Position
		hit_instance = raycast_result.Instance
	end

	-- create visual beam
	local origin_part, origin_att = createAttachmentPart(params.origin)
	local end_part, end_att = createAttachmentPart(hit_position)

	local beam = createBeam(origin_att, end_att, params.width or 0.5, params.texture, params.color)

	-- handle pierce logic
	local pierce_count = params.pierce_count or 1
	local hit_instances = {}

	if
		raycast_result
		and hit_instance
		and not is_descendant_ignored(hit_instance, params.ignored_instances or {})
	then
		-- find the character or model that was hit
		local humanoid = hit_instance:FindFirstChild("Humanoid")
		local character = humanoid and hit_instance.Parent or hit_instance:FindFirstAncestorOfClass("Model")

		if character and not table.find(hit_instances, character) then
			table.insert(hit_instances, character)

			-- deal damage if damage is specified
			if params.damage and humanoid then
				humanoid:TakeDamage(params.damage)
			end

			-- apply falloff if enabled
			local adjusted_damage = params.damage or 0
			if params.falloff and humanoid then
				local distance = (hit_position - params.origin).Magnitude
				adjusted_damage = adjusted_damage
					* math.max(0, 1 - (distance / (params.max_distance or 1000)))
			end

			-- play hit particle if provided
			if params.hit_particle then
				local particle_clone = params.hit_particle:Clone()
				particle_clone.Parent = hit_instance
				game:GetService("Debris"):AddItem(particle_clone, 0.5)
			end
		end

		-- continue pierce if enabled and pierce count available
		if params.pierce and pierce_count > 1 then
			-- TODO: implement pierce continuation from hit position
		end
	end

	-- cleanup beams and parts after lifetime
	local lifetime = params.life_time or 0.5
	game:GetService("Debris"):AddItem(origin_part, lifetime)
	game:GetService("Debris"):AddItem(end_part, lifetime)
end

return module
