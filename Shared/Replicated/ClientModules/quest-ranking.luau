--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local compute_level = require(script.Parent["compute-level"])
local future = require(ReplicatedStorage.Packages.future)

-- quest-ranking.luau

-- for giving availiable quests
-- for each rank

local module = {
	registered = {
		[1] = {
			"take-a-hike",
		},
	},
}

local function getObjectivesFromRank(rank: number)
	return future
		.new(function(...)
			return module.registered[rank]
		end)
		:Unwrap()
end

return setmetatable({
	GetQuestsFromRank = getObjectivesFromRank,
}, {
	__call = function()
		return module
	end,
})
