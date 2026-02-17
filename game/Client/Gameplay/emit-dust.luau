--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local hydration = require(ReplicatedStorage.Utility.hydration)
local random = require(ReplicatedStorage.Utility.random)
local space = require(ReplicatedStorage.Modules.Serialization.space)
local spr = require(ReplicatedStorage.Modules.spr)

-- emit-dust.luau
-- emits a dust part.
-- WIP

local pool = PoolerPlus:CreatePool("DustPool", function()
	return ReplicatedStorage.Assets.Dust:Clone()
end)

local module = {}

function module.emit(position: CFrame)
	local dust = pool:Get()
	hydration(dust) {
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Position = space.toVec(position.Position) * (random.normalized_vector() * 1.5),
		Transparency = 0,
	}

	local mass = dust.AssemblyMass
	local power = 30

	-- apply angular impulse to backwards to the position
	local velocity = -position.LookVector * random.integer()
	dust:ApplyAngularImpulse(velocity * mass * power)

	dust.Parent = workspace

	spr.target(dust, 0.8, 5, {
		Transparency = 1,
	})

	spr.completed(dust, function()
		pool:Return(dust)
	end)
end

return module
