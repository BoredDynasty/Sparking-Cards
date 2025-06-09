--!strict

--# selene: allow(incorrect_standard_library_use)

local net = require("@lune/net") -- library for making HTTP requests
local roblox = require("@lune/roblox") -- roblox library

return function(placeId: number)
	local cookie = roblox.getAuthCookie()
	assert(cookie, "Failed to get auth cookie")

	local result = net.request({
		url = "https://assetdelivery.roblox.com/v1/asset/",
		headers = {
			Cookie = cookie,
		},
		query = {
			id = tostring(placeId),
		},
	})

	--assert(result.ok, result.body)
	print(result.ok)
	print(result.body)
	print(result.headers)

	return result.body
end
