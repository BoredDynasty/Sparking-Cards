--!native

--[[
	rbx deeplink
	utility functions for dealing w roblox deeplinks
]]

local url = require("../Modules/Serialization/url")

local REGULAR_FORMAT = "https://www.roblox.com/games/start?placeId=%*&launchData=%*"
local APPSFLYER_FORMAT = "https://ro.blox.com/Ebh5?af_dp=%*&af_web_dp=%*"
local DATA_LEN_LIMIT = 200
local DATA_LEN_ERROR = `[RBX DEEPLINK] data provided exceeds {DATA_LEN_LIMIT} characters`

local rbxdeeplink = {}

function rbxdeeplink.get_launchdata(player: Player): string?
	local launch_data = player:GetJoinData().LaunchData

	if launch_data and #launch_data ~= 0 then
		local decoded = url.decode(launch_data)
		-- pattern for getting a string with a non zero length
		-- right after "&launchdata=" that doesn't include the & character
		return string.match(decoded, "&launchdata=([^&]+)")
	else
		return nil
	end
end

function rbxdeeplink.format_appsflyer(
	placeid: number,
	data: string,
	encode_spaces_as: url.SpaceEncoding?
): string
	if #data > DATA_LEN_LIMIT then
		error(DATA_LEN_ERROR)
	else
		local regular = url.encode(string.format(REGULAR_FORMAT, placeid, data), encode_spaces_as)
		return string.format(APPSFLYER_FORMAT, regular, regular)
	end
end

function rbxdeeplink.format(placeid: number, data: string, encode_spaces_as: url.SpaceEncoding?): string
	if #data > DATA_LEN_LIMIT then
		error(DATA_LEN_ERROR)
	else
		return string.format(REGULAR_FORMAT, placeid, url.encode(data, encode_spaces_as))
	end
end

return table.freeze(rbxdeeplink)
