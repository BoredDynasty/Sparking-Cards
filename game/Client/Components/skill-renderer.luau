--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local skill_tree = require(ReplicatedStorage.Combat.framework["skill-tree"])
local spr = require(ReplicatedStorage.Modules.spr)
local transition = require(StarterPlayer.StarterPlayerScripts.Interface.transition)

-- skill-tree-renderer.luau
-- exempt from displayorder.luau

local module = {}

local player = Players.LocalPlayer

local Events = ReplicatedStorage.Events
local get_profile = Events.GetProfile
