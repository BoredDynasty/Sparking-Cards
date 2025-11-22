--!strict

export type WeaponConfig = {
	Damage: number,
	AttackSpeed: number,
	ComboWindow: number,
	Animations: { [string]: string },
	Sounds: { [string]: string },
	VFX: { [string]: string },
}

local WeaponData: { [string]: WeaponConfig } = {
	Sword = {
		Damage = 10,
		AttackSpeed = 0.5,
		ComboWindow = 0.3,
		Animations = {
			Attack1 = "rbxassetid://1234567890",
			Attack2 = "rbxassetid://0987654321",
		},
		Sounds = {
			Swing = "rbxassetid://1111111111",
			Impact = "rbxassetid://2222222222",
		},
		VFX = {
			Slash = "SlashEffect",
			Impact = "ImpactEffect",
		}
	},
	-- Example of another weapon type
	Scythe = {
		Damage = 15,
		AttackSpeed = 0.8,
		ComboWindow = 0.5,
		Animations = {
			Attack1 = "rbxassetid://...",
			Attack2 = "rbxassetid://...",
		},
		Sounds = {
			Swing = "rbxassetid://...",
			Impact = "rbxassetid://...",
		},
		VFX = {
			Slash = "ScytheSlashEffect",
			Impact = "ImpactEffect",
		}
	}
}

return table.freeze(WeaponData)
