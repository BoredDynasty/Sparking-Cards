--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local trove = require(ReplicatedStorage.Packages.trove)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- aurora.luau
-- a script that uses one particle emitter
-- to recreate an aurora borealis.

local aurora = {}
aurora.__index = aurora

type self = {
	_trove: typeof(trove.new()),
	id: string,
	color: Color3,
	defaultEmission: number,
	defaultRate: number,
	position: Vector3,
	object: Part,
	emitter: ParticleEmitter,
}

export type aurora = setmetatable<self, typeof(aurora)>

function aurora.new(color: Color3?)
	local self = setmetatable({
		_trove = trove.new(),
		id = "rbxassetid://110170832236629",
		color = color or Color3.new(),
		defaultEmission = 1,
		defaultRate = 100,
		position = Vector3.new(),
	}, aurora)

	self.object = self._trove:Construct(Instance, "Part", Workspace) :: Part
	self.object.Name = "aurora_" .. url.generateShortUniqueId()
	self.object.Size = Vector3.one
	self.object.Anchored = true
	self.object.CanCollide = false
	self.object.Transparency = 1
	self.object.Position = self.position

	-- particle emitter

	self.emitter = self._trove:Construct(Instance, "ParticleEmitter", self.object) :: ParticleEmitter
	self.emitter.Texture = self.id
	self.emitter.SpreadAngle = Vector2.new(180, 0)
	self.emitter.Drag = 9
	self.emitter.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	self.emitter.LightInfluence = 0.1
	self.emitter.LightEmission = self.defaultEmission
	self.emitter.Rate = self.defaultRate
	self.emitter.Squash = NumberSequence.new(2)
	self.emitter.Color = ColorSequence.new(self.color)

	self.emitter.Speed = NumberRange.new(100) -- for now
	self.emitter.Lifetime = NumberRange.new(2, 4)
	self.emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 1),
		NumberSequenceKeypoint.new(0.5, 1.7),
		NumberSequenceKeypoint.new(1, 1),
	})

	return self
end

function aurora:setColor(color: Color3 | ColorSequence): aurora
	local color_part = self._trove:Construct(Instance, "Part", ReplicatedStorage) :: Part
	color_part:SetAttribute("color", self.color)

	local interpolation = TweenPlus(color_part, {
		["@color"] = color,
	}, {
		Time = 1,
	})

	self._trove:Add(interpolation)

	interpolation.Updated:Connect(function()
		self.color = color_part:GetAttribute("color")
	end)

	interpolation.Completed:Once(function()
		self._trove:Remove(color_part)
		interpolation:Destroy()
	end)

	interpolation:Start()

	return self
end

function aurora:adjust(emission_factor: number?, rate_factor: number?): aurora
	emission_factor = emission_factor or 1
	rate_factor = rate_factor or 1

	self.emitter.LightEmission = self.defaultEmission * emission_factor
	self.emitter.Rate = self.defaultRate * rate_factor
end

function aurora:setPosition(position: Vector3): aurora
	self.position = position
	self.object.Position = self.position

	return self
end

function aurora:destroy()
	self._trove:Destroy()
	setmetatable(self, nil)
end

return aurora
