--!strict

local ExperienceManager = {}

local function toRomanNumeral(number: number): string
	local romanNumerals = {
		[1] = "I",
		[2] = "II",
		[3] = "III",
		[4] = "IV",
		[5] = "V",
		[6] = "VI",
		[7] = "VII",
		[8] = "VIII",
		[9] = "IX",
		[10] = "X",
	}

	return romanNumerals[number] or "Invalid number"
end

ExperienceManager.RegisteredLevels = {
	[1] = "Bronze",
	[2] = "Silver",
	[3] = "Gold",
	[4] = "Platinum",
	[5] = "Diamond",
	[6] = "Master",
}

ExperienceManager.toRomanNumeral = toRomanNumeral

return ExperienceManager
