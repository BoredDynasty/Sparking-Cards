--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local damage_indicator = require(ReplicatedStorage.Effects["damage-indicator"])
local future = require(ReplicatedStorage.Packages.future)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- damage.luau

-- This module handles the damage calculations and effects for combat strikes in the orion framework.

export type Damage = {
	amount: number, -- The amount of damage dealt
	source: Player?, -- Optional player who dealt the damage
	target: Player, -- player who received the damage
}

local module = setmetatable({}, {
	--[[
	@param amount: number, -- The amount of damage dealt
	@param source: Player?, -- Optional player who dealt the damage
	@param target: Player, -- player who received the damage
]]
	__call = function<a...>(self: { read __call: (Damage) -> a... }, parameters: Damage)
		return self.__call(parameters)
	end,
})
module.__index = module

module.incoming = {} :: { Damage }
module.cancel = SignalPlus() :: SignalPlus.Signal<Player>

--[[
	@param amount: number, -- The amount of damage dealt
	@param source: Player?, -- Optional player who dealt the damage
	@param target: Player, -- player who received the damage
]]
function module.__call(parameters: Damage)
	-- Process damage logic here
	if not parameters.amount then
		warn("no damage amount inputted")

		return false
	end

	if not parameters.source then
		print("no damage source")
	end

	if not parameters.target then
		warn("no damage target")

		return false
	end

	local damage_amount = parameters.amount
	local source_player_id = parameters.source and parameters.source.UserId
	local target_player_id = parameters.target.UserId

	-- get the player instances
	local source_player = future
		.new(function()
			if source_player_id then
				return playerMarshaller.getByUserId(source_player_id)
			else
				return nil
			end
		end)
		:Unwrap()

	local target_player = playerMarshaller.getByUserId(target_player_id)

	if not target_player then
		warn("couldn't get target player from id")

		return false
	end

	local target_character = characterMarshaller.get(target_player)

	-- do a nice lil visual effect for the damage
	local target_root = target_character:FindFirstChild("HumanoidRootPart") :: BasePart
	if target_root then
		damage_indicator(damage_amount, Color3.fromHex("#ffffff"), target_root)
	end

	local target_humanoid = target_character:FindFirstChild("Humanoid") :: Humanoid
	if not target_humanoid then
		print("no humanoid to damage")
	end

	table.insert(module.incoming, {
		amount = damage_amount,
		source = source_player,
		target = target_player,
	})

	local thread = task.spawn(function()
		task.wait(2 / 16) -- around 0.125s

		target_humanoid:TakeDamage(damage_amount)
	end)

	module.cancel:Connect(function(player)
		if player == parameters.target then
			task.cancel(thread)
		end
	end)

	return true -- Indicate success
end

function module:GetIncoming()
	return module.incoming
end

function module:GetIcomingForPlayer(player: Player): Damage?
	for _, data in ipairs(module.incoming) do
		if data.target == player then
			return data
		end
	end

	return nil
end

return module
