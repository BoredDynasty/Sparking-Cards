--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- wet.luau

--[[
   Doesn't really do anything ...
      it does set the player up for freeze, shock and or steam reactions.
]]
return function(player: playerMarshaller.player, signal: SignalPlus.Signal<>)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	local text = [[
   <font color="#3399ff">Wet</font>
   ]]

	if humanoid then
		signal:Fire()

		Packet.IndictEffect.sendTo({ text = text }, player)
	end
end
