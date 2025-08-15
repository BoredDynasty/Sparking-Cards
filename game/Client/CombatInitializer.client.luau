--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Orion = require(ReplicatedStorage.Shared.Replicated.Combat.OrionFramework.Orion)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local orionInstance = Orion.new(character)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		orionInstance:ExecuteAttack("Frost", "Skill", Vector3.new(), 50, Vector3.new())
			:catch(function(err)
				warn("Error executing attack:", err)
			end)
	end
end)

player.CharacterRemoving:Connect(function()
	orionInstance:Destroy()
end)
