--!native

--[=[
    @class ShakerInstances
    The physics backbone of SpringShaker. Implements a damped harmonic oscillator
    using the closed-form solution:

    ```
    S(t) = F(t) * cos(sqrt(T) * t) * e^(-D*t) * E(t)
    ```

    Where:
    - `F(t)` — External noise force (Perlin rumble + jitter) scaled by Magnitude
    - `cos(sqrt(T) * t)` — Oscillation frequency driven by Tension
    - `e^(-D*t)` — Exponential decay driven by Damper (only active during fade-out)
    - `E(t)` — Cubic fade envelope `CurrentTime^3`

    Not intended to be used directly — SpringShaker manages all instances internally.
]=]
local ShakerInstances = {}
ShakerInstances.__index = ShakerInstances

local Batch = require(script.Parent.Batch)
local Random = Random.new()

type CamShakeInstance = Batch.CamShakeStates

--[=[
    Constructs a new shaker math instance from a preset configuration table.

    @param __SpringShakeDefClass __camShakePreset -- The preset or .new() config table
    @return __SpringShakerClassMeta
]=]
function ShakerInstances.new(__SpringShakeDefClass)
	assert(__SpringShakeDefClass, "__SpringShakeDefClass must be of a new constructor class")

	local INITIATOR_COMPOUND = setmetatable({
		Magnitude = __SpringShakeDefClass.Magnitude or 0.4,
		Roughness = __SpringShakeDefClass.Roughness or 0.2,
		FadeInTime = __SpringShakeDefClass.FadeInTime or 0,
		FadeOutTime = __SpringShakeDefClass.FadeOutTime or 0,
		Velocity = __SpringShakeDefClass.Velocity or Vector3.zero,
		Tension = __SpringShakeDefClass.Tension or 150,
		Damper = __SpringShakeDefClass.Damping or 1,
		PositionInfluence = __SpringShakeDefClass.PosInflux or __SpringShakeDefClass.PositionInfluence or Vector3.one,
		RotationInfluence = __SpringShakeDefClass.RotInflux or __SpringShakeDefClass.RotationInfluence or Vector3.one,
		Elapsed = 0,
		RawTime = 0,
		SustainComplex = true,
		FadeOutElapsed = 0,
		Position = Vector3.zero,
		CurrentTime = (__SpringShakeDefClass.FadeInTime > 0 and 0 or 1),
		Active = true,
		Tick = Random:NextInteger(-100, 100),
		State = Batch.BuildInPresets.__camShakeStates.Active,
	}, ShakerInstances)

	return INITIATOR_COMPOUND
end

