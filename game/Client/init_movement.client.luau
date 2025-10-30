--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementController = require(script.Parent.Movement.MovementController)
local Walk = require(script.Parent.Movement.Walk)
local Sprint = require(script.Parent.Movement.Sprint)
local Jump = require(script.Parent.Movement.Jump)
local Dash = require(script.Parent.Movement.Dash)
local Slide = require(script.Parent.Movement.Slide)
local Stamina = require(script.Parent.Movement.Stamina)
local GroundPound = require(script.Parent.Movement.GroundPound)
local Joint = require(script.Parent.Movement.Joint)
local DirectionalSettings = require(script.Parent.Movement.DirectionalSettings)

local movementController = MovementController.new()

movementController:add("Walk", Walk)
movementController:add("Sprint", Sprint)
movementController:add("Jump", Jump)
movementController:add("Dash", Dash)
movementController:add("Slide", Slide)
movementController:add("Stamina", Stamina)
movementController:add("GroundPound", GroundPound)
movementController:add("Joint", Joint)
movementController:add("DirectionalSettings", DirectionalSettings)

movementController:start()

-- Example of how to use the new signals
local jump = movementController:get("Jump")
jump.jumped:Connect(function()
	print("Jumped!")
end)

jump.landed:Connect(function()
	print("Landed!")
end)

local groundPound = movementController:get("GroundPound")
groundPound.onGroundPound:Connect(function()
	print("Ground pound initiated!")
end)
