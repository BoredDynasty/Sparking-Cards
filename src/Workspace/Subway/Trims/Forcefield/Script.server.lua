local LetterboxRemote = game.ReplicatedStorage.RemoteEvents.NewDialogue

local message = script.Parent:GetAttribute("DialogueText")
local DissapearTime = script.Parent:GetAttribute("DissapearTime")
local Camera = script.Parent:GetAttribute("CameraBool")

local db = false
local Player = game:GetService("Players")

Player.PlayerAdded:Connect(function(player: Player)
	script.Parent.Touched:Connect(function(hit)
		if db == false then
			db = true
			local character = hit.Parent
			local humanoid = character:FindFirstChild("Humanoid")

			LetterboxRemote:FireClient(player, message, DissapearTime, Camera)
			print("Dialogue Request Processed")
		end
		task.wait(tonumber(DissapearTime - 4))
		db = false
	end)
end)