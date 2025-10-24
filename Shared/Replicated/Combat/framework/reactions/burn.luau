--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- burn.luau

return function(player: playerMarshaller.player, signal: SignalPlus.Signal<>)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	local text = [[
   <font color="#ed5d53">Burning</font>
   ]]

	if humanoid then
		humanoid.WalkSpeed *= 0.5
		humanoid.JumpPower *= 0.5

		Packet.IndictEffect.sendTo({ text = text }, player)

		signal:Connect(function()
			damage.__call({
				amount = humanoid.Health * 0.9,
				target = player,
			})
		end)
	end
end
