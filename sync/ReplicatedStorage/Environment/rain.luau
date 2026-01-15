--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Workspace = game:GetService("Workspace")

local lerp = require(StarterPlayer.StarterPlayerScripts.Utilities.lerp)
local observer = require(ReplicatedStorage.Utility.observer)
local random = require(ReplicatedStorage.Utility.random)
local trove = require(ReplicatedStorage.Packages.trove)

-- rain.luau
-- parallel raycasting for rain

local rain_module = {}
rain_module.__index = rain_module

local function createParticles()
	local Instances = {
		Particles = Instance.new("Folder"),
		Hit = Instance.new("ParticleEmitter"),
		Puddle = Instance.new("ParticleEmitter"),
		Splash = Instance.new("ParticleEmitter"),
		Trail = Instance.new("ParticleEmitter"),
	}

	Instances.Particles.Name = "Particles"
	Instances.Particles.Parent = script

	Instances.Hit.Name = "Hit"
	Instances.Hit.LightInfluence = 0.5
	Instances.Hit.Lifetime = NumberRange.new(0.3, 0.3)
	Instances.Hit.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
	Instances.Hit.SpreadAngle = Vector2.new(0.1, 0.1)
	Instances.Hit.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.09, 0.9),
		NumberSequenceKeypoint.new(0.32, 0.95),
		NumberSequenceKeypoint.new(1, 1),
	})
	Instances.Hit.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.89, 0.94, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.89, 0.94, 1)),
	})
	Instances.Hit.Speed = NumberRange.new(0, 0)
	Instances.Hit.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.02, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	Instances.Hit.Enabled = false
	Instances.Hit.Rate = 2
	Instances.Hit.EmissionDirection = Enum.NormalId.Front
	Instances.Hit.Texture = "rbxassetid://125957387729715"
	Instances.Hit.Rotation = NumberRange.new(-180, 180)
	Instances.Hit.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	Instances.Hit.Parent = Instances.Particles

	Instances.Puddle.Name = "Puddle"
	Instances.Puddle.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	Instances.Puddle.LightInfluence = 0.5
	Instances.Puddle.Lifetime = NumberRange.new(1.5, 1.5)
	Instances.Puddle.SpreadAngle = Vector2.new(0.1, 0.1)
	Instances.Puddle.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.22, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	Instances.Puddle.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.89, 0.94, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.89, 0.94, 1)),
	})
	Instances.Puddle.Speed = NumberRange.new(0, 0)
	Instances.Puddle.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 4.31), NumberSequenceKeypoint.new(1, 4.5) })
	Instances.Puddle.Enabled = false
	Instances.Puddle.Rate = 0.5
	Instances.Puddle.EmissionDirection = Enum.NormalId.Front
	Instances.Puddle.Texture = "rbxassetid://12302665387"
	Instances.Puddle.Rotation = NumberRange.new(-180, 180)
	Instances.Puddle.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	Instances.Puddle.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	Instances.Puddle.Parent = Instances.Particles

	Instances.Splash.Name = "Splash"
	Instances.Splash.LightInfluence = 0.5
	Instances.Splash.Lifetime = NumberRange.new(0.3, 0.3)
	Instances.Splash.SpreadAngle = Vector2.new(0.1, 0.1)
	Instances.Splash.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(1, 1) })
	Instances.Splash.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.89, 0.94, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.89, 0.94, 1)),
	})
	Instances.Splash.Speed = NumberRange.new(0, 0)
	Instances.Splash.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.06) })
	Instances.Splash.Enabled = false
	Instances.Splash.Rate = 1
	Instances.Splash.EmissionDirection = Enum.NormalId.Front
	Instances.Splash.Texture = "rbxassetid://16587390596"
	Instances.Splash.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	Instances.Splash.Parent = Instances.Particles

	Instances.Trail.Name = "Trail"
	Instances.Trail.LightInfluence = 0.5
	Instances.Trail.Lifetime = NumberRange.new(0.3, 0.3)
	Instances.Trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.01, 0.6),
		NumberSequenceKeypoint.new(1, 0.44),
	})
	Instances.Trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.9, 0.92, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.69, 0.73, 0.8)),
	})
	Instances.Trail.Speed = NumberRange.new(350, 350)
	Instances.Trail.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 2) })
	Instances.Trail.Enabled = false
	Instances.Trail.Rate = 1
	Instances.Trail.EmissionDirection = Enum.NormalId.Front
	Instances.Trail.Texture = "http://www.roblox.com/asset/?id=3806148993"
	Instances.Trail.Rotation = NumberRange.new(-1, 1)
	Instances.Trail.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
	Instances.Trail.Parent = Instances.Particles
