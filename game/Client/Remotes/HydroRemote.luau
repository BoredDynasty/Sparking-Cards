--!strict

-- HydroRemote.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local mousecast = require(StarterPlayer.StarterPlayerScripts.Utilities.mousecast)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- return a tuple that the attack module can use

local player = playerMarshaller.get()

local function getTuple()
	-- get the mouses position in 3D space
	local cast = mousecast({})
	assert(cast and cast.Position, `there is no raycast`)
	return cast.Position
end
