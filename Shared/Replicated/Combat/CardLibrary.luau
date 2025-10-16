--!strict
-- CardLibrary.luau
-- Defines the available cards/weapon archetypes, their specific Orion attack names,
-- and associated passive abilities.

export type Card = {
	DisplayName: string,
	WeaponType: string, -- General category for the weapon type (e.g., "Gauntlet", "Sword")
	BaseDamageMultiplier: number, -- Base damage multiplier for this card's attacks
	MaxCombo: number, -- Max M1 combo count for this weapon/card
	MovesetName: string?,
	FlavorText: string?,
	TextColor: Color3?,
	HighlightedFlavorTextTags: { string }?,
	Moveset: {
		M1: string, -- AttackName for the first M1 attack (e.g., "CryoGauntlet_M1_1")
		Skill: string, -- AttackName for the E skill (e.g., "CryoGauntlet_IceShard_Skill")
		Ultimate: string, -- AttackName for the Q ultimate (e.g., "CryoGauntlet_BlizzardRush_Ultimate")
		Support: string?, -- Optional AttackName for the R support move
		-- Potentially add M1_2, M1_3 etc. if combo pieces have unique AttackNames not covered by Orion's NextComboAttack
	},
	PassiveModuleName: string?, -- Optional name of the passive module associated with this card (e.g., "CryoArmor")
	-- Other card-specific properties could include:
	-- DefaultDamageValues: { M1 = 10, Skill = 25, Ultimate = 50, Support = 0 }?
	-- DefaultCooldowns: { M1 = 0.5, Skill = 8, Ultimate = 20, Support = 15 }?
	-- AnimationIds: { M1 = "rbxassetid://...", Skill = "rbxassetid://..." }?
	-- SoundIds: { M1_Swing = "rbxassetid://...", Skill_Cast = "rbxassetid://..." }?
	-- StatusEffectOnHit: { Name: string, Chance: number, Duration: number, Potency: number }?,
}

-- It's crucial that the AttackNames listed in Moveset (e.g., "CryoGauntlet_M1_1")
-- from the combat modules (e.g., Cryo.moveset.M1) with Orion.RegisterAttack.

local CardLibrary = {
	CryoGauntlet = {
		DisplayName = "Cryo Gauntlet",
		WeaponType = "Gauntlet",
		MovesetName = "Glacial Emperor's Decree",
		FlavorText = [[
		The will of the tundra made manifest; where the Emperor treads, life itself slows to a halt.
		]],
		TextColor = Color3.fromRGB(100, 193, 255),
		BaseDamageMultiplier = 1.0,
		MaxCombo = 7,
		Moveset = {
			M1 = "CryoGauntlet_M1_1",
			Skill = "CryoGauntlet_IceShard_Skill",
			Ultimate = "CryoGauntlet_Blizzard_Ultimate",
			Support = "CryoGauntlet_Aegis_Support",
		},
		PassiveModuleName = "PermaFrost",
	},
	PyroKatana = {
		DisplayName = "Fiery Katana",
		WeaponType = "Sword",
		MovesetName = "Conflagration of the Blazing Heart",
		FlavorText = [[
		A single spark, given the will to burn the world.
		]],
		HighlightedFlavorTextTags = {
			"spark",
			"burn",
		},
		TextColor = Color3.fromRGB(255, 88, 88),
		BaseDamageMultiplier = 1.1,
		MaxCombo = 3,

		Moveset = {
			M1 = "PyroKatana_M1_1",
			Skill = "PyroKatana_BurningBlade_Skill",
			Ultimate = "PyroKatana_InfernalSlash_Ultimate",
			Support = "PyroKatana_HeatAura_Support",
		},
		AttackSpeed = 0.4,
		RecoveryTime = 0.5,
		StunTime = 0.175,
		HitboxSize = vector.one * 5,
		PassiveModuleName = "DrawIn",
	},
	HydroCatalyst = {
		DisplayName = "Hydro Catalyst",
		WeaponType = "Catalyst",
		MovesetName = "Tidal Sovereign's Judgment",
		FlavorText = [[
		In the crushing darkness of the abyss, even light bends. Accept the judgment of the tides.
		]],
		TextColor = Color3.fromRGB(119, 151, 255),
		BaseDamageMultiplier = 1.15,
		MaxCombo = 3,
		Moveset = {
			M1 = "HydroCatalyst_WashingTide_1",
			Skill = "HydroCatalyst_Vortex_Skill",
			Ultimate = "HydroCatalyst_BlueTyphoon_Ultimate",
			Support = "CryoGauntlet_TidalSurge_Support",
		},
		PassiveModuleName = "WaveRider",
	},
	ShadowPolearm = {
		DisplayName = "ShadowReaper Polearm",
		WeaponType = "Polearm",
		BaseDamageMultiplier = 1.2,
		MaxCombo = 2,
		Moveset = {
			M1 = "ShadowPolearm_M1_1",
			Skill = "ShadowPolearm_SpectralReach_Skill",
			Ultimate = "ShadowPolearm_VoidSweep_Ultimate",
			Support = nil,
		},
		PassiveModuleName = "ShadowLeech", -- Example for a hypothetical passive
	},
	StoneClaymore = {
		DisplayName = "Granite Greatsword",
		WeaponType = "Claymore",
		BaseDamageMultiplier = 0.9,
		MaxCombo = 3,
		Moveset = {
			M1 = "StoneClaymore_M1_1",
			Skill = "StoneClaymore_Earthshatter_Skill",
			Ultimate = "StoneClaymore_QuakeStomp_Ultimate",
			Support = "StoneClaymore_RockWall_Support",
		},
		PassiveModuleName = "StoneForm", -- Example for a hypothetical passive
	},
	-- Add more cards/weapons here
}

return CardLibrary
