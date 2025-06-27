--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Utility.SignalPlus)

-- Type definitions
type HitboxConfig = {
	Size: Vector3,
	CFrame: CFrame?,
	Duration: number?,
	Filter: { Instance }?,
	MaxHits: number?,
	Visualize: boolean?,
	ValidateRaycast: boolean?,
}

type HitResult = {
	Part: BasePart,
	Position: Vector3,
	Normal: Vector3,
	Instance: Instance,
	Distance: number,
}

export type Hitbox = {
	Active: boolean,
	Size: Vector3,
	CFrame: CFrame,
	Filter: { Instance },
	MaxHits: number,
	HitList: { [Instance]: true },
	Duration: number,
	Connection: RBXScriptConnection?,

	HitDetected: SignalPlus.Signal<(hitResult: HitResult) -> ()>,
	HitboxStarted: SignalPlus.Signal<() -> ()>,
	HitboxEnded: SignalPlus.Signal<() -> ()>,

	Start: (self: Hitbox) -> (),
	Stop: (self: Hitbox) -> (),
	Destroy: (self: Hitbox) -> (),
}

-- Visualization helpers
local function createVisualBox(cf: CFrame, size: Vector3): BasePart
	local box = Instance.new("Part")
	box.Size = size
	box.CFrame = cf
	box.Anchored = true
	box.CanCollide = false
	box.CanQuery = false
	box.CanTouch = false
	box.Transparency = 0.5
	box.Color = Color3.fromRGB(255, 0, 0)
	box.Parent = workspace
	return box
end

local ClientCast = {}
ClientCast.__index = ClientCast

function ClientCast.new(config: HitboxConfig): Hitbox
	local self = setmetatable({
		Active = false,
		Size = config.Size,
		CFrame = config.CFrame or CFrame.new(),
		Filter = config.Filter or {},
		MaxHits = config.MaxHits or math.huge,
		HitList = {},
		Duration = config.Duration,
		Visualize = config.Visualize or false,
		ValidateRaycast = config.ValidateRaycast or false,

		HitDetected = SignalPlus(),
		HitboxStarted = SignalPlus(),
		HitboxEnded = SignalPlus(),

		_visualPart = nil,
	}, ClientCast)

	return self
end

function ClientCast:_checkHit(): { HitResult }
	local region = Region3.new(self.CFrame.Position - self.Size / 2, self.CFrame.Position + self.Size / 2)

	local parts = workspace:GetPartBoundsInBox(self.CFrame, self.Size, self.Filter :: OverlapParams)
	local results: { HitResult } = {}

	for _, part in parts do
		local model = part:FindFirstAncestorWhichIsA("Model")
		if not model then
			continue
		end

		-- Skip if already hit and under max hits
		if self.HitList[model] and #self.HitList >= self.MaxHits :: number then
			continue
		end

		-- Optional raycast validation
		if self.ValidateRaycast :: boolean then
			local ray = Ray.new(
				self.CFrame.Position,
				(part.Position - self.CFrame.Position).Unit * self.Size.Magnitude
			)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = self.Filter
			local rayResult = workspace:Raycast(ray.Origin, ray.Direction, raycastParams)

			if not rayResult then
				continue
			end

			-- Send validation to server
			Packet.rayValidation.send({ model.Name })
		end

		-- Record hit
		self.HitList[model] = true

		-- Create hit result
		local hitResult: HitResult = {
			Part = part,
			Position = part.Position,
			Normal = (part.Position - self.CFrame.Position).Unit,
			Instance = model,
			Distance = (part.Position - self.CFrame.Position).Magnitude,
		}

		table.insert(results, hitResult)
	end

	return results
end

function ClientCast:Start()
	if self.Active then
		return
	end
	self.Active = true

	-- Visual debugging
	if self.Visualize then
		self._visualPart = createVisualBox(self.CFrame, self.Size)
	end

	-- Set up hit detection loop
	self.Connection = RunService.Heartbeat:Connect(function()
		local hits = self:_checkHit()
		for _, hit in hits do
			self.HitDetected:Fire(hit)
		end
	end)

	self.HitboxStarted:Fire()

	-- Handle duration
	if self.Duration then
		task.delay(self.Duration :: number, function()
			if self.Active then
				self:Stop()
			end
		end)
	end
end

function ClientCast:Stop()
	if not self.Active then
		return
	end
	self.Active = false

	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end

	if self._visualPart then
		self._visualPart:Destroy()
		self._visualPart = nil
	end

	self.HitboxEnded:Fire()
end

function ClientCast:Destroy()
	self:Stop()
	self.HitDetected:Destroy()
	self.HitboxStarted:Destroy()
	self.HitboxEnded:Destroy()
end

return ClientCast
