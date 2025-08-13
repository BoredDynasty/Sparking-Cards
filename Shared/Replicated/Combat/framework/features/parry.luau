--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local orion = require(ReplicatedStorage.Combat.orion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local stun = require(ReplicatedStorage.Combat.Strike.stun)

-- parry.luau

-- we need a more robust and advanced system for this.

local parry = {
	PARRY_WINDOW = 0.35, -- seconds allowed after client parry start (tweak)
	PARRY_COOLDOWN = 0.6,
	STUN_DURATION = 0.7,
	RIPOSTE_WINDOW = 0.6,
}
