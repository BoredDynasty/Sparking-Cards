--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TweenPlus = require(script.Parent.TweenPlus)
local audio = require(script.Parent.audio)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local hydration = require(ReplicatedStorage.Utility.hydration)
local random = require(ReplicatedStorage.Utility.random)

local FireworkAssets = fetchAsset("Fireworks") :: Folder

local Colors = {
	Color3.fromRGB(255, 49, 49),
	Color3.fromRGB(255, 179, 55),
	Color3.fromRGB(255, 255, 53),
	Color3.fromRGB(105, 255, 79),
	Color3.fromRGB(70, 252, 255),
	Color3.fromRGB(193, 85, 255),
	Color3.fromRGB(255, 169, 225),
}

local function MakeFirework(position: Vector3, colors: { Color3 }?)
	if not colors then
		colors = Colors
	end

	task.spawn(function()
		local color = Colors[random.integer(1, #colors)]

		local firework = Instance.new("Part")
		hydration(firework) {
			CanCollide = false,
			Anchored = true,
			CFrame = position,
			Size = Vector3.one,
			Name = "Firework",
			Parent = Workspace,
		}

		local Trail = FireworkAssets:FindFirstChild("Trail") :: ParticleEmitter
		Trail = Trail:Clone()
		Trail.Parent = firework

		local time = random.integer(8, 11)
		local height = random.integer(4, 7)

		TweenPlus(firework, {
			{ CFrame = position + vector.create(0, height, 0) },
		}, {
			Time = time / 10,
			EasingStyle = "Linear",
		}):Start()

		audio:SFX("blastoff")
		task.wait(1)

		Trail.Enabled = false

		local ExplosionParticle = FireworkAssets:FindFirstChild("Explosion") :: ParticleEmitter
		ExplosionParticle = ExplosionParticle:Clone()
		ExplosionParticle.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(1, color),
		})
		ExplosionParticle.Parent = firework
		ExplosionParticle:Emit(25)

		for i = 1, 4 do
			task.defer(audio.SFX, audio, "boom")
		end

		task.delay(4, firework.Destroy, firework)
	end)
end

local function set_off(object: BasePart, colors: { Color3 }?)
	local NumberOfFireworks = random.integer(4, 6)
	local WhenToStop = 0

	while WhenToStop < NumberOfFireworks do
		MakeFirework(object.CFrame + Vector3.new(random.float(-4, 4), -2, random.float(-4, 4)), colors)
		WhenToStop += 1
	end
end

return setmetatable({
	create = MakeFirework,
}, {
	__call = function(_, ...)
		return set_off(...)
	end,
})
