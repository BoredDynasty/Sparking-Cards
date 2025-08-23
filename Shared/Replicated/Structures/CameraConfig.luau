--!strict

--[=[
	CameraConfig
	@module CameraConfig

	Centralized configuration for the camera system.
]=]

local CameraConfig = {
	BaseFOV = 70,

	Offset = {
		Offset = Vector3.new(2, 2, 6), -- Right, Up, Back
		Smoothness = 0.15,
	},

	Sway = {
		MaxSway = 6,
		SwayLerpSpeed = 10,
	},

	Follow = {
		MaxTilt = 8,
	},

	Trail = {
		Offset = Vector3.new(0, 0, -10),
		TrailAlpha = 0.1,
	},

	Shake = {
		DefaultStrength = 5,
	},

	Recoil = {
		DefaultStrength = 2,
		DefaultDuration = 0.1,
	},

	Idle = {
		IdleTime = 5, -- seconds
		Speed = 0.1,
		Intensity = 0.05,
	},
}

return CameraConfig