end

local function createSounds()
	local Instances = {
		Sounds = Instance.new("Folder"),
		Rain = Instance.new("Sound"),
		IndoorEq = Instance.new("EqualizerSoundEffect"),
		IndoorReverb = Instance.new("ReverbSoundEffect"),
	}

	Instances.Sounds.Name = "Sounds"
	Instances.Sounds.Parent = script

	Instances.Rain.Name = "Rain"
	Instances.Rain.Looped = true
	Instances.Rain.SoundId = "rbxassetid://9112854440"
	Instances.Rain.Parent = Instances.Sounds

	Instances.IndoorEq.Name = "IndoorEq"
	Instances.IndoorEq.MidGain = 0
	Instances.IndoorEq.LowGain = 0
	Instances.IndoorEq.HighGain = -18
	Instances.IndoorEq.Parent = Instances.Rain

	Instances.IndoorReverb.Name = "IndoorReverb"
	Instances.IndoorReverb.WetLevel = 0.1
	Instances.IndoorReverb.DryLevel = 6
	Instances.IndoorReverb.DecayTime = 0.5
	Instances.IndoorReverb.Parent = Instances.Rain
end

type self = typeof(rain_module.new())
export type metatable = setmetatable<self, typeof(rain_module)>

function rain_module.new()
	local self = setmetatable({
		_trove = trove.new(),
	}, rain_module)

	-- settings
	self.puddle_amount = 3
	self.rain_amount = 15
	self.rain_height = 35
	self.rain_range = 15

	self.puddle_max_time = 1.5
	self.rain_max_time = 0.3

	self.cast_params = RaycastParams.new()
	self.cast_params.IgnoreWater = true
	self.cast_params.RespectCanCollide = true
	self.cast_params.FilterType = Enum.RaycastFilterType.Exclude
	self.cast_params.FilterDescendantsInstances = {}

	self.cast_direction = Vector3.new(0, -self.rain_height * 1.5, 0)
	self.building_cast_direction = Vector3.new(0, self.rain_height, 0)

	self.camera = Workspace.CurrentCamera

	self.castRain = function()
		return Workspace:Raycast(
			self.camera.CFrame.Position + Vector3.new(random.integer(-self.rain_range, self.rain_range)),
			self.cast_direction,
			self.cast_params
		)
	end
	self.isObstructed = function()
		-- is the player inside a building or smth?
		return Workspace:Raycast(self.camera.CFrame.Position, self.cast_direction, self.cast_params) and true
			or false
	end

	self.scaleAmount = function(base: number, deltaTime: number)
		-- lock casting to # per frame from 60FPS

		return math.floor(base * math.clamp(deltaTime * 60, 0.5, 1.5))
	end

	self.rain_hits = table.create(1000)
	self.puddle_hits = table.create(1000)

	self.obstructed = observer.new(false)

	self.SFX = {}

	createParticles()
	createSounds()

	-- particles
	self.particles = script:WaitForChild("Particles") :: Folder

	self.rainSplash = self.particles:WaitForChild("Splash")
	self.rainPuddle = self.particles:WaitForChild("Puddle")
	self.rainTrail = self.particles:WaitForChild("Trail")
	self.rainHit = self.particles:WaitForChild("Hit")

	-- sfx

	self.sounds = script:WaitForChild("Sounds")

	self.rainSFX = self.sounds:WaitForChild("Rain")
	self.rainIndoorEq = self.rainSFX:WaitForChild("IndoorEq") :: EqualizerSoundEffect
	self.rainIndoorReverb = self.rainSFX:WaitForChild("IndoorReverb") :: ReverbSoundEffect

	return self
end

