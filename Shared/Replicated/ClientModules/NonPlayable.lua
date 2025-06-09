--!strict

local NonPlayable = {}
NonPlayable.__index = NonPlayable

function NonPlayable.new(nonPlayable: Model)
	local self = setmetatable({}, NonPlayable)

	self.nonPlayable = nonPlayable
	self.playingAnimation = nil

	return self
end



return NonPlayable
