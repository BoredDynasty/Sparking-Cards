--!strict
-- CardLibrary.luau
-- Defines the available cards/weapon archetypes, their specific Orion attack names,
-- and associated passive abilities.

export type Card = {
	DisplayName: string,
	WeaponType: string, -- General category for the weapon type (e.g., "Gauntlet", "Sword")
	BaseDamageMultiplier: number, -- Base damage multiplier for this card's attacks
	MaxCombo: number, -- Max M1 combo count for this weapon/card
	MovesetName: string,
	TextColor: Color3,
	Moveset: {
		M1: string,
		Skill: string,
		Ultimate: string,
		Support: string,
		-- Potentially add M1_2, M1_3 etc. if combo pieces have unique AttackNames not covered by Orion
	},
	-- Other card-specific properties could include:
	-- DefaultDamageValues: { M1 = 10, Skill = 25, Ultimate = 50, Support = 0 }?
	-- DefaultCooldowns: { M1 = 0.5, Skill = 8, Ultimate = 20, Support = 15 }?
	-- AnimationIds: { M1 = "rbxassetid://...", Skill = "rbxassetid://..." }?
	-- SoundIds: { M1_Swing = "rbxassetid://...", Skill_Cast = "rbxassetid://..." }?
	-- StatusEffectOnHit: { Name: string, Chance: number, Duration: number, Potency: number }?,
}
local CardLibrary = {
	CryoGauntlet = {
		DisplayName = "Cryo Gauntlet",
		WeaponType = "Gauntlet",
		MovesetName = "Glacial Emperor's Decree",
		TextColor = Color3.fromRGB(100, 193, 255),
		BaseDamageMultiplier = 1.15,
		MaxCombo = 7,
		Moveset = {
			M1 = "CryoGauntlet_M1_1",
			Skill = "CryoGauntlet_IceShard_Skill",
			Ultimate = "CryoGauntlet_Blizzard_Ultimate",
			Support = "CryoGauntlet_Aegis_Support",
		},
	},
	PyroKatana = {
		DisplayName = "Pyro Katana",
		WeaponType = "Sword",
		MovesetName = "Conflagration of the Blazing Heart",
		TextColor = Color3.fromRGB(255, 88, 88),
		BaseDamageMultiplier = 1.3,
		MaxCombo = 3,

		Moveset = {
			M1 = "PyroKatana_M1_1",
			Skill = "PyroKatana_Slash_Skill",
			Ultimate = "PyroKatana_InfernalSlash_Ultimate",
			Support = "PyroKatana_HeatAura_Support",
		},
	},
	HydroCatalyst = {
		DisplayName = "Hydro Catalyst",
		WeaponType = "Catalyst",
		MovesetName = "Tidal Sovereign's Judgment",
		TextColor = Color3.fromRGB(119, 151, 255),
		BaseDamageMultiplier = 1.1,
		MaxCombo = 3,
		Moveset = {
			M1 = "HydroCatalyst_WashingTide_1",
			Skill = "HydroCatalyst_Vortex_Skill",
			Ultimate = "HydroCatalyst_BlueTyphoon_Ultimate",
			Support = "HydroCatalyst_WaveRider_Support",
		},
	},
	ShadowScythe = {
		DisplayName = "Shadow Scythe",
		WeaponType = "Scythe",
		MovesetName = "Oblivion Reap",
		TextColor = Color3.fromRGB(80, 0, 120),
		BaseDamageMultiplier = 1.35,
		Moveset = {
			M1 = "ShadowScythe_VoidSlice_1",
			Skill = "ShadowScythe_DarkSpiral_Skill",
			Ultimate = "ShadowScythe_OblivionRift_Ultimate",
			Support = "ShadowScyhe_FadeStep_Support",
		},
	},
	AnemoTwinBlades = {
		DisplayName = "Anemo Twin Blades",
		WeaponType = "TwinBlades",
		MovesetName = "Heavenly Current",
		TextColor = Color3.fromRGB(180, 255, 243),
		BaseDamageMultiplier = 1.05,
		Moveset = {
			M1 = "AnemoTwinBlades_GaleSlash_1",
			Skill = "AnemoTwinBlades_CycloneStep_Skill",
			Ultimate = "AnemoTwinBlades_Heaven'sCurrent_Ultimate",
			Support = "AnemoTwinBlades_AirStep_Support",
		},
	},

	-- geo claymore
	GeoClaymore = {
		DisplayName = "Geo Claymore",
		WeaponType = "Claymore",
		MovesetName = "Stonebound Oath",
		TextColor = Color3.fromRGB(180, 120, 60),
		BaseDamageMultiplier = 1.4,
		Moveset = {
			M1 = "GeoClaymore_StoneSlam_1",
			Skill = "GeoClaymore_QuakeSpiral_Skill",
			Ultimate = "GeoClaymore_Earthshatter_Ultimate",
			Support = "GeoClaymore_GraniteGuard_Support",
		},
	},

	-- light staff
	LightStaff = {
		DisplayName = "Light Staff",
		WeaponType = "Staff",
		MovesetName = "Radiant Canon",

		TextColor = Color3.fromRGB(255, 255, 200),
		BaseDamageMultiplier = 1.1,
		Moveset = {
			M1 = "LightStaff_RadiantStrike_1",
			Skill = "LightStaff_SolarFlare_Skill",
			Ultimate = "LightStaff_DivineNova_Ultimate",
			Support = "LightStaff_GloryShield_Support",
		},
	},

	-- electro polearm
	ElectroPolearm = {
		DisplayName = "Electro Polearm",
		WeaponType = "Polearm",
		MovesetName = "Stormpiercer Art",
		TextColor = Color3.fromRGB(200, 180, 255),
		BaseDamageMultiplier = 1.25,
		Moveset = {
			M1 = "ElectroPolearm_ThunderPierce_1",
			Skill = "ElectroPolearm_StaticSurge_Skill",
			Ultimate = "ElectroPolearm_ThunderGate_Ultimate",
			Support = "ElectroPolearm_ChargeGuard_Support",
		},
	},

	PoisonDagger = {
		DisplayName = "Posion Dagger",
		WeaponType = "Dagger",
		MovesetName = "Virulent Whisper",
		TextColor = Color3.fromRGB(140, 200, 90),
		BaseDamageMultiplier = 1.2,
		Moveset = {
			M1 = "PoisonDagger_Venom_Lash_1",
			Skill = "PoisonDagger_Toxic_Spiral_Skill",
			Ultimate = "PoisonDagger_Acid_Bloom_Ultimate",
			Supprt = "PoisonDagger_Plague_Waltz_Support",
		},
	},

	-- Add more cards/weapons here
	-- goal is to have almost all known/fictional elements
	-- in this chart
}

return CardLibrary
