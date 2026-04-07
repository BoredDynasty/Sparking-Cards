--!native
-- Shake module by sleitnick [RbxUtil]
local RunService = game:GetService("RunService")

type UpdateCallbackFn = () -> (Vector3, Vector3, boolean)

export type Shake = {
	Amplitude: number,
	Frequency: number,
	FadeInTime: number,
	FadeOutTime: number,
	SustainTime: number,
	Sustain: boolean,
	PositionInfluence: Vector3,
	RotationInfluence: Vector3,
	TimeFunction: () -> number,

	Start: (self: Shake) -> (),
	Stop: (self: Shake) -> (),
	IsShaking: (self: Shake) -> boolean,
	StopSustain: (self: Shake) -> (),
	Update: (self: Shake) -> (Vector3, Vector3, boolean),
	OnSignal: (
		self: Shake,
		signal: RBXScriptSignal,
		callback: (Vector3, Vector3, boolean) -> ()
	) -> RBXScriptConnection,
	BindToRenderStep: (self: Shake, name: string, priority: number, callback: (Vector3, Vector3, boolean) -> ()) -> (),
	Clone: (self: Shake) -> Shake,
	Destroy: (self: Shake) -> (),
}

local rng = Random.new()
local renderId = 0

local Shake = {}
Shake.__index = Shake

function Shake.new(): Shake
	local self = setmetatable({}, Shake)

	self.Amplitude = 1
	self.Frequency = 1
	self.FadeInTime = 1
	self.FadeOutTime = 1
	self.SustainTime = 0
	self.Sustain = false
	self.PositionInfluence = Vector3.one
	self.RotationInfluence = Vector3.one
	self.TimeFunction = if RunService:IsRunning() then time else os.clock

	self._timeOffset = rng:NextNumber(-1e6, 1e6)
	self._startTime = 0
	self._running = false
	self._signalConnections = {}
	self._renderBindings = {}

	return self
end

function Shake.InverseSquare(shake: Vector3, distance: number): Vector3
	if distance < 1 then
		distance = 1
	end
	local intensity = 1 / (distance * distance)
	return shake * intensity
end

function Shake.NextRenderName(): string
	renderId += 1
	return ("__shake_%.4i__"):format(renderId)
end

function Shake:Start()
	self._startTime = self.TimeFunction()
	self._running = true
end

function Shake:Stop()
	self._running = false

	for _, name in self._renderBindings do
		RunService:UnbindFromRenderStep(name)
	end
	table.clear(self._renderBindings)

	for _, conn in self._signalConnections do
		conn:Disconnect()
	end
	table.clear(self._signalConnections)
end

function Shake:IsShaking(): boolean
	return self._running
end

function Shake:StopSustain()
	local now = self.TimeFunction()
	self.Sustain = false
	self.SustainTime = (now - self._startTime) - self.FadeInTime
end

function Shake:Update(): (Vector3, Vector3, boolean)
	local done = false

	local now = self.TimeFunction()
	local dur = now - self._startTime

	local noiseInput = ((now + self._timeOffset) / self.Frequency) % 10000

	local multiplierFadeIn = 1
	local multiplierFadeOut = 1
	if dur < self.FadeInTime then
		-- Fade in
		multiplierFadeIn = dur / self.FadeInTime
	end
	if not self.Sustain and dur > self.FadeInTime + self.SustainTime then
		if self.FadeOutTime == 0 then
			done = true
		else
			-- Fade out
			multiplierFadeOut = 1 - (dur - self.FadeInTime - self.SustainTime) / self.FadeOutTime
			if not self.Sustain and dur >= self.FadeInTime + self.SustainTime + self.FadeOutTime then
				done = true
			end
		end
	end

	local offset = Vector3.new(
		math.noise(noiseInput, 0) / 2,
		math.noise(0, noiseInput) / 2,
		math.noise(noiseInput, noiseInput) / 2
	) * self.Amplitude * math.min(multiplierFadeIn, multiplierFadeOut)

	if done then
		self:Stop()
	end

	return self.PositionInfluence * offset, self.RotationInfluence * offset, done
end

function Shake:OnSignal(signal, callbackFn: UpdateCallbackFn)
	local conn = signal:Connect(function()
		callbackFn(self:Update())
	end)

	table.insert(self._signalConnections, conn)

	return conn
end

function Shake:BindToRenderStep(name: string, priority: number, callbackFn: UpdateCallbackFn)
	RunService:BindToRenderStep(name, priority, function()
		callbackFn(self:Update())
	end)

	table.insert(self._renderBindings, name)
end

function Shake:Clone()
	local shake = Shake.new()
	local cloneFields = {
		"Amplitude",
		"Frequency",
		"FadeInTime",
		"FadeOutTime",
		"SustainTime",
		"Sustain",
		"PositionInfluence",
		"RotationInfluence",
		"TimeFunction",
	}
	for _, field in cloneFields do
		shake[field] = self[field]
	end
	return shake
end

function Shake:Destroy()
	self:Stop()
end

return {
	new = Shake.new,
	InverseSquare = Shake.InverseSquare,
	NextRenderName = Shake.NextRenderName,
}
