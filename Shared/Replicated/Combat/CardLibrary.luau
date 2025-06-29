--!strict
-- CardLibrary.luau
-- Defines the available cards/weapon archetypes, their specific Orion attack names,
-- and associated passive abilities.

export type Card = {
	DisplayName: string,
	WeaponType: string, -- General category for the weapon type (e.g., "Gauntlet", "Sword")
	BaseDamageMultiplier: number, -- Base damage multiplier for this card's attacks
	MaxCombo: number, -- Max M1 combo count for this weapon/card
	Moveset: {
		M1: string, -- AttackName for the first M1 attack (e.g., "FrostGauntlet_M1_1")
		Skill: string, -- AttackName for the E skill (e.g., "FrostGauntlet_IceShard_Skill")
		Ultimate: string, -- AttackName for the Q ultimate (e.g., "FrostGauntlet_BlizzardRush_Ultimate")
		Support: string?, -- Optional AttackName for the R support move
		-- Potentially add M1_2, M1_3 etc. if combo pieces have unique AttackNames not covered by Orion's NextComboAttack
	},
	PassiveModuleName: string?, -- Optional name of the passive module associated with this card (e.g., "FrostArmor")
	-- Other card-specific properties could include:
	-- DefaultDamageValues: { M1 = 10, Skill = 25, Ultimate = 50, Support = 0 }?
	-- DefaultCooldowns: { M1 = 0.5, Skill = 8, Ultimate = 20, Support = 15 }?
	-- AnimationIds: { M1 = "rbxassetid://...", Skill = "rbxassetid://..." }?
	-- SoundIds: { M1_Swing = "rbxassetid://...", Skill_Cast = "rbxassetid://..." }?
	-- StatusEffectOnHit: { Name: string, Chance: number, Duration: number, Potency: number }?,
}

-- It's crucial that the AttackNames listed in Moveset (e.g., "FrostGauntlet_M1_1")
-- are unique and are used by CombatModuleManager to register the corresponding functions
-- from the combat modules (e.g., Frost.moveset.M1) with Orion.RegisterAttack.

local CardLibrary: { [string]: Card } = {
	FrostGauntlet = {
		DisplayName = "Frost Gauntlets",
		WeaponType = "Gauntlet",
		BaseDamageMultiplier = 1.0,
		MaxCombo = 3,
		Moveset = {
			M1 = "FrostGauntlet_M1_1",
			Skill = "FrostGauntlet_IceShard_Skill",
			Ultimate = "FrostGauntlet_BlizzardRush_Ultimate",
			Support = "FrostGauntlet_CryoBarrier_Support",
		},
		PassiveModuleName = "FrostArmor", -- Links to game/Server/Passives/FrostArmor.lua
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
		PassiveModuleName = nil, -- Example: No passive, or passive name TBD
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
