--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RankStructure = require(ReplicatedStorage.Structures.RankStructure)
local compute_level = require(ReplicatedStorage.ClientModules["compute-level"])
local future = require(ReplicatedStorage.Packages.future)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- rank-manager.luau
-- server-sided

local module = {}

function module:IncreaseRank(rank: string)
	local i = table.find(rank_order, rank)

	if i and rank_order[i + 1] then
		return rank_order[i + 1]
	end

	return rank
end

function module:DecreaseRank(rank: string)
	local i = table.find(rank_order, rank)

	if i and rank_order[i - 1] then
		return rank_order[i - 1]
	end

	return rank
end

return module
