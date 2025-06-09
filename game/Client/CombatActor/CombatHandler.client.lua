--! strict

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local UserInputService = game:GetService("UserInputService")

local Melee = require(StarterPlayer.StarterPlayerScripts.CombatModules.Melee)
local MouseRaycast = require(StarterPlayer.StarterPlayerScripts.Utilities.MouseRaycast)
local characterUtility = require(ReplicatedStorage.Utility.character)

-- // Requires

print("Running combat handler client")

local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder
local remoteEvents = ReplicatedStorage.RemoteEvents

-- // Util

local skillEvent = remoteEvents:WaitForChild("SkillEvents") :: RemoteEvent

local player = Players.LocalPlayer
local character = characterUtility.get(player)
local mouse = player:GetMouse()

-- // TODO) Check what Equipped Card the player has

local function inputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed or gameProcessed == true then
		return
	end
	--print("input began")
	if input.KeyCode == Enum.KeyCode.E then
		local position = MouseRaycast({ character })
		if not position or not position.Position then
			return
		end
		print(position.Position)
		print("sending skill event to server")
		local data = { Position = position.Position }
		skillEvent:FireServer(data)
	end
end

UserInputService.InputBegan:Connect(inputBegan)
mouse.Button1Down:Connect(function()
	Melee(player)
end)
