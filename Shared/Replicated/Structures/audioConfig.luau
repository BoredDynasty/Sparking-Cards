--!strict

-- audioConfig.luau

local tbl = {
	click = {
		id = 90092163763441,
		name = "click",
	},
	hover = {
		id = 119879668444252,
		name = "hover",
	},
	leave = {
		id = 85897203168160,
		name = "leave",
	},
	success = {
		id = 76288726968959,
		name = "success",
	},
	blastoff = {
		id = 551051176,
		name = "blastoff",
	},
	boom = {
		id = 269146157,
		name = "boom",
	},
}

local self = {
	getAudioConfig = function()
		return tbl
	end,
}

function self.getIdByName(name: string): number?
	for _, v in pairs(tbl) :: typeof(tbl) do
		if v.name == name then
			return v.id
		end
	end
	return nil
end

return self
