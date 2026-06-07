--!strict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local random = require(ReplicatedStorage.Utility.random)
local space = require(ReplicatedStorage.Modules.Serialization.space)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- emit-dust.luau
-- emits a dust part.
-- WIP

local pool = PoolerPlus:CreatePool("DustPool", function()
	return ReplicatedStorage.Assets.Dust:Clone()
end)

pool:AdaptivePreload()

type BrickParticle = {
	amount: number,
	lifetime: number,
	size_range: NumberRange,
	force: Vector3,
	spin: number,
	fade_time: number,
	collision: boolean,
}

local defaults: BrickParticle = {
	amount = 20,
	lifetime = 1.8,
	size_range = NumberRange.new(0.3, 0.5),
	force = Vector3.new(25, 35, 25),
	spin = 10,
	fade_time = 0.4,
	collision = false,
}

local function randomRange(range: NumberRange)
	return random.float() * (range.Max - range.Min) + range.Min
end

local module = {}

--[[
	```luau
	-- usage

	local brick_particle = require(path.to.brick_particle)

	brick_particle.emit(Vector3.one, Color3.new(52, 45, 243), {
		amount = 20,
		lifetime = 1.8,
		size_range = NumberRange.new(0.3, 0.5),
		force = Vector3.new(25, 35, 25),
		spin = 10,
		fade_time = 0.4,
		collision = false,
	})
]]
function module.emit(position: Vector3, color: Color3, config: BrickParticle)
	config = config or defaults
	-- reconcile config with defaults
	for key, value in pairs(defaults) do
		if config[key] == nil then
			config[key] = value
		end
	end

	for i = 1, config.amount do
		local brick = pool:Get()
		brick.Position = position
		brick.Color = color
		brick.CanCollide = config.collision
		brick.Anchored = false

		local size = randomRange(config.size_range)
		brick.Size = Vector3.one * size

		brick.Parent = workspace

		-- velocity
		local force = config.force
		brick.AssemblyLinearVelocity = Vector3.new(
			math.random(-force.X, force.X),
			math.random(force.Y * 0.6, force.Y),
			math.random(-force.Z, force.Z)
		)

		brick.AssemblyAngularVelocity = space.toVector3(random.normalized_vector() * config.spin)

		-- fade out
		task.delay(config.lifetime - config.fade_time, function()
			if brick.Parent then
				local t_info = TweenInfo.new(config.fade_time)

				local tween = TweenService:Create(brick, t_info, { Transparency = 1 })

				tween:Play()
			end
		end)

		Debris:AddItem(brick, config.lifetime) -- we dont usually use debris.
	end
end

return module
