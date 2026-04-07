--!strict
--!native

--[=[
    @class Batch
    Internal type definitions and shared state enums for SpringShaker.
    Not intended for direct use.
]=]
local Batch = {}

--[=[
    @type __SpringShakerClassMeta {	Magnitude: number, Roughness: number, FadeInTime: number, FadeOutTime: number, Velocity: Vector3, Tension: number, Damper: number,RotationInfluence: Vector3, PositionInfluence: Vector3, Elapsed: number, SustainComplex: boolean, Position: Vector3, CurrentTime: number, Active: boolean, Tick: number, State: CamShakeStates, Update: (self: __SpringShakerClassMeta, dt: number) -> Vector3, FadeOut: (self: __SpringShakerClassMeta, time: number) -> (), FadeIn: (self: __SpringShakerClassMeta, time: number) -> (), IsShaking: (self: __SpringShakerClassMeta) -> boolean, IsFadingOut: (self: __SpringShakerClassMeta) -> boolean, IsFading: (self: __SpringShakerClassMeta) -> boolean, IsDead: (self: __SpringShakerClassMeta) -> boolean, GetState: (self: __SpringShakerClassMeta) -> number, GetFadeMagnitude: (self: __SpringShakerClassMeta) -> number}
    @within Batch
    Internal math state maintained per shaker instance. Not intended for direct access.
]=]
export type __SpringShakerClassMeta = {
	Magnitude: number,
	Roughness: number,
	FadeInTime: number,
	FadeOutTime: number,
	Velocity: Vector3,
	Tension: number,
	Damper: number,
	RotationInfluence: Vector3,
	PositionInfluence: Vector3,
	Elapsed: number,
	SustainComplex: boolean,
	Position: Vector3,
	CurrentTime: number,
	Active: boolean,
	Tick: number,
	State: CamShakeStates,
	Update: (self: __SpringShakerClassMeta, dt: number) -> Vector3,
	FadeOut: (self: __SpringShakerClassMeta, time: number) -> (),
	FadeIn: (self: __SpringShakerClassMeta, time: number) -> (),
	IsShaking: (self: __SpringShakerClassMeta) -> boolean,
	IsFadingOut: (self: __SpringShakerClassMeta) -> boolean,
	IsFading: (self: __SpringShakerClassMeta) -> boolean,
	IsDead: (self: __SpringShakerClassMeta) -> boolean,
	GetState: (self: __SpringShakerClassMeta) -> number,
	GetFadeMagnitude: (self: __SpringShakerClassMeta) -> number,
}

--[=[
    @type __camShakePreset {Magnitude: number, Roughness: number, FadeInTime: number, FadeOutTime: number, Tension: number, Damping: number, Velocity: Vector3, RotationInfluence: Vector3, PositionInfluence: Vector3, __RenderPriority: number}
    @within Batch
    Configuration table passed into SpringShaker.new() or returned by :GetPreset().
]=]
export type __camShakePreset = {
	__SpringShakeInstance: __SpringShakerClassMeta,
	_PartnerLoop: boolean,
	Magnitude: number,
	Roughness: number,
	FadeInTime: number,
	Tension: number,
	Damping: number,
	Velocity: Vector3,
	__JanitorClass: any,
	FadeOutTime: number,
	RotationInfluence: Vector3,
	PositionInfluence: Vector3,
	__RenderPriority: number,
}

local __camShakeStates = {
	Reserved = -1,
	Inactive = 0,
	Active = 1,
	FadeInProgress = 2,
	FadeOutProgress = 3,
}

--[=[
    @type CamShakeStates {Reserved: number, Inactive: number, Active: number, FadeInProgress: number, FadeOutProgress: number}
    @within Batch
    Enum values representing the current state of a shaker instance.
]=]
export type CamShakeStates = typeof(__camShakeStates)

local __camShakePresetConfiguration = {
	MAGNITUDE = "Magnitude",
	ROUGHNESS = "Roughness",
	FADEOUTTIME = "FadeOutTime",
	FADEINTIME = "FadeInTime",
	VELOCITY = "Velocity",
	DAMPING = "Damping",
	TENSION = "Tension",
}

Batch.BuildInPresets = {
	__presetConfig = __camShakePresetConfiguration,
	__camShakeStates = __camShakeStates,
}

return Batch