--[=[
    Steps the physics simulation forward by `dx` seconds.
    Internally this:
    1. Advances the cubic fade envelope (CurrentTime^3)
    2. Samples Perlin noise for rumble and jitter
    3. Applies the damped harmonic oscillator formula
    4. Clamps position to prevent explosive values

    :::note 
    Calling Update on an inactive shaker will return Vector3.zero and do no work.
    :::

    :::caution
    Setting Magnitude above 10^5 risks [Resonance](https://en.wikipedia.org/wiki/Resonance) —
    a real physics phenomenon where the forcing frequency matches the system's natural frequency,
    producing explosive and unregisterable values. SpringShaker will abort and warn if this is detected.
    :::

    @param dx number -- Delta time in seconds (typically from RenderStepped)
    @return Vector3 -- The current position offset to accumulate onto the camera
]=]
function ShakerInstances:Update(dx)
	if not self.Active or not self.Position then
		return Vector3.zero
	end
	dx = math.min(dx, 0.033)

	if self.SustainComplex then
		local rate = (self.FadeInTime > 0) and (dx / self.FadeInTime) or 1
		self.CurrentTime = math.min(1, self.CurrentTime + rate)
	else
		local rate = (self.FadeOutTime > 0) and (dx / self.FadeOutTime) or 1
		self.CurrentTime = math.max(0, self.CurrentTime - rate)
	end

	local energy = math.pow(self.CurrentTime, 3)
	self.Elapsed = self.Elapsed + (dx * self.Roughness)
	local _t = self.Elapsed + self.Tick

	local rumble = Vector3.new(math.noise(_t, 10.5), math.noise(_t, 25.5), math.noise(_t, 40.5))
	local jitter = Vector3.new(math.noise(_t * 5, 70.5), math.noise(_t * 5, 85.5), math.noise(_t * 5, 100.5)) * 0.3

	local combinedForce = (rumble + jitter) * (self.Magnitude * energy)

	local displacement = self.Position - combinedForce
	local clampedDisplacement = Vector3.new(
		math.clamp(displacement.X, -2, 2),
		math.clamp(displacement.Y, -2, 2),
		math.clamp(displacement.Z, -2, 2)
	)

	local springForce = -self.Tension * clampedDisplacement
	local dampingForce = -self.Damper * self.Velocity

	self.Velocity += (springForce + dampingForce) * dx
	self.Position += self.Velocity * dx

	if self.Position.X ~= self.Position.X or self.Position.Magnitude > 10 ^ 5 then
		warn("SpringShake: Massive resonance detected, aborting...")
		self.Position = Vector3.zero
		self.Velocity = Vector3.zero
		return Vector3.zero
	end

	return self.Position
end

--[=[
    Begins fading the shake out over the given duration.
    Sets `SustainComplex` to false, enabling the exponential decay envelope on the next Update.
    Resets `RawTime` to 0 so decay always starts from `e^0 = 1`.

    @param Time number -- Duration in seconds. Pass 0 for an immediate stop.
]=]
function ShakerInstances:FadeOut(Time: number)
	assert(Time, "given time was not found and failed to set fadeout")
	if Time == 0 then
		self.CurrentTime = 0
	end

	self.FadeOutElapsed = 0
	self.FadeOutTime = Time
	self.FadeInTime = 0
	self.SustainComplex = false
end

--[=[
    Begins fading the shake in over the given duration.
    Sets `SustainComplex` to true, holding decay at 1 until FadeOut is called.

    @param Time number -- Duration in seconds. Pass 0 to start at full magnitude immediately.
]=]
function ShakerInstances:FadeIn(Time: number)
	assert(Time, "given time was not found and failed to set fadein")
	if Time == 0 then
		self.CurrentTime = 1
	end

	self.FadeOutTime = 0
	self.FadeInTime = Time
	self.SustainComplex = true
end

--[=[
    Returns the current fade multiplier in the range [0, 1].
    Computed as `CurrentTime^3` for a cubic ease curve —
    slow to start, fast to finish.

    @return number
]=]
function ShakerInstances:GetFadeMagnitude(): number
	return math.pow(self.CurrentTime, 3)
end

--[=[
    Returns true if the shaker is currently active or sustaining at any energy level.

    @return boolean
]=]
function ShakerInstances:IsShaking(): boolean
	local curTime = self.CurrentTime or 0
	return (curTime > 0 or self.SustainComplex == true)
end

--[=[
    Returns true if the shaker is currently in the process of fading out.

    @return boolean
]=]
function ShakerInstances:IsFadingOut(): boolean
	local curTime = self.CurrentTime or 0
	return (not self.SustainComplex) and (curTime > 0)
end

--[=[
    Returns true if the shaker is currently fading in (has not yet reached full energy).

    @return boolean
]=]
function ShakerInstances:IsFading(): boolean
	local curTime = self.CurrentTime or 0
	local fadeIn = self.FadeInTime or 0
	return (curTime < 1) and (self.SustainComplex == true) and (fadeIn > 0)
end

--[=[
    Returns true if the shaker has fully decayed and is safe to recycle.
    Checks that SustainComplex is false, CurrentTime is at zero,
    and both Position and Velocity magnitudes are below the settlement threshold.

    @return boolean
]=]
function ShakerInstances:IsDead(): boolean
	if not self.Position then
		return true
	end

	local curTime = self.CurrentTime or 0
	local isSettled = self.Position.Magnitude < 0.001 and (self.Velocity and self.Velocity.Magnitude < 0.001 or true)

	return (not self.SustainComplex) and (curTime <= 0) and isSettled
end

--[=[
    Returns the current state of this shaker instance as an integer enum value.

    | State | Value |
    | --- | --- |
    | Reserved | -1 |
    | Inactive | 0 |
    | Active | 1 |
    | FadeInProgress | 2 |
    | FadeOutProgress | 3 |

    @return number
]=]
function ShakerInstances:GetState(): number
	if self:IsShaking() then
		return Batch.BuildInPresets.__camShakeStates.Active
	end

	if self:IsFadingOut() then
		return Batch.BuildInPresets.__camShakeStates.FadeOutProgress
	end

	if self:IsFading() then
		return Batch.BuildInPresets.__camShakeStates.FadeInProgress
	end

	return Batch.BuildInPresets.__camShakeStates.Inactive
end

return ShakerInstances
