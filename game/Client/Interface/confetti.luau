--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local random = require(ReplicatedStorage.Utility.random)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- confetti.luau

-- Util

local random_seed = random.create()
local _trove = trove.new()

return function(colors: { Color3 }?, container: Instance, add_shadow: boolean?)
	colors = colors
		or {
			Color3.new(1, 0, 0),
			Color3.new(0, 0.101961, 1),
			Color3.new(0, 1, 0.666667),
			Color3.new(1, 0.85098, 0),
		}

	-- TODO) complete the effect
end
