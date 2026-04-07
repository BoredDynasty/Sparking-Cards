--[=[
    @class SpringShaker
    A physics-based camera shaker for Roblox built on a damped harmonic oscillator. Unlike noise-only shakers, SpringShaker simulates real mass and resistance — giving shakes a natural ring-down and weight.
]=]

--// CLASSES \\--
local SpringShaker = {}
local SpringShakerPresets = {}

--// FOLDERS \\--
local Packages = script.Parent.Packages

--// MODULES  \\--
local Batch = require(script.Batch)
local Janitor = require(Packages.janitor)
local ShakerInstances = require(script.SpringInstances)
local Presets = require(script.presets)

--// CONFIGURATION \\--
local PresetData = Batch.BuildInPresets
local PresetConfig = PresetData.__presetConfig

--// SERVICES || IMPORTS \\--
local CurrentCamera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

--// DECLARATIONS & PRIVATE FUNCTIONS \\--
local __classInstances = {}

--[=[
    @type __SpringShakerClassDef table
    @within SpringShaker
    Combined type of the preset configuration and the shaker instance methods.
]=]
export type __SpringShakerClassDef = typeof(SpringShakerPresets) & Batch.__camShakePreset

SpringShaker._PresetsMap = Presets
SpringShaker._PartnerLoop = false

SpringShakerPresets.__index = function(self, __indexmap)
	local internal_rawdata = rawget(self, __indexmap)
	if internal_rawdata ~= nil then
		return internal_rawdata
	end

	local PRESET_CONNECTOR = {
		[PresetConfig.MAGNITUDE] = function()
			return self.Magnitude
		end,
		[PresetConfig.ROUGHNESS] = function()
			return self.Roughness
		end,
		[PresetConfig.FADEINTIME] = function()
			return self.FadeInTime
		end,
		[PresetConfig.FADEOUTTIME] = function()
			return self.FadeOutTime
		end,
		[PresetConfig.DAMPING] = function()
			return self.Damping
		end,
		[PresetConfig.TENSION] = function()
			return self.Tension
		end,
		[PresetConfig.VELOCITY] = function()
			return self.Velocity
		end,
	}

	local __connector = PRESET_CONNECTOR[__indexmap]
	if __connector then
		return __connector()
	end

	return SpringShaker[__indexmap]
end

--// FUNCTIONS \\--

--[=[
    Creates a brand new Springy camera shaker instance.

    Usage: 
    ```lua 
    local MySpringShaker = SpringShaker.new({
        Magnitude = 0.5,
        Roughness = 0.3,
        FadeInTime = 0.2,
        FadeOutTime = 0.6,
        Tension = 120,
        Damping = 8,
        Velocity = Vector3.new(0, 0, 0),
        RotationInfluence = Vector3.new(1, 1, 1),
    })
    SpringShaker:ShakeOnce(MySpringShaker, 2) -- Shakes for apparent 2 seconds.
    ```

    @param __SpringShakeDefClass Batch.__camShakePreset -- The configuration table for the shaker.
    @return __SpringShakerClassDef -- Returns the shaker class object.
]=]
function SpringShaker.new(__SpringShakeDefClass: Batch.__camShakePreset): __SpringShakerClassDef
	assert(RunService:IsClient(), "SpringShaker must be run on the client.")
	assert(__SpringShakeDefClass, "SpringShaker must have a valid table.")

	local __Magnitude = math.clamp(__SpringShakeDefClass.Magnitude or 0.4, 0, 10 ^ 5)

	local INSTANTIATOR_CLASS = setmetatable({
		Active = true,
		Magnitude = __Magnitude,
		Roughness = math.clamp(__SpringShakeDefClass.Roughness or 0.2, 0, 500),
		FadeInTime = __SpringShakeDefClass.FadeInTime or 0.1,
		FadeOutTime = __SpringShakeDefClass.FadeOutTime or 0.5,
		Tension = math.clamp(__SpringShakeDefClass.Tension or 150, 0, 1500),
		Damping = __SpringShakeDefClass.Damping or 10,
		__JanitorClass = Janitor.new(),
		Velocity = __SpringShakeDefClass.Velocity or Vector3.zero,
		__RenderPriority = __SpringShakeDefClass.__RenderPriority or (Enum.RenderPriority.Camera.Value + 1),
		__Callback = nil,
		_PartnerLoop = false,
		RotationInfluence = __SpringShakeDefClass.RotationInfluence or Vector3.one,
		PositionInfluence = __SpringShakeDefClass.PositionInfluence or Vector3.one
	}, SpringShakerPresets)

	return (INSTANTIATOR_CLASS :: Batch.__camShakePreset) :: __SpringShakerClassDef
end

