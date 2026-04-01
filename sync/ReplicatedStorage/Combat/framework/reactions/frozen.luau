--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local damage = require(ReplicatedStorage.Combat.Strike.damage)

-- frozen.luau
-- a block of ice is stuck on the player.

local assets = ReplicatedStorage.Assets

return function(target: Player, duration: number)
	if not target then
		warn("no target player inputted for frozen reaction")
	end

	local block = assets.IceCube

	local character = target.Character
	if not character then
		print("no character")
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	if not humanoid then
		print("no humanoid")
		return
	end

	local rootPart = humanoid.RootPart
	if not rootPart then
		print("no root part")
		return
	end

	local blockClone = block:Clone()
	blockClone.Parent = character
	blockClone.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2)
	blockClone.Anchored = true

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.PlatformStand = true

	character:SetAttribute("Flying", false)

	local startTime = os.clock()
	local connection

	connection = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration and connection then
			blockClone:Destroy()

			connection:Disconnect()
		else
			blockClone.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2)
		end
	end)

	-- add shatter damage when hit
	humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		if humanoid.Health < humanoid.MaxHealth then
			-- apply shatter damage here, e.g., 20% of max health
			local shatterDamage = humanoid.MaxHealth * 0.2

			damage:apply({
				target = target,
				amount = shatterDamage,
			})

			blockClone:Destroy()

			if connection then
				connection:Disconnect()
			end
		end
	end)
end
