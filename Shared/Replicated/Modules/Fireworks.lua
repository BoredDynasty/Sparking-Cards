--!nonstrict
local Fireworks = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local audio = require(script.Parent.audio)

audio:writeSFX({
	blastoff = 551051176,
	boom = 269146157,
})

local FireworkAssets =
	ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Particles"):WaitForChild("Fireworks") :: Folder

--[ Utils ]--
local RNG = Random.new()
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
		local RandomColor = Colors[RNG:NextInteger(1, #colors)]

		local NewPart = Instance.new("Part")
		NewPart.CanCollide = false
		NewPart.Anchored = true
		NewPart.CFrame = position
		NewPart.Size = Vector3.new()
		NewPart.Name = "Firework"
		NewPart.Parent = game.Workspace

		local Trail = FireworkAssets:FindFirstChild("Trail") :: ParticleEmitter
		Trail = Trail:Clone()
		Trail.Parent = NewPart

		local Time = RNG:NextNumber(8, 11)
		local Height = RNG:NextNumber(4, 7)
		TweenService:Create(
			NewPart,
			TweenInfo.new(Time / 10, Enum.EasingStyle.Linear),
			{ CFrame = position + Vector3.new(0, Height, 0) }
		):Play()
		audio:SFX("blastoff")
		task.wait(1)

		Trail.Enabled = false

		local ExplosionParticle = FireworkAssets:FindFirstChild("Explosion") :: ParticleEmitter
		ExplosionParticle = ExplosionParticle:Clone()
		ExplosionParticle.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, RandomColor),
			ColorSequenceKeypoint.new(1, RandomColor),
		})
		ExplosionParticle.Parent = NewPart
		ExplosionParticle:Emit(25)
		for _ = 1, 4 do
			task.wait()
			audio:SFX("boom")
			task.wait()
		end

		Debris:AddItem(NewPart, 4)
	end)
end

function Fireworks:PlayFireworks(object: BasePart, colors: { Color3 }?)
	local NumberOfFireworks = RNG:NextInteger(4, 6)
	local WhenToStop = 0

	while WhenToStop < NumberOfFireworks do
		task.wait()
		MakeFirework(object.CFrame + Vector3.new(RNG:NextNumber(-4, 4), -2, RNG:NextNumber(-4, 4)), colors)
		WhenToStop = WhenToStop + 1
	end
end

return Fireworks