--[=[
    Retrieves a preset by name and returns a new Shaker instance.

    Usage: 
    ```lua 
    local SpringShaker = require(path.to.SpringShaker)
    local ExplosionShake = SpringShaker:GetPreset("Explosion")

    SpringShaker:ShakeOnce(ExplosionShake, 2)
    ```
    @param PresetName string -- The key name of the preset.
    @return __SpringShakerClassDef?
]=]
function SpringShaker:GetPreset(PresetName: string): __SpringShakerClassDef?
	local __presetAnnotator = SpringShaker._PresetsMap[PresetName]
	if not __presetAnnotator then
		return nil
	end
	return SpringShaker.new(__presetAnnotator)
end

--[=[
    Internal method to bind the shaker update loop to RenderStep.
    @param SpringDef __SpringShakerClassDef -- The instance to start rendering.
]=]
function SpringShaker:Start(SpringDef: __SpringShakerClassDef)
	assert(SpringDef, "Start method requires a valid shaker instance.")

	if SpringShaker._PartnerLoop then
		return
	end
	SpringShaker._PartnerLoop = true

	SpringDef.__JanitorClass:Add(function()
		if SpringShaker._PartnerLoop then
			RunService:UnbindFromRenderStep("PartnerLoop")
			SpringShaker._PartnerLoop = false
		end
	end, true)

	RunService:BindToRenderStep("PartnerLoop", SpringDef.__RenderPriority, function(DeltaTime)
		debug.profilebegin("SpringShakerClass")
		if #__classInstances == 0 then
			SpringShaker:Recycle(SpringDef)
			return
		end

		local _Offset = self:UpdateAll(DeltaTime)
		if _Offset then
			CurrentCamera.CFrame *= _Offset
		end
		debug.profileend()
	end)
end

--[=[
    Forces a specific shaker instance to stop rendering immediately.

    This does not use FadeOut method unlike :HaltDurationWise, so it will just stop the shaker without any fade effect.
    Used in benchmarking or emergency stops.
    @param SpringDef __SpringShakerClassDef -- The instance to halt.
]=]
function SpringShaker:Halt(SpringDef: __SpringShakerClassDef)
	if SpringDef._PartnerLoop then
		RunService:UnbindFromRenderStep("PartnerLoop")
	end
end

--[=[
    Iterates through all active shakers and triggers their FadeOut.
    @param FadeOutTime number? -- Optional time to override the preset's FadeOutTime.
]=]
function SpringShaker:HaltAll(FadeOutTime: number?)
	for _, shaker in ipairs(__classInstances) do
		if shaker.__SpringShakeInstance then
			shaker.__SpringShakeInstance:FadeOut(FadeOutTime or 0.5)
		end
	end
end

--[=[
    Immediately stops all rendering and cleans up all memory.
]=]
function SpringShaker:RecycleAll()
	for i = #__classInstances, 1, -1 do
		self:Recycle(__classInstances[i])
		table.remove(__classInstances, i)
	end
	table.clear(__classInstances)
end

--[=[
    Fades out all active shakers based on their current state.

    Usage: 
    ```lua 
    local SpringShaker = require(path.to.SpringShaker)
    local ExplosionShake = SpringShaker:GetPreset("Explosion")
    SpringShaker:ShakeSustained(ExplosionShake)

    task.delay(3, function()
        SpringShaker:HaltDurationWise(ExplosionShake.FadeOutTime) -- Smoothly fades out after 3 seconds.
    end)
    ```
    @param Time number? -- Optional override for the FadeOut duration.
]=]
function SpringShaker:HaltDurationWise(Time: number?)
	for _, shakerPreset in ipairs(__classInstances) do
		local mathInstance = shakerPreset.__SpringShakeInstance
		if mathInstance and not mathInstance:IsFadingOut() then
			mathInstance:FadeOut(Time or shakerPreset.FadeOutTime)
		end
	end
end

--[=[
    :::caution
    **DO NOT USE** - NOT INTENDED FOR GENERAL USE.
    * **SpringShaker** automatically runs this upon use!
    :::

    Internal core loop that calculates the combined CFrame of all active springs.

    @since v1.1
    @param dx number -- Delta time taken from each frames. Average (0.016 for 60fps).
    @return CFrame? -- It returns the CFrame of the both EulerAngles and the default positional influence CFrame. Or it could return nothing.
]=]

function SpringShaker:UpdateAll(dx: number): CFrame?
	if #__classInstances == 0 then
		return CFrame.identity
	end
	if not dx then
		return nil
	end

	local __rotdef, __posdef = Vector3.zero, Vector3.zero
	local MAX_OFFSET = 15
	local MAX_POS_OFFSET = 10

	for i = #__classInstances, 1, -1 do
		local __SpringShakerClass = __classInstances[i]
		local __SpringShakeInstance = __SpringShakerClass.__SpringShakeInstance

		if not __SpringShakeInstance then
			continue
		end

		local __component = __SpringShakeInstance:Update(dx)

		if __SpringShakeInstance:IsDead() then
			self:Recycle(__SpringShakerClass)
			table.remove(__classInstances, i)
			continue
		end

		__rotdef += (__component * __SpringShakeInstance.RotationInfluence)
		__posdef += (__component * __SpringShakeInstance.PositionInfluence)
	end

	if __rotdef.Magnitude > MAX_OFFSET then
		__rotdef = __rotdef.Unit * MAX_OFFSET
	end

	if __posdef.Magnitude > MAX_POS_OFFSET then 
		__posdef = __posdef.Unit * MAX_POS_OFFSET
	end


	return CFrame.fromEulerAnglesYXZ(math.rad(__rotdef.X), math.rad(__rotdef.Y), math.rad(__rotdef.Z))  
	* CFrame.new(__posdef)
