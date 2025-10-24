--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- shock.luau

--[[
   Applies the shock reaction to a player.
      Shocked players take increased damage from electricity attacks.
      Shocked players cannot be frozen.
]]

return function(player: playerMarshaller.player, signal: SignalPlus.Signal<>)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	local text = [[
   <font color="#ffff66">Shocked</font>
   ]]

	if humanoid then
		signal:Connect(function()
			damage.__call({
				amount = humanoid.Health * 0.95,
				target = player,
			})
		end)

		Packet.IndictEffect.sendTo({ text = text }, player)
	end
end
