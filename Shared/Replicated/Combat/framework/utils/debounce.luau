--!nonstrict

-- debounce.luau

-- a debounce class for handling all the movement-related events

local debounce = {}
debounce.__index = debounce

export type debounces = {
	M1: number,
	Skill: number,
	Ultimate: number,
	Support: number,
}

function debounce.new(params: debounces)
	local proxyTable = {}
	for moveName: string, delayTime: number in pairs(params) do
		proxyTable[moveName] = {
			moveName = moveName,
			lastCall = tick(),
			delayTime = delayTime,
		}
	end
	return setmetatable(proxyTable, debounce)
end

function debounce:__call(moveName: string)
	local currentTime = tick()
	local lastCall = self[moveName].lastCall
	local delayTime = self[moveName].delayTime

	if currentTime - lastCall >= delayTime then
		self[moveName].lastCall = currentTime -- Update the last call time
		return true
	end

	return false
end

return debounce
