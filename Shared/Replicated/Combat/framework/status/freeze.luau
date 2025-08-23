--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- freeze.luau

return function(player: playerMarshaller.player, signal: SignalPlus.Signal<>)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	local text = [[
   <font color="#55aaff">Frozen</font>
   ]]

	if humanoid then
		humanoid.WalkSpeed *= 0.5
		humanoid.JumpPower *= 0.5

		Packet.IndictEffect.sendTo({ text = text }, player)

		signal:Connect(function()
			humanoid:TakeDamage(humanoid.Health * 0.9)
		end)
	end
end
