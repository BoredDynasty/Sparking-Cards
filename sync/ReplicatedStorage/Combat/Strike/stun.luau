--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)

-- stun.luau

return function(player: Player, duration: number): boolean
	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	local old_walk_speed = humanoid.WalkSpeed
	local old_jump_power = humanoid.JumpPower
	local stun_id = os.clock()

	character:SetAttribute("StunnedUntil", os.clock() + duration)
	character:SetAttribute("StunId", stun_id)

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	task.delay(duration, function()
		if not humanoid.Parent or character:GetAttribute("StunId") ~= stun_id then
			return
		end

		humanoid.WalkSpeed = old_walk_speed
		humanoid.JumpPower = old_jump_power
		character:SetAttribute("StunnedUntil", nil)
		character:SetAttribute("StunId", nil)
	end)

	Packet.DeductStamina.sendTo({ amount = 100 }, player)

	return true
end
--
