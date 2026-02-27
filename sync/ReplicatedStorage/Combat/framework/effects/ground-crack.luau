--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)

-- ground-crack.luau

local module = {}

local assets = ReplicatedStorage.Assets

local crack_pool = PoolerPlus:CreatePool("GroundCrackPool", function()
	return assets["Crack-01"]:Clone()
end)

local big_crack_pool = PoolerPlus:CreatePool("GroundCrackPool", function()
	return assets["Big-Crack-01"]:Clone()
end)

function module.crack(position: CFrame)
	local crack = crack_pool:Get()

	crack.CFrame = position
	crack.Parent = workspace

	for i, particle_emitter in pairs(crack:GetDescendants()) do
		if particle_emitter:IsA("ParticleEmitter") then
			particle_emitter:Emit(0.5)
		end
	end

	-- TODO) play a sound

	-- Return the crack to the pool after 5 seconds
	task.delay(5, function()
		crack.Parent = nil
		crack_pool:Return(crack)
	end)
end

function module.big_crack(position: CFrame)
	local crack = big_crack_pool:Get()

	crack.CFrame = position
	crack.Parent = workspace

	for i, particle_emitter in pairs(crack:GetDescendants()) do
		if particle_emitter:IsA("ParticleEmitter") then
			task.spawn(function()
				particle_emitter.Enabled = true

				task.wait(4)

				particle_emitter.Enabled = false
			end)
		end
	end

	-- TODO) play a sound

	-- Return the crack to the pool after 5 seconds
	task.delay(5, function()
		crack.Parent = nil
		crack_pool:Return(crack)
	end)
end

return module
