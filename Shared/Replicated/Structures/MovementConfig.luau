--!strict
return {
	Keybinds = {
		Sprint = Enum.KeyCode.LeftShift,
		Slide = Enum.KeyCode.C,
		CancelSlide = Enum.KeyCode.Space,
		Dash = Enum.KeyCode.V,
	},
	Character = {
		BaseSpeed = 14,
		MaxSpeed = 18,
		AccelerationRate = 2,
		StaminaRate = 10,
		BaseFieldOfView = 70,
	},
	Debounces = {
		Sprint = {
			Active = false,
			Cooldown = 0.6,
		},
		Jump = {
			Active = false,
			Cooldown = 0.8,
		},
		Slide = {
			Active = true,
			Cooldown = 2,
		},
		Dash = {
			Active = false,
			Cooldown = 3,
		},
	},
	HipHeight = {
		Normal = 0,
		Slide = -2,
	},
	Velocity = {
		Forward = 1,
		Upward = 2,
		Downward = 1,
	},
	PushVelocity = {
		Forward = 50,
		Upward = 50,
	},
	Animations = {
		Walk = {
			Id = "rbxassetid://14608793266",
			Weight = 1,
			Speed = 1,
		},
		Run = {
			Id = "rbxassetid://14608790956",
			Weight = 1,
			Speed = 1,
		},
		Slide = {
			Id = "rbxassetid://14608790956",
			Weight = 1,
			Speed = 1,
		},
		Dash = {
			Id = "rbxassetid://14608790956",
			Weight = 1,
			Speed = 1,
		},
	},
	Jump = {
		StaminaCost = 10,
	},
	Sprint = {
		SpeedIncrease = 18,
		StaminaDrainRate = 10,
		FieldOfViewIncrease = 10,
	},
	Slide = {
		Cooldown = 2,
		BaseSpeed = 50,
		SpeedLossFlat = 1,
		SpeedLossUp = 2,
		SpeedGainDown = 1,
		CancelPushForward = 50,
		CancelPushUpward = 50,
	},
	Dash = {
		Cooldown = 3,
		Force = 100,
		Duration = 0.3,
		StaminaCost = 15,
	},
}
