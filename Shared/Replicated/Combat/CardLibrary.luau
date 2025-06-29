-- CardLibrary.luau
-- Defines the available cards/weapon archetypes and their specific Orion attack names.

export type Card = {
	DisplayName: string,
	WeaponType: string, -- General category for the weapon type
	BaseDamageMultiplier: number, -- Base damage multiplier for this card
	MaxCombo: number, -- Max M1 combo count for this weapon
	Moveset: {
		M1: string, -- AttackName for the first M1 attack
		Skill: string, -- AttackName for the E skill
		Ultimate: string, -- AttackName for the Q ultimate
		Support: string?, -- AttackName for R if this card has a support move
	},
	-- Other card-specific properties can go here
	-- e.g., StatusEffectOnHit?: { Name: string, Chance: number, Duration: number },
}

return {
	FrostGauntlet = {
		DisplayName = "Frost Gauntlets",
		WeaponType = "Gauntlet", -- General category, can be used for specific logic if needed
		BaseDamageMultiplier = 1.0,
		MaxCombo = 3, -- Max M1 combo count for this weapon
		Moveset = {
			M1 = "FrostGauntlet_M1_1", -- AttackName for the first M1 attack
			Skill = "FrostGauntlet_IceShard_Skill", -- AttackName for the E skill
			Ultimate = "FrostGauntlet_BlizzardRush_Ultimate", -- AttackName for the Q ultimate
			Support = "FrostGauntlet_CryoBarrier_Support", -- AttackName for R if this card has a support move
		},
		-- Other card-specific properties can go here
		-- e.g., StatusEffectOnHit = { Name = "Slow", Chance = 0.3, Duration = 2 },
	},
	FireSword = {
		DisplayName = "Fiery Longsword",
		WeaponType = "Sword",
		BaseDamageMultiplier = 1.1,
		MaxCombo = 4,
		Moveset = {
			M1 = "FireSword_M1_1",
			Skill = "FireSword_BurningBlade_Skill",
			Ultimate = "FireSword_InfernoSlash_Ultimate",
			Support = "FireSword_HeatAura_Support",
		},
	},
	ShadowPolearm = {
		DisplayName = "ShadowReaper Polearm",
		WeaponType = "Polearm",
		BaseDamageMultiplier = 1.2,
		MaxCombo = 2, -- Example: Polearms might have fewer but stronger M1s
		Moveset = {
			M1 = "ShadowPolearm_M1_1",
			Skill = "ShadowPolearm_SpectralReach_Skill",
			Ultimate = "ShadowPolearm_VoidSweep_Ultimate",
			Support = nil, -- Example: This weapon has no dedicated support move via CardLibrary
		},
	},
	StoneClaymore = {
		DisplayName = "Granite Greatsword",
		WeaponType = "Claymore",
		BaseDamageMultiplier = 0.9, -- Example: Slower but maybe higher base damage on attacks
		MaxCombo = 3,
		Moveset = {
			M1 = "StoneClaymore_M1_1",
			Skill = "StoneClaymore_Earthshatter_Skill",
			Ultimate = "StoneClaymore_QuakeStomp_Ultimate",
			Support = "StoneClaymore_RockWall_Support",
		},
	},
	-- Add more cards/weapons here
}
