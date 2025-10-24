--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local compute_level = require(script.Parent["compute-level"])
local promise = require(ReplicatedStorage.Packages.promise)
local quest = require(script.Parent.quest)

-- quest-ranking.luau

-- for giving availiable quests
-- for each rank

local self = {
	registered = {
		[1] = {
			"take-a-hike",
		},
	},
}

local function getObjectivesFromRank(rank: number): { string }
	return promise
		.new(function(resolve: ({ string }) -> ...unknown)
			resolve(self.registered[rank])
		end)
		:catch(print)
		:expect()
end

function getRankFromObjective(objective: string): string?
	return promise
		.new(function(resolve: (string?) -> ...unknown)
			for i, data in pairs(self.registered) do
				for j, name in ipairs(data) do
					if string.lower(name) == string.lower(objective) then
						local rankName = compute_level.rankNumberToName(i)
						if rankName then
							resolve(rankName)

							break -- stawp~!
						else
							resolve(nil)
						end
					end
				end
			end
		end)
		:catch(print)
		:expect()
end

return setmetatable({
	getObjectivesFromRank = getObjectivesFromRank,
	getRankFromObjective = getRankFromObjective,
}, {
	__call = function()
		return self
	end,
})
