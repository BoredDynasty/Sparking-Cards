--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local WeaponData = require(ReplicatedStorage.Shared.Replicated.Combat.Melee.WeaponData)
local MainNet = require(ReplicatedStorage.Shared.Replicated.Packet)

--- @class MeleeServer
-- Handles server-side melee combat logic.
-- @server
local MeleeServer = {}
MeleeServer.__index = MeleeServer

export type self = {}

--- Creates a new MeleeServer.
-- @return MeleeServer The new MeleeServer.
function MeleeServer.new(): self
	local self = setmetatable({}, MeleeServer)

	MainNet.MeleeAttack:connect(function(player, data)
		self:handleAttack(player, data.weapon_name)
	end)

	return self
end

--- Handles an attack event from the client.
-- @param player Player The player who initiated the attack.
-- @param weapon_name string The name of the weapon used.
function MeleeServer:handleAttack(player: Player, weapon_name: string)
	local character = player.Character
	if not character then
		return
	end

	local weapon_config = WeaponData[weapon_name]
	if not weapon_config then
		return
	end

	-- Perform hit detection
	local hitbox_cframe = character.PrimaryPart.CFrame * CFrame.new(0, 0, -2.5)
	local hitbox_size = Vector3.new(4, 5, 5)
	local overlap_params = OverlapParams.new()
	overlap_params.FilterDescendantsInstances = {character}
	overlap_params.FilterType = Enum.RaycastFilterType.Blacklist

	local parts_in_box = workspace:GetPartBoundsInBox(hitbox_cframe, hitbox_size, overlap_params)

	local characters_hit = {}
	for _, part in ipairs(parts_in_box) do
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and not table.find(characters_hit, humanoid.Parent) then
			table.insert(characters_hit, humanoid.Parent)
			humanoid:TakeDamage(weapon_config.Damage)
		end
	end
end

return MeleeServer
