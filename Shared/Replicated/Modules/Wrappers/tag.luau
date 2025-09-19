--!strict
local CollectionService = game:GetService("CollectionService")

-- tag.luau
-- a wrapper for CollectioService

local tag_module = {}

function tag_module:for_eachi<I..., R...>(tag: string, f: (I...) -> R..., ...: I...): R...
	for i, inst in ipairs(CollectionService:GetTagged(tag)) do
		return f(...)
	end
end

return tag_module