function rain_module:Start(self: self)
	local conn, conn2

	local offset = CFrame.new(0, 0, -0.2)

	conn = RunService.RenderStepped:ConnectParallel(function(deltaTime)
		-- rain
		for i = 1, self.scaleAmount(self.rain_amount, deltaTime) do
			local cast = self.castRain()
			if cast then
				local position = cast.Position
				local normal = cast.Normal

				table.insert(self.rain_hits, {
					rain_hit_CFrame = CFrame.new(position, position + normal) * offset,
				})
			end
		end

		-- puddles
		for i = 1, self.scaleAmount(self.puddle_amount, deltaTime) do
			local cast = self.castRain()
			if cast then
				local position = cast.Position
				local normal = cast.Normal

				table.insert(self.rain_hits, {
					rain_hit_CFrame = CFrame.new(position, position + normal) * offset,
				})
			end
		end

		self.obstructed:Set(self.isObstructed())

		if self.obstructed then
			self.SFX.HighGain = lerp(self.rainIndoorEq.HighGain, -18, 3 * deltaTime)
			self.SFX.DecayTime = lerp(self.rainIndoorReverb.DecayTime, 0.5, 3 * deltaTime)
			self.SFX.Diffusion = lerp(self.rainIndoorReverb.Diffusion, 1, 3 * deltaTime)
			self.SFX.DryLevel = lerp(self.rainIndoorReverb.DryLevel, 6, 3 * deltaTime)
			self.SFX.WetLevel = lerp(self.rainIndoorReverb.WetLevel, 0.1, 3 * deltaTime)
		else
			self.SFX.HighGain = lerp(self.rainIndoorEq.HighGain, 0, 3 * deltaTime)
			self.SFX.DecayTime = lerp(self.rainIndoorReverb.DecayTipme, 0, 3 * deltaTime)
			self.SFX.Diffusion = lerp(self.rainIndoorReverb.Diffusion, 0, 3 * deltaTime)
			self.SFX.DryLevel = lerp(self.rainIndoorReverb.DryLevel, 0, 3 * deltaTime)
			self.SFX.WetLevel = lerp(self.rainIndoorReverb.WetLevel, 0, 3 * deltaTime)
		end
	end)

	conn2 = RunService.RenderStepped:Connect(function(deltaTime)
		-- rain drops

		for i = #self.rain_hits, 1, -1 do
			local data = table.remove(self.rain_hits, i)

			local attachment = self._trove:Construct(Instance, "Attachment", Workspace.Terrain) :: Attachment
			attachment.WorldCFrame = data.rain_hit_CFrame

			local hit = self.rainHit:Clone()
			hit.Parent = attachment
			local splash = self.rainSplash:Clone()
			splash.Parent = attachment
			local trail = self.rainTrail:Clone()
			trail.Parent = attachment

			hit:Emit(1)
			splash:Emit(1)
			trail:Emit(1)

			task.delay(self.rain_max_time, self._trove.Remove, self._trove, attachment)
		end

		for i = #self.puddle_hits, 1, -1 do
			local data = table.remove(self.puddle_hits, i)

			local attachment = self._trove:Construct(Instance, "Attachment", Workspace.Terrain) :: Attachment
			attachment.WorldCFrame = data.rain_hit_CFrame

			local puddle = self.rainPuddle:Clone()
			puddle.Parent = attachment

			puddle:Emit(1)

			task.delay(self.rain_max_time, self._trove.Remove, self._trove, attachment)
		end
	end)

	if table.find(self.SFX, "HighGain") then
		self.rainIndoorEq.HighGain = self.SFX.HighGain
		self.rainIndoorReverb.DecayTime = self.SFX.DecayTime
		self.rainIndoorReverb.Density = self.SFX.Density
		self.rainIndoorReverb.Diffusion = self.SFX.Diffusion
		self.rainIndoorReverb.DryLevel = self.SFX.DryLevel
		self.rainIndoorReverb.WetLevel = self.SFX.WetLevel

		if self.SFX.DecayTime < 0.11 then
			self.rainIndoorReverb.Enabled = false
		else
			self.rainIndoorReverb.Enabled = true
		end
	end

	self._trove:Add(conn)
	self._trove:Add(conn2)
end

