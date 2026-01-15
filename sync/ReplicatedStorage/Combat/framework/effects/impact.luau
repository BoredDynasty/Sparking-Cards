--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- impact.luau

-- This module handles the impact effects of attacks in the combat framework.

local vfxFolder = ReplicatedStorage.Assets.VisualEffects

export type ImpactEffect = {
	position: Vector3,
	direction: Vector3,
	magnitude: number,
	duration: number,
}

local function impactNameToAsset(name: string): Instance?
	-- Convert the impact name to an asset path
	local assetNames = {
		["CraterDust"] = vfxFolder.CraterDust,
		["Impact"] = vfxFolder.Impact,
		["Wind"] = vfxFolder.hit_wind,
	}
	return assetNames[name]
end

--[[
	@param position Vector3
	@param direction Vector3
	@param magnitude number
	@param duration number
]]
return function(impact: ImpactEffect)
	local asset = impactNameToAsset(impact.name)
	if not asset then
		error("Impact effect asset not found for name: " .. impact.name)
	end

	local effectInstance = asset:Clone()
	effectInstance.Position = impact.position
	effectInstance.Orientation =
		Vector3.new(0, math.atan2(impact.direction.X, impact.direction.Z) * (180 / math.pi), 0)

	-- Set the magnitude and duration of the effect
	effectInstance.Size = Vector3.new(impact.magnitude, impact.magnitude, impact.magnitude)
	effectInstance.Transparency = 1 -- Set transparency to 1 for visibility

	-- Play the effect
	effectInstance.Parent = workspace
	for _, emitter: ParticleEmitter in ipairs(effectInstance:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			local emitCount = emitter:GetAttribute("EmitCount") or 1
			emitter:Emit(emitCount * impact.magnitude) -- Emit particles based on the magnitude
		end
	end
	task.delay(impact.duration, function()
		effectInstance:Destroy()
	end)

	return effectInstance
end
