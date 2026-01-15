--!nonstrict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local promise = require(ReplicatedStorage.Packages.promise)

-- tag.luau
-- a wrapper for CollectionService

local tag_module = {}

function tag_module:for_eachi<I..., R...>(tag: string, f: (I...) -> R..., ...: I...): R...
	local var_arg = { ... }

	for i, inst in ipairs(CollectionService:GetTagged(tag)) do
		return select(
			2,
			promise
				.new(function(resolve)
					local x = f(unpack(var_arg))
					resolve(x)
					return x
				end)
				:await()
		)
	end
end

return tag_module
