--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)

-- ground-crack.luau

local module = {}

local assets = ReplicatedStorage.Assets

local crack_pool = PoolerPlus:CreatePool("GroundCrackPool", function()
	return assets["Crack-01"]:Clone()
end)

local big_crack_pool = PoolerPlus:CreatePool("GroundCrackPool", function()
	return assets["Big-Crack-01"]:Clone()
end)

local ray_params = RaycastParams.new()
ray_params.FilterType = Enum.RaycastFilterType.Blacklist
ray_params.IgnoreWater = true -- we'll add a splash effect later, but for now we just don't want cracks in water
ray_params.FilterDescendantsInstances = {}

local function addCharacterToBlacklist()
	table.clear(ray_params.FilterDescendantsInstances)

	for i, player in ipairs(Players:GetPlayers()) do
		table.insert(ray_params.FilterDescendantsInstances, player.Character or player.CharacterAdded:Wait())
	end
end

addCharacterToBlacklist()

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		addCharacterToBlacklist()
	end)
end)

local function findSolidGround(position: Vector3)
	local ray = Ray.new(position + Vector3.new(0, 5, 0), Vector3.new(0, -1, 0) * 10)
	local result = workspace:Raycast(ray.Origin, ray.Direction)
	if not result then
		return nil
	end

	local part = result.Instance

	if part and part.CanCollide then
		return CFrame.new(result.Position)
	end

	return nil
end

function module.crack(position: CFrame)
	local crack = crack_pool:Get()

	-- find the ground below the position
	local ground_position = findSolidGround(position.Position)
	if not ground_position then
		crack_pool:Return(crack)
		print("couldnt find solid ground")
		return
	end

	crack.CFrame = ground_position
	crack.Parent = workspace

	for i, particle_emitter in pairs(crack:GetDescendants()) do
		if particle_emitter:IsA("ParticleEmitter") then
			task.spawn(particle_emitter.Emit, particle_emitter, 0.5)
			particle_emitter.Enabled = false
		end
	end

	audio:ConfigureSFX("ground-crack", {
		volume = 1,
	})
	audio:PlaySFX("ground-crack", position.Position)

	-- Return the crack to the pool after 5 seconds
	task.delay(5, function()
		crack.Parent = nil
		crack_pool:Return(crack)
	end)
end

function module.big_crack(position: CFrame)
	local crack = big_crack_pool:Get()
	-- find the ground below the position
	local ground_position = findSolidGround(position.Position)
	if not ground_position then
		crack_pool:Return(crack)
		print("couldnt find solid ground")
		return
	end

	crack.CFrame = ground_position
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

	audio:ConfigureSFX("ground-crack", {
		volume = 2,
	})
	audio:PlaySFX("ground-crack", position.Position)

	-- Return the crack to the pool after 5 seconds
	task.delay(5, function()
		crack.Parent = nil
		crack_pool:Return(crack)
	end)
end

return module
