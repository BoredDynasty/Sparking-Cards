return {
	-- North America
	US = "NA",
	CA = "NA",

	-- Brazil & Latin America
	BR = "BR",
	MX = "LAN",
	CR = "LAN",
	GT = "LAN",
	PA = "LAN",
	DO = "LAN",
	SV = "LAN",
	NI = "LAN",
	HN = "LAN",
	PR = "LAN",

	AR = "LAS",
	CL = "LAS",
	CO = "LAS",
	EC = "LAS",
	PE = "LAS",
	UY = "LAS",
	VE = "LAS",
	PY = "LAS",
	BO = "LAS",

	-- Western Europe
	GB = "EUW",
	FR = "EUW",
	DE = "EUW",
	NL = "EUW",
	BE = "EUW",
	IE = "EUW",
	CH = "EUW",
	AT = "EUW",
	DK = "EUW",
	NO = "EUW",
	SE = "EUW",
	FI = "EUW",
	IS = "EUW",
	PT = "EUW",
	ES = "EUW",
	IT = "EUW",
	LU = "EUW",

	-- Nordic & Eastern Europe
	PL = "EUNE",
	RO = "EUNE",
	HU = "EUNE",
	SK = "EUNE",
	CZ = "EUNE",
	SI = "EUNE",
	BG = "EUNE",
	GR = "EUNE",
	HR = "EUNE",
	EE = "EUNE",
	LT = "EUNE",
	LV = "EUNE",
	BA = "EUNE",
	ME = "EUNE",
	MK = "EUNE",
	RS = "EUNE",
	AL = "EUNE",

	-- Turkey & CIS
	TR = "TR",
	CY = "TR",
	RU = "RU",
	KZ = "RU",
	UA = "RU",

	-- Asia-Pacific
	KR = "KR",
	JP = "JP",
	SG = "SEA",
	MY = "SEA",
	ID = "SEA",
	TH = "SEA",
	PH = "SEA",
	VN = "SEA",
	HK = "SEA",
	TW = "SEA",

	-- Oceania
	AU = "OCE",
	NZ = "OCE",

	-- fallbacks for low-population or ambiguous regions
	-- Middle East & North Africa → EUW (closest backbone)
	AE = "EUW",
	SA = "EUW",
	IL = "EUW",
	EG = "EUW",
	MA = "EUW",
	DZ = "EUW",
	TN = "EUW",
	ZA = "EUW",
	NG = "EUW",
	KE = "EUW",
	-- South America (Antarctica, etc.) → NA or LAS
	AQ = "NA",
	GS = "NA",
	FK = "LAS",
	-- everything else default
	DEFAULT = "EUW",
}