end

--[=[
    Cleans up an individual shaker instance and its Janitor class.
    @param __SpringShakerClass __SpringShakerClassDef -- The specific instance to recycle.
]=]
function SpringShaker:Recycle(__SpringShakerClass: __SpringShakerClassDef)
	if not __SpringShakerClass then
		return
	end

	if __SpringShakerClass.__JanitorClass then
		__SpringShakerClass.__JanitorClass:Cleanup()
	end
end

--[=[
    Adds a shaker instance to the active stack.
    @param __SpringShakeInstance __SpringShakerClassDef -- The instance to append.
]=]
function SpringShaker:Append(__SpringShakeInstance: __SpringShakerClassDef)
	table.insert(__classInstances, __SpringShakeInstance)
end

--[=[
    Starts a shaker that lasts until manually stopped.
    Usage: 
    ```lua 
    local SpringShaker = require(path.to.SpringShaker)
    local ExplosionShake = SpringShaker:GetPreset("Explosion")
    SpringShaker:ShakeSustained(ExplosionShake)
    ```

    @param __SpringShakeInstance __SpringShakerClassDef -- The instance to use.
]=]
function SpringShaker:ShakeSustained(__SpringShakeInstance: __SpringShakerClassDef)
	__SpringShakeInstance.__SpringShakeInstance = ShakerInstances.new(__SpringShakeInstance)
	__SpringShakeInstance.__SpringShakeInstance:FadeIn(__SpringShakeInstance.FadeInTime)

	self:Append(__SpringShakeInstance)
	self:Start(__SpringShakeInstance)
end

--[=[
    Plays a shaker once for a specific duration.

    Usage: 
    ```lua 
    local SpringShaker = require(path.to.SpringShaker)
    local ExplosionShake = SpringShaker:GetPreset("Explosion")
    SpringShaker:ShakeOnce(ExplosionShake, 2)
    ```

    @param SpringDef __SpringShakerClassDef -- The instance configuration.
    @param Duration number? -- How long the shake should stay active.
]=]
function SpringShaker:ShakeOnce(SpringDef: __SpringShakerClassDef, Duration: number?)
	SpringDef.__SpringShakeInstance = ShakerInstances.new(SpringDef)
	SpringDef.__SpringShakeInstance:FadeIn(SpringDef.FadeInTime or 0.05) -- ramp up

	self:Append(SpringDef)
	self:Start(SpringDef)

	task.delay(Duration or 1, function()
		if SpringDef and SpringDef.__SpringShakeInstance then
			SpringDef.__SpringShakeInstance:FadeOut(SpringDef.FadeOutTime or 0.5)
		end
	end)
end

--[=[
Plays a shake once, but creates a fully independent instance per call.
Safe for rapid fire — each call lives and dies on its own without stomping previous shakes.
Useful for gun recoil, footsteps, or any shake that may be triggered multiple times in quick succession.

Usage:
```lua
local SpringShaker = require(path.to.SpringShaker)
SpringShaker:ShakeIndividual(SpringShaker:GetPreset("M2Recoil"), 0.3)
```

@param SpringDef __SpringShakerClassDef -- The preset configuration.
@param Duration number? -- How long before fadeout triggers.
@deprecated v1.1.3 -- This function is standard but it has complex issues over architecture. It can be usable, but for now it is deprecated. 
]=]
function SpringShaker:ShakeIndividual(SpringDef: __SpringShakerClassDef, Duration: number?)
	local instance = ShakerInstances.new(SpringDef)
	instance:FadeIn(SpringDef.FadeInTime or 0.04)

	local SpringShaker_Meta = getmetatable(SpringDef :: any)

	local individualClone: __SpringShakerClassDef = setmetatable({
		__SpringShakeInstance = instance,
		__JanitorClass = {
			Cleanup = function() end,
			Add = function() end,
		},
		__RenderPriority = SpringDef.__RenderPriority or (Enum.RenderPriority.Camera.Value + 1),
		FadeOutTime = SpringDef.FadeOutTime or 0.5,
		_PartnerLoop = false,
	}, SpringShaker_Meta) :: any

	self:Append(individualClone)
	self:Start(individualClone)

	task.delay(Duration or 1, function()
		if instance then
			instance:FadeOut(individualClone.FadeOutTime)
		end
	end)
end

return SpringShaker
