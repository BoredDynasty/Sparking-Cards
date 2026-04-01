--!strict

-- melt.luau
-- increases damage taken by 50% for 15 seconds; can be refreshed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local damage = require(ReplicatedStorage.Combat.Strike.damage)

local assets = ReplicatedStorage.Assets

return function(target: Player, duration: number)
	if not target then
		warn("no target player inputted for melt reaction")
	end

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

	task.spawn(function()
		local is_applied = false

		while character:GetAttribute("Melted") do
			if is_applied then
				break
			end

			local incoming = damage:GetIncomingForPlayer(target)
			if incoming then
				is_applied = true

				incoming.amount *= 1.5
			end

			RunService.Heartbeat:Wait()
		end
	end)

	-- add a steam effect
	local steam = assets.Beams["Wind-01"]
	steam.Parent = character

	-- offset upwards
	steam.CFrame = humanoid.RootPart.CFrame * CFrame.new(0, 2, 0)

	-- keep setting the CFrame to the player until the effect wears off, in case they move around
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not character:GetAttribute("Melted") and connection then
			connection:Disconnect()

			return
		end

		steam.CFrame = humanoid.RootPart.CFrame * CFrame.new(0, 2, 0)
	end)

	for i, particle_emitter in ipairs(steam:GetDescendants()) do
		if not particle_emitter:IsA("ParticleEmitter") then
			continue
		end

		assert(particle_emitter:IsA("ParticleEmitter"))

		local emit_count = particle_emitter:GetAttribute("EmitCount") :: number
		local emit_delay = particle_emitter:GetAttribute("EmitDelay") :: number

		task.spawn(function()
			particle_emitter:Emit(emit_count)
		end)
		task.delay(emit_delay, function()
			particle_emitter:Emit(emit_count)
		end)
	end

	character:SetAttribute("Melted", true)

	task.delay(duration, function()
		character:SetAttribute("Melted", false)
	end)
end