--[[
	To be run in parallel.
]]
function rain_module.Update(self: self, deltaTime: number)
	local offset = CFrame.new(0, 0, -0.2)

	-- rain
	for i = 1, self.scaleAmount(self.rain_amount, deltaTime) do
		local cast = self.castRain()
		if cast then
			local position = cast.Position
			local normal = cast.Normal

			table.insert(self.rain_hits, {
				rain_hit_CFrame = CFrame.new(position, position + normal) * offset,
			})
		end
	end

	-- puddles
	for i = 1, self.scaleAmount(self.puddle_amount, deltaTime) do
		local cast = self.castRain()
		if cast then
			local position = cast.Position
			local normal = cast.Normal

			table.insert(self.rain_hits, {
				rain_hit_CFrame = CFrame.new(position, position + normal) * offset,
			})
		end
	end

	self.obstructed:Set(self.isObstructed())

	if self.obstructed then
		self.SFX.HighGain = lerp(self.rainIndoorEq.HighGain, -18, 3 * deltaTime)
		self.SFX.DecayTime = lerp(self.rainIndoorReverb.DecayTime, 0.5, 3 * deltaTime)
		self.SFX.Diffusion = lerp(self.rainIndoorReverb.Diffusion, 1, 3 * deltaTime)
		self.SFX.DryLevel = lerp(self.rainIndoorReverb.DryLevel, 6, 3 * deltaTime)
		self.SFX.WetLevel = lerp(self.rainIndoorReverb.WetLevel, 0.1, 3 * deltaTime)
	else
		self.SFX.HighGain = lerp(self.rainIndoorEq.HighGain, 0, 3 * deltaTime)
		self.SFX.DecayTime = lerp(self.rainIndoorReverb.DecayTipme, 0, 3 * deltaTime)
		self.SFX.Diffusion = lerp(self.rainIndoorReverb.Diffusion, 0, 3 * deltaTime)
		self.SFX.DryLevel = lerp(self.rainIndoorReverb.DryLevel, 0, 3 * deltaTime)
		self.SFX.WetLevel = lerp(self.rainIndoorReverb.WetLevel, 0, 3 * deltaTime)
	end

	-- rain drops

	task.synchronize()

	for i = #self.rain_hits, 1, -1 do
		local data = table.remove(self.rain_hits, i)

		local attachment = self._trove:Construct(Instance, "Attachment", Workspace.Terrain) :: Attachment
		attachment.WorldCFrame = data.rain_hit_CFrame

		local hit = self.rainHit:Clone()
		hit.Parent = attachment
		local splash = self.rainSplash:Clone()
		splash.Parent = attachment
		local trail = self.rainTrail:Clone()
		trail.Parent = attachment

		hit:Emit(1)
		splash:Emit(1)
		trail:Emit(1)

		task.delay(self.rain_max_time, self._trove.Remove, self._trove, attachment)
	end

	for i = #self.puddle_hits, 1, -1 do
		local data = table.remove(self.puddle_hits, i)

		local attachment = self._trove:Construct(Instance, "Attachment", Workspace.Terrain) :: Attachment
		attachment.WorldCFrame = data.rain_hit_CFrame

		local puddle = self.rainPuddle:Clone()
		puddle.Parent = attachment

		puddle:Emit(1)

		task.delay(self.rain_max_time, self._trove.Remove, self._trove, attachment)
	end

	if table.find(self.SFX, "HighGain") then
		self.rainIndoorEq.HighGain = self.SFX.HighGain
		self.rainIndoorReverb.DecayTime = self.SFX.DecayTime
		self.rainIndoorReverb.Density = self.SFX.Density
		self.rainIndoorReverb.Diffusion = self.SFX.Diffusion
		self.rainIndoorReverb.DryLevel = self.SFX.DryLevel
		self.rainIndoorReverb.WetLevel = self.SFX.WetLevel

		if self.SFX.DecayTime < 0.11 then
			self.rainIndoorReverb.Enabled = false
		else
			self.rainIndoorReverb.Enabled = true
		end
	end
end

function rain_module:Destroy(self: self)
	-- allow for final processing
	task.defer(function()
		self._trove:Destroy()
		setmetatable(self, nil)
	end)
end

return rain_module
