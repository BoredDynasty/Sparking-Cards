--!strict

local regioncodes = require(script.regioncodes)

-- MatchMaker.luau

local matchmaker = {
	match_makers = {},
	regioncodes = regioncodes,
}
matchmaker.__index = matchmaker
