--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local _StarterPlayer = game:GetService("StarterPlayer")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local _observer = require(ReplicatedStorage.Utility.observer)
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local input = require(ReplicatedStorage.Packages.input)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- tooltip.luau

local module = {}
