--[[
You can add any types of Presets here as long as it follows the format below:
PresetName = {
    Magnitude: number, 
    Roughness: number, 
    FadeInTime: number, 
    FadeOutTime: number, 
    Tension: number, 
    Damping: number, 
    RotationInfluence: Vector3, 

	Critical damping threshold: Damping ≈ 2 * sqrt(Tension)
	e.g. Tension=150 → ideal Damping ≈ 24.5, so 22–28 is a good cinematic range
	Going below this gives a subtle ring/bounce; going above kills motion too fast.
	RotationInfluence should stay small (-1 to 1) for cinematic subtlety.
	Roughness above ~10 starts feeling artificial/jittery rather than physical.
}
To run it, you just have to use the function of :GetPreset() and enter a valid Preset (string).
]]

local Presets = {
	-- A distant, heavy detonation. Head snaps back, slight leftward torque from shockwave.
	Explosion = {
		Magnitude = 8,
		Roughness = 25,
		FadeInTime = 0,
		FadeOutTime = 1.2,
		Tension = 400,
		Damping = 45,
		RotationInfluence = Vector3.new(-0.8, -0.25, 0.4),
	},
	-- Underfoot blast. Sharp downward snap then chaotic recovery.
	Landmine = {
		Magnitude = 3,
		Roughness = 30,
		FadeInTime = 0,
		FadeOutTime = 0.4,
		Tension = 600,
		Damping = 60,
		RotationInfluence = Vector3.new(-0.5, 0.15, -0.2),
	},
	-- Rolling ground tremor. Z dominant, asymmetric pitch for organic feel.
	Earthquake = {
		Magnitude = 6,
		Roughness = 6.4,
		FadeInTime = 2.5,
		FadeOutTime = 9.0,
		Tension = 400,
		RotationInfluence = Vector3.new(-0.2, -0.1, 1),
	},
	-- Nearby explosive impact. Sharp upward flinch, slight left bias.
	ExplosiveBullet = {
		Magnitude = 1.5,
		Roughness = 45,
		FadeInTime = 0,
		FadeOutTime = 0.2,
		Tension = 800,
		Damping = 70,
		RotationInfluence = Vector3.new(-0.35, -0.15, 0.1),
	},
	-- Mechanical vibration. Symmetric, no dominant axis.
	Vibration = {
		Magnitude = 0.2,
		Roughness = 50,
		FadeInTime = 1.0,
		FadeOutTime = 1.0,
		Tension = 1000,
		Damping = 80,
		RotationInfluence = Vector3.new(0.08, -0.05, 0.1),
	},
	-- Heavy landing. Nose dips forward on impact, slight rightward stumble.
	Bounce = {
		Magnitude = 2.0,
		Roughness = 5,
		FadeInTime = 0,
		FadeOutTime = 0.8,
		Tension = 150,
		Damping = 12,
		RotationInfluence = Vector3.new(-0.5, 0.1, -0.2),
	},
	-- Something massive approaching. Builds slowly, multi-axis swell.
	Resonance = {
		Magnitude = 5.0,
		Roughness = 12,
		FadeInTime = 4.0,
		FadeOutTime = 2.0,
		Tension = 200,
		Damping = 15,
		RotationInfluence = Vector3.new(-0.4, -0.2, 0.5),
	},
	-- Distant vehicle or structural stress. Subtle, low and persistent.
	Rumble = {
		Magnitude = 1.5,
		Roughness = 8,
		FadeInTime = 1.8,
		FadeOutTime = 3.5,
		Tension = 180,
		Damping = 18,
		RotationInfluence = Vector3.new(-0.15, 0.1, 0.2),
	},
	-- Sharp hit to the player. Head snaps back and slightly right.
	Impact = {
		Magnitude = 3.5,
		Roughness = 20,
		FadeInTime = 0,
		FadeOutTime = 0.35,
		Tension = 500,
		Damping = 50,
		RotationInfluence = Vector3.new(-0.5, 0.25, -0.15),
	},
	-- M2 Browning recoil. Muzzle climbs, slight rightward torque from bolt.
	M2Recoil = {
		Magnitude = 1.2,
		Roughness = 30,
		FadeInTime = 0.04,
		FadeOutTime = 0.25,
		Tension = 800,
		Damping = 65,
		RotationInfluence = Vector3.new(-0.35, 0.08, -0.05),
	},
}
return Presets
