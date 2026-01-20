--!strict

-- beam.luau

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Workspace = game:GetService("Workspace")

local _damage = require(ReplicatedStorage.Combat.Strike.damage)

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local beam_module = {}
beam_module.__index = beam_module

export type BeamParams = {
	origin: Vector3,
	direction: Vector3?,
	target: Vector3?,
	maxDistance: number?,
	speed: number?,
	width: number?,
	color: Color3?,
	texture: string?,
	damage: number?,
	falloff: boolean?,
	pierce: boolean?,
	pierceCount: number?,
	ignoredInstances: { Instance }?,
	source: Model?, -- used for damage attribution
	lifeTime: number?, -- visual life time
	hitParticle: ParticleEmitter?, -- optional particle effect to play at hit point
	onHit: ((hitResult: { position: Vector3, instance: Instance }, humanoid: Humanoid, part: BasePart) -> ())?, -- optional callback on hit
}

local function createAttachmentPart(position: Vector3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(position)
	part.Parent = Workspace
	local att = Instance.new("Attachment")
	att.Parent = part
	return part, att
end

local function makeBeam(att0: Attachment, att1: Attachment, width: number, color: Color3?, texture: string)
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

local function isDescendantIgnored(hitInstance: Instance, ignored: { Instance })
	if not hitInstance then
		return false
	end

	for _, inst in ipairs(ignored) do
		if inst and (hitInstance:IsDescendantOf(inst) or hitInstance == inst) then
			return true
		end
	end
	return false
end

-- Utility to find humanoid from a hit part
local function getHumanoidFromPart(part: BasePart): (Humanoid?, Model?)
	if not part then
		return nil, nil
	end
	local player = playerMarshaller.getFromCharacter(part:FindFirstAncestorOfClass("Model") :: Model)

	if player then
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character.Humanoid

		return humanoid, character
	end

	return nil, nil
end

--[[
   Fires a hitscan beam from origin in direction (or towards target) up to maxDistance,

   dealing damage to the first humanoid hit (or multiple if piercing).

   @param origin: Vector3,
	@param direction: Vector3?,
	@param target: Vector3?,
	@param maxDistance: number?,
	@param speed: number?,
	@param width: number?,
	@param color: Color3?,
	@param texture: string?,
	@param damage: number?,
	@param falloff: boolean?,
	@param pierce: boolean?,
	@param pierceCount: number?,
	@param ignoredInstances: { Instance }?,
	@param source: Model?, -- used for damage attribution
	@param lifeTime: number?, -- visual life time
	@param hitParticle: ParticleEmitter?, -- optional particle effect to play at hit point
	@param onHit: ((hitResult: { position: Vector3, instance: Instance }, humanoid: Humanoid, part: BasePart) -> ())?, -- optional callback on hit
]]
function beam_module.Fire(params: BeamParams)
	assert(params and params.origin, "beam_module.Fire: origin required")

	local origin = params.origin
	local direction = nil

	if params.target then
		direction = (params.target - origin).Unit
	elseif params.direction then
		direction = params.direction.Unit
	else
		warn("beam_module.Fire: either direction or target required")
		return
	end

	local maxDistance = params.maxDistance or 300
	--local speed = params.speed or math.huge
	local width = params.width or 0.25

	local color = params.color or Color3.fromRGB(255, 200, 100)

	local lifetime = params.lifeTime or 0.6
	local damage = params.damage or 10

	local falloff = params.falloff == nil and true or params.falloff

	local pierce = params.pierce or false
	local pierceCount = (params.pierceCount ~= nil) and params.pierceCount or (pierce and math.huge or 1)

	local ignored = params.ignoredInstances or {}

	local source = params.source
	local onHit = params.onHit

	-- Setup raycasting params
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignored
	rayParams.IgnoreWater = true

	local remaining = maxDistance
	local currentOrigin = origin
	local hits = 0

	local visualParts = {}

	while remaining > 0 and hits < pierceCount do
		local rayResult = Workspace:Raycast(currentOrigin, direction * remaining, rayParams)

		local hitPos, hitInstance, distanceTraveled = nil, nil, remaining

		if rayResult then
			hitPos = rayResult.Position
			hitInstance = rayResult.Instance
			distanceTraveled = (hitPos - currentOrigin).Magnitude
		else
			hitPos = currentOrigin + direction * remaining
			distanceTraveled = remaining
		end

		-- Visual: create attachments & beam between currentOrigin and hitPos
		local partA, attA = createAttachmentPart(currentOrigin)
		local partB, attB = createAttachmentPart(hitPos)

		table.insert(visualParts, partA)
		table.insert(visualParts, partB)

		local beam = makeBeam(attA, attB, width, color, params.texture or "")
		-- optional glow particle at hit
		if params.hitParticle then
			local particle = params.hitParticle:Clone()
			particle.Parent = partB
			particle.Enabled = true

			particle:Emit(1)

			Debris:AddItem(particle, lifetime)
		end

		-- Damage handling if we hit something relevant
		if hitInstance and not isDescendantIgnored(hitInstance, ignored) then
			local humanoid, model = getHumanoidFromPart(hitInstance)
			if humanoid and humanoid.Health > 0 then
				hits = hits + 1
				-- compute damage with falloff

				local appliedDamage = damage

				if falloff then
					local distFromOrigin = (currentOrigin - origin).Magnitude + distanceTraveled

					local factor = math.max(0, 1 - (distFromOrigin / maxDistance))
					appliedDamage = math.max(0, math.floor(appliedDamage * factor + 0.5))

					if appliedDamage <= 0 then
						appliedDamage = 1
					end
				end

				if onHit then
					onHit({ position = hitPos, instance = hitInstance }, humanoid, hitInstance :: BasePart)
				else
					_damage.__call({
						amount = appliedDamage,
						source = source and playerMarshaller.getFromCharacter(source),
						target = model and playerMarshaller.getFromCharacter(model),
					})
				end
			else
				-- hit non-humanoid part: still counts as a hit for piercing behaviour if configured
				if not pierce then
					hits = hits + 1
				end
			end
		else
			-- no hit -> beam ended on empty space
			hits = hits + 1
		end

		-- Move origin forward to continue pierce
		if rayResult then
			-- nudge slightly forward so we don't immediately hit the same part
			local epsilon = 0.5

			currentOrigin = hitPos + direction * epsilon
			remaining = remaining - distanceTraveled - epsilon

			-- if not piercing, break
			if not pierce then
				break
			end
		else
			break
		end
	end

	-- cleanup visuals after lifetime
	for _, p in ipairs(visualParts :: { Instance }) do
		Debris:AddItem(p, lifetime)
	end

	print("Boom!")
end

return beam_module
